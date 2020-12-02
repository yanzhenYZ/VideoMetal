//
//  ViewController.m
//  test
//
//  Created by Work on 2019/8/28.
//  Copyright © 2019 yanzhen. All rights reserved.
//

#define TTT 1

#import "ViewController.h"
#import "WSTCaptureKit.h"
//#import "YZVideoCapture.h"
#import <MetalKit/MetalKit.h>
#import <MetalPerformanceShaders/MetalPerformanceShaders.h>
#import "TTTHelpPlayer.h"

@interface ViewController ()<WSTCaptureKitDelegate, MTKViewDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *player;
@property (nonatomic, strong) WSTCaptureKit *captureKit;
@property (nonatomic, strong) CIContext *context;

@property (nonatomic, strong) MTKView *mtkView;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id<MTLTexture> texture;
@property (nonatomic, assign) CVMetalTextureCacheRef textureCache; //output


@property (nonatomic, strong) TTTHelpPlayer *helper;
@end

/**
 1. GPUImage   11.6%  40.0MB
 2. Metal      19.8%  60.0MB
 3. CIContext  29.4%  40MB
 */



@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    
    //1. 带有方向用OpenGL渲染
    //2. 旋转方向用OpenGL渲染
    //3. 加上基本的美颜，滤镜，-out输出buffer
    
//    [self setupMetal];
//    _helper = [[TTTHelpPlayer alloc] initWithFrame:_player.bounds];
//    [_player addSubview:_helper];
    
    [self test];
    
//    [self test_capture];
    
    //#define KCONNECT 0  使用带有方向的采集， 不需要OpenGL旋转方向
}

- (void)setupMetal {
    self.mtkView = [[MTKView alloc] initWithFrame:self.view.bounds];
    self.mtkView.device = MTLCreateSystemDefaultDevice();
//    [self.anchorVideoView insertSubview:self.mtkView atIndex:0];
    [self.player addSubview:self.mtkView];
    self.mtkView.delegate = self;
    self.mtkView.framebufferOnly = NO; // 允许读写操作
    //    self.mtkView.transform = CGAffineTransformMakeRotation(M_PI / 2);
    self.commandQueue = [self.mtkView.device newCommandQueue];
    CVMetalTextureCacheCreate(NULL, NULL, self.mtkView.device, NULL, &_textureCache);
}

- (void)test {
    _context = [CIContext contextWithOptions:nil];
    
    T3LiveVideoConfiguration *lfvideoConfig = [T3LiveVideoConfiguration new];
    lfvideoConfig.videoSize = CGSizeMake(720, 1280); //640x360  other
    lfvideoConfig.videoFrameRate = 15;
    //lfvideoConfig.videoMaxKeyframeInterval = mFps;
    lfvideoConfig.sessionPreset = LFCaptureSessionPreset720x1280;
    UIInterfaceOrientation outputOrientation = [UIApplication sharedApplication].statusBarOrientation;
    lfvideoConfig.outputImageOrientation = outputOrientation;
    lfvideoConfig.autorotate = NO;
    lfvideoConfig.devPos = AVCaptureDevicePositionFront;
    lfvideoConfig.imageFillMode = kT3GPUImageFillModePreserveAspectRatioAndFill;
    
    
    _captureKit = [[WSTCaptureKit alloc] initWithAudioConfiguration:lfvideoConfig captureType:T3LiveCaptureMaskVideo];
    _captureKit.delegate = self;
    
    _captureKit.preView = self.player;
    
    _captureKit.beautyFace = YES;
    _captureKit.beautyLevel = 0.5;
    _captureKit.brightLevel = 0.5;
    _captureKit.videoFrameRate = 15;
    _captureKit.running = YES;
    
//    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(100, 100, 150, 50)];
//    label.text = @"11111111111111";
//    label.textColor = UIColor.redColor;
//    _captureKit.warterMarkView = label;
}

#pragma mark - WSTCaptureKitDelegate
- (void)outputCaptured:(CVPixelBufferRef)pixelBuffer {
//    NSLog(@"3TLog------%@",pixelBuffer);
//    [self captureVideoBuffer:pixelBuffer];
//    kCVPixelBufferPixelFormatTypeKey
//    PixelFormatType
//    NSLog(@"3TLog------%u : %d",(unsigned int)CVPixelBufferGetPixelFormatType(pixelBuffer), kCVPixelFormatType_32BGRA);
    return;
    
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height =  CVPixelBufferGetHeight(pixelBuffer);
    CVMetalTextureRef tmpTexture = NULL;
    // 如果MTLPixelFormatBGRA8Unorm和摄像头采集时设置的颜色格式不一致，则会出现图像异常的情况；
    CVReturn status = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, self.textureCache, pixelBuffer, NULL, MTLPixelFormatBGRA8Unorm, width, height, 0, &tmpTexture);
    if(status == kCVReturnSuccess)
    {
        self.mtkView.drawableSize = CGSizeMake(width, height);
        self.texture = CVMetalTextureGetTexture(tmpTexture);
        CFRelease(tmpTexture);
    }
}

#pragma mark - MTKViewDelegate
- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
    
}

- (void)drawInMTKView:(MTKView *)view {
    if (self.texture) {
        id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer]; // 创建指令缓冲
        id<MTLTexture> drawingTexture = view.currentDrawable.texture; // 把MKTView作为目标纹理
        
        MPSImageGaussianBlur *filter = [[MPSImageGaussianBlur alloc] initWithDevice:self.mtkView.device sigma:1]; // 这里的sigma值可以修改，sigma值越高图像越模糊
        [filter encodeToCommandBuffer:commandBuffer sourceTexture:self.texture destinationTexture:drawingTexture]; // 把摄像头返回图像数据的原始数据
        
        [commandBuffer presentDrawable:view.currentDrawable]; // 展示数据
        [commandBuffer commit];
        
        self.texture = NULL;
    }
}


- (void)captureVideoBuffer:(CVPixelBufferRef)imageBuffer {
    CVPixelBufferRetain(imageBuffer);
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:imageBuffer];
    if (ciImage == nil) {
        CVPixelBufferRelease(imageBuffer);
        return;
    }
    CGFloat imageWidth = CVPixelBufferGetWidth(imageBuffer);
    CGFloat imageHeight = CVPixelBufferGetHeight(imageBuffer);
    CGImageRef videoImage = [self.context createCGImage:ciImage fromRect:CGRectMake(0, 0, imageWidth, imageHeight)];
    if (videoImage == nil) {
        CVPixelBufferRelease(imageBuffer);
        return;
    }
    UIImage *image = [[UIImage alloc] initWithCGImage:videoImage];
    CGImageRelease(videoImage);
    CVPixelBufferRelease(imageBuffer);
    dispatch_async(dispatch_get_main_queue(), ^{
        self.player.image = image;
    });
}
@end
