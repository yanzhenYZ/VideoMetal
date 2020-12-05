//
//  MetalObj.m
//  test
//
//  Created by 闫振 on 2020/12/1.
//  Copyright © 2020 yanzhen. All rights reserved.
//

#import "MetalObj.h"
#import <MetalKit/MetalKit.h>
#import "YZShaderType.h"
#import "MetalHelper.h"

@interface MetalObj ()<MTKViewDelegate>
@property (nonatomic, assign) UIInterfaceOrientation orientation;
@property (nonatomic, weak) UIView *player;
@property (nonatomic, strong) MTKView *mtkView;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
//高速纹理读取缓存区.
@property (nonatomic, assign) CVMetalTextureCacheRef textureCache;
//渲染管道
@property (nonatomic, strong) id<MTLRenderPipelineState> pipelineState;
//纹理
@property (nonatomic, strong) id<MTLTexture> textureY;
@property (nonatomic, strong) id<MTLTexture> textureUV;

//顶点缓存区
@property (nonatomic, strong) id<MTLBuffer> vertices;
//YUV->RGB转换矩阵
@property (nonatomic, strong) id<MTLBuffer> convertMatrix;
//顶点个数
@property (nonatomic, assign) NSUInteger numVertices;
@end

@implementation MetalObj

- (void)dealloc
{
    if (_textureCache) {
        CVMetalTextureCacheFlush(_textureCache, 0);
        CFRelease(_textureCache);
    }
}

- (void)setupView:(UIView *)view {
    _orientation = UIApplication.sharedApplication.statusBarOrientation;
    _player = view;
    [self _setupMetal];
    [self _setupPipeline];
    [self _setupVertex];
    [self _setupMatrix];
}

- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    if (!pixelBuffer) { return; }
    OSType type = CVPixelBufferGetPixelFormatType(pixelBuffer);
    if (type != kCVPixelFormatType_420YpCbCr8BiPlanarFullRange && type != kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange) {
        NSLog(@"not 420f");
        return;
    }
    
    CVPixelBufferRetain(pixelBuffer);
    //指定buffer类型一次性_setupMatrix
    //[self _setNewConvertMatrix:pixelBuffer];
    
    size_t width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0);
    size_t height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0);
    
    self.mtkView.drawableSize = [MetalHelper getDrawableSize:_orientation size:CGSizeMake(width, height)];
    
    // 像素格式:普通格式，包含一个8位规范化的无符号整数组件。
    MTLPixelFormat pixelFormat = MTLPixelFormatR8Unorm;
    
    // 临时纹理
    CVMetalTextureRef texture = NULL;
    
    /* 根据视频像素缓存区 创建 Metal 纹理缓存区
     
     从现有图像缓冲区创建核心视频Metal纹理缓冲区。
     
     参数1: allocator 内存分配器,默认kCFAllocatorDefault
     参数2: textureCache 纹理缓存区对象
     参数3: sourceImage 视频图像缓冲区
     参数4: textureAttributes 纹理参数字典.默认为NULL
     参数5: pixelFormat 图像缓存区数据的Metal 像素格式常量.注意如果MTLPixelFormatBGRA8Unorm和摄像头采集时设置的颜色格式不一致，则会出现图像异常的情况；
     参数6: width,纹理图像的宽度（像素）
     参数7: height,纹理图像的高度（像素）
     参数8: planeIndex.如果图像缓冲区是平面的，则为映射纹理数据的平面索引。对于非平面图像缓冲区忽略。
     参数9: textureOut,返回时，返回创建的Metal纹理缓冲区。
     */
    CVReturn status = CVMetalTextureCacheCreateTextureFromImage(NULL, self.textureCache, pixelBuffer, NULL, pixelFormat, width, height, 0, &texture);
    if(status == kCVReturnSuccess) {
        _textureY = CVMetalTextureGetTexture(texture);
        CFRelease(texture);
    }
    
    // textureUV 设置(同理,参考于textureY 设置)
    width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 1);
    height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 1);
    pixelFormat = MTLPixelFormatRG8Unorm;
    texture = NULL;
    status = CVMetalTextureCacheCreateTextureFromImage(NULL, self.textureCache, pixelBuffer, NULL, pixelFormat, width, height, 1, &texture);
    if(status == kCVReturnSuccess) {
        _textureUV = CVMetalTextureGetTexture(texture);
        CFRelease(texture);
    }
    CVPixelBufferRelease(pixelBuffer);
    if (_textureY && _textureUV) {
        [self _setNewVertex];
        [self.mtkView draw];
    }
}

#pragma mark - private

- (void)_setupMetal {
    self.mtkView = [[MTKView alloc] initWithFrame:self.player.bounds];
    self.mtkView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.mtkView.backgroundColor = UIColor.redColor;
    //和self.mtkView.drawableSize控制渲染模式
    self.mtkView.contentMode = UIViewContentModeScaleAspectFit;
    [self.player addSubview:self.mtkView];
    
    //手动self.mtkView.draw渲染
    self.mtkView.paused = YES;
    self.mtkView.framebufferOnly = NO;
    self.mtkView.enableSetNeedsDisplay = NO;
    
    self.mtkView.device = MTLCreateSystemDefaultDevice();
    self.mtkView.delegate = self;
    //textureCache的创建(通过CoreVideo提供给CPU/GPU高速缓存通道读取纹理数据)
    CVMetalTextureCacheCreate(NULL, NULL, self.mtkView.device, NULL, &_textureCache);
}

// 设置渲染管道
- (void)_setupPipeline {
    /*
     newDefaultLibrary: 默认一个metal 文件时,推荐使用
     newLibraryWithFile:error: 从Library 指定读取metal 文件
     newLibraryWithData:error: 从Data 中获取metal 文件
     */
    
    NSBundle *bundle = [NSBundle bundleForClass:self.class];
    //todo for framework
    NSString *path = [bundle pathForResource:@"default" ofType:@"metallib"];
    id<MTLLibrary> defaultLibrary = [self.mtkView.device newLibraryWithFile:path error:nil];
    //bundle
    //NSURL *pathUrl = [bundle URLForResource:@"default" withExtension:@"metallib"];
    //id<MTLLibrary> defaultLibrary = [self.mtkView.device newLibraryWithURL:pathUrl error:nil];
    
    //default
    //id<MTLLibrary> defaultLibrary = [self.mtkView.device newDefaultLibrary];
    // 顶点shader
    id<MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:@"vertexShader_yz"];
    // 片元shader
    id<MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"samplingShader_yz"];
    
    //渲染管道描述信息类
    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineStateDescriptor.vertexFunction = vertexFunction;
    pipelineStateDescriptor.fragmentFunction = fragmentFunction;
    // 设置颜色格式
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = self.mtkView.colorPixelFormat;
    
    //初始化渲染管道根据渲染管道描述信息   耗性能操作不宜频繁调用
    self.pipelineState = [self.mtkView.device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor  error:NULL];
    //CommandQueue是渲染指令队列，保证渲染指令有序地提交到GPU
    self.commandQueue = [self.mtkView.device newCommandQueue];
}

// 设置顶点
- (void)_setupVertex {
    return;
    // 顶点坐标(x,y,z,w) 纹理坐标(x,y)
    // 视频全屏播放, 所以顶点大小均设置[-1,1]
    static const YZVertex quadVertices[] =
    {
        { {  1.0, -1.0, 0.0, 1.0 },  { 1.f, 1.f } },
        { { -1.0, -1.0, 0.0, 1.0 },  { 0.f, 1.f } },
        { { -1.0,  1.0, 0.0, 1.0 },  { 0.f, 0.f } },
        
        { {  1.0, -1.0, 0.0, 1.0 },  { 1.f, 1.f } },
        { { -1.0,  1.0, 0.0, 1.0 },  { 0.f, 0.f } },
        { {  1.0,  1.0, 0.0, 1.0 },  { 1.f, 0.f } },
    };
    
    // 创建顶点缓存区
    self.vertices = [self.mtkView.device newBufferWithBytes:quadVertices length:sizeof(quadVertices) options:MTLResourceStorageModeShared];
    self.numVertices = sizeof(quadVertices) / sizeof(YZVertex);
}

/**
 只考虑固定格式 设置YUV->RGB转换的矩阵 see T3GPUImageColorConversion.m
 */
- (void)_setupMatrix {
    // 偏移量
    vector_float3 kColorConversion601FullRangeOffset = (vector_float3){ -(16.0/255.0), -0.5, -0.5};
    YZConvertMatrix matrix;
    matrix.matrix = [MetalHelper getDefaultFloat3x3Matrix];
    matrix.offset = kColorConversion601FullRangeOffset;
    
    // 转换矩阵缓存区.
    self.convertMatrix = [self.mtkView.device newBufferWithBytes:&matrix length:sizeof(YZConvertMatrix) options:MTLResourceStorageModeShared];
}


#pragma mark - MTKViewDelegate

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
    
}

- (void)drawInMTKView:(MTKView *)view {
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    
    //获取渲染描述信息
    MTLRenderPassDescriptor *renderPassDesc = view.currentRenderPassDescriptor;
    if(renderPassDesc)
    {
        // 设置renderPassDescriptor中颜色附着(默认背景色)
        renderPassDesc.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.5, 0.5, 1.0f);
        
        //5.根据渲染描述信息创建渲染命令编码器
        id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDesc];
        
        // 设置视口大小(显示区域)
        [encoder setViewport:(MTLViewport){0.0, 0.0, view.drawableSize.width, view.drawableSize.height, -1.0, 1.0 }];
        
        // 为渲染编码器设置渲染管道
        [encoder setRenderPipelineState:self.pipelineState];
        
        // 设置顶点缓存区
        [encoder setVertexBuffer:self.vertices offset:0 atIndex:YZVertexInputIndexVertices];
        
        // 向片元函数设置textureY 纹理
        [encoder setFragmentTexture:_textureY atIndex:YZFragmentTextureIndexTextureY];
        // 向片元函数设置textureUV 纹理
        [encoder setFragmentTexture:_textureUV atIndex:YZFragmentTextureIndexTextureUV];
        
        // 设置片元函数转化矩阵
        [encoder setFragmentBuffer:self.convertMatrix offset:0 atIndex:YZFragmentInputIndexMatrix];
        
        // 开始绘制
        [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:self.numVertices];
        [encoder endEncoding];
        
        // 显示
        [commandBuffer presentDrawable:view.currentDrawable];
    }
    [commandBuffer commit];
    _textureY = nil;
    _textureUV = nil;
}
#pragma mark - Vertex

- (void)_setNewVertex {
    
    switch (_orientation) {
        case UIInterfaceOrientationPortrait:
            [self _portraitVertex];
            break;
        default:
            [self _defaultVertex];
            break;
    }
}

- (void)_portraitVertex {
    //顶点坐标(x,y,z,w) 纹理坐标(x,y)
    static const YZVertex PortraitVertices[] =
    {
        { {  1.0, -1.0, 0.0, 1.0 },  { 1.f, 0.f } },
        { { -1.0, -1.0, 0.0, 1.0 },  { 1.f, 1.f } },
        { { -1.0,  1.0, 0.0, 1.0 },  { 0.f, 1.f } },

        { {  1.0, -1.0, 0.0, 1.0 },  { 1.f, 0.f } },
        { { -1.0,  1.0, 0.0, 1.0 },  { 0.f, 1.f } },
        { {  1.0,  1.0, 0.0, 1.0 },  { 0.f, 0.f } },
    };
    
    
    
    // 创建顶点缓存区
    self.vertices = [self.mtkView.device newBufferWithBytes:PortraitVertices length:sizeof(PortraitVertices) options:MTLResourceCPUCacheModeDefaultCache];
    self.numVertices = sizeof(PortraitVertices) / sizeof(YZVertex);
}

- (void)_defaultVertex {
    //顶点坐标(x,y,z,w) 纹理坐标(x,y)
    static const YZVertex defaultVertices[] =
    {
        { {  1.0, -1.0, 0.0, 1.0 },  { 1.f, 1.f } },
        { { -1.0, -1.0, 0.0, 1.0 },  { 0.f, 1.f } },
        { { -1.0,  1.0, 0.0, 1.0 },  { 0.f, 0.f } },
        
        { {  1.0, -1.0, 0.0, 1.0 },  { 1.f, 1.f } },
        { { -1.0,  1.0, 0.0, 1.0 },  { 0.f, 0.f } },
        { {  1.0,  1.0, 0.0, 1.0 },  { 1.f, 0.f } },
    };
    
    
    
    // 创建顶点缓存区
    self.vertices = [self.mtkView.device newBufferWithBytes:defaultVertices length:sizeof(defaultVertices) options:MTLResourceCPUCacheModeDefaultCache];
    self.numVertices = sizeof(defaultVertices) / sizeof(YZVertex);
}

#pragma mark - not use
- (void)_setNewConvertMatrix:(CVPixelBufferRef)pixelBuffer {
    vector_float3 kColorConversion601FullRangeOffset = (vector_float3){ -(16.0/255.0), -0.5, -0.5};
    YZConvertMatrix matrix;
    matrix.matrix = [MetalHelper getFloat3x3Matrix:pixelBuffer];
    //matrix.matrix = [MetalHelper getDefaultFloat3x3Matrix];
    matrix.offset = kColorConversion601FullRangeOffset;
    
    // 转换矩阵缓存区
    self.convertMatrix = [self.mtkView.device newBufferWithBytes:&matrix length:sizeof(YZConvertMatrix) options:MTLResourceCPUCacheModeDefaultCache];//MTLResourceStorageModeShared
}
@end
