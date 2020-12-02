//
//  YZVideoCapture.m
//  test
//
//  Created by Work on 2019/8/29.
//  Copyright © 2019 yanzhen. All rights reserved.
//

#import "YZVideoCapture.h"
#import "YZHelper.h"

@interface YZVideoCapture ()<AVCaptureVideoDataOutputSampleBufferDelegate>
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureDeviceInput *videoInput;
@property (nonatomic, strong) AVCaptureDevice *videoDevice;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoOutput;

@property (nonatomic, strong) YZProgram *yuvConversionProgram;
@end

@implementation YZVideoCapture {
    dispatch_queue_t _videoQueue;
    
    GLint _yuvConversionPositionAttribute, _yuvConversionTextureCoordinateAttribute;
    GLint _yuvConversionLuminanceTextureUniform, _yuvConversionChrominanceTextureUniform;
    GLint _yuvConversionMatrixUniform;
    const GLfloat *_preferredConversion;
    int _imageBufferWidth, _imageBufferHeight;
    GLuint _luminanceTexture, _chrominanceTexture;
    
    YZGPUImageRotationMode _outputRotation, _internalRotation;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _videoQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH,0);
        
        NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        for (AVCaptureDevice *device in devices) {
            if (device.position == AVCaptureDevicePositionFront) {
                _videoDevice = device;
            }
        }
        
        _captureSession = [[AVCaptureSession alloc] init];

        [_captureSession beginConfiguration];
        
        _videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:_videoDevice error:nil];
        if ([_captureSession canAddInput:_videoInput]) {
            [_captureSession addInput:_videoInput];
        }
        
        _videoOutput = [[AVCaptureVideoDataOutput alloc] init];
        [_videoOutput setAlwaysDiscardsLateVideoFrames:NO];
        
        if ([YZContextTool supportsFastTextureUpload]) {
            [_videoOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
        } else {
            NSAssert(0, @"not support texture");
        }
        YZrunSynchronouslyOnVideoProcessingQueue(^{
            [YZContextTool useImageProcessingContext];
            self.yuvConversionProgram = [[YZContextTool shared] programForVertexShaderString:kYZGPUImageVertexShaderString fragmentShaderString:kYZGPUImageYUVFullRangeConversionForLAFragmentShaderString];

            if (!self.yuvConversionProgram.initialized)
            {
                [self.yuvConversionProgram addAttribute:@"position"];
                [self.yuvConversionProgram addAttribute:@"inputTextureCoordinate"];
    //
                if (![self.yuvConversionProgram link])
                {
//                    NSString *progLog = [_yuvConversionProgram programLog];
//                    NSLog(@"Program link log: %@", progLog);
//                    NSString *fragLog = [_yuvConversionProgram fragmentShaderLog];
//                    NSLog(@"Fragment shader compile log: %@", fragLog);
//                    NSString *vertLog = [_yuvConversionProgram vertexShaderLog];
//                    NSLog(@"Vertex shader compile log: %@", vertLog);
//                    _yuvConversionProgram = nil;
                    NSAssert(NO, @"Filter shader link failed");
                }
            }
        
            self->_yuvConversionPositionAttribute = [self.yuvConversionProgram attributeIndex:@"position"];
            self->_yuvConversionTextureCoordinateAttribute = [self.yuvConversionProgram attributeIndex:@"inputTextureCoordinate"];
            self->_yuvConversionLuminanceTextureUniform = [self.yuvConversionProgram uniformIndex:@"luminanceTexture"];
            self->_yuvConversionChrominanceTextureUniform = [self.yuvConversionProgram uniformIndex:@"chrominanceTexture"];
            self->_yuvConversionMatrixUniform = [self.yuvConversionProgram uniformIndex:@"colorConversionMatrix"];

            [YZContextTool setActiveShaderProgram:self.yuvConversionProgram];

            glEnableVertexAttribArray(self->_yuvConversionPositionAttribute);
            glEnableVertexAttribArray(self->_yuvConversionTextureCoordinateAttribute);
    });
        
        [_videoOutput setSampleBufferDelegate:self queue:_videoQueue];
        if ([_captureSession canAddOutput:_videoOutput]) {
            [_captureSession addOutput:_videoOutput];
        }
        
        _captureSession.sessionPreset = AVCaptureSessionPreset640x480;
        [_captureSession commitConfiguration];
    }
    return self;
}

- (void)startCapture {
    [_captureSession startRunning];
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    CFRetain(sampleBuffer);
    YZrunAsynchronouslyOnVideoProcessingQueue(^{
        [self processVideoSampleBuffer:sampleBuffer];
        CFRelease(sampleBuffer);
    });
}

- (void)processVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer;
{
    CVPixelBufferRef pixerBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    CVImageBufferRef cameraFrame = CMSampleBufferGetImageBuffer(sampleBuffer);
    int bufferWidth = (int) CVPixelBufferGetWidth(cameraFrame);
    int bufferHeight = (int) CVPixelBufferGetHeight(cameraFrame);
    CFTypeRef colorAttachments = CVBufferGetAttachment(cameraFrame, kCVImageBufferYCbCrMatrixKey, NULL);
    
    if (colorAttachments != NULL) {
        if(CFStringCompare(colorAttachments, kCVImageBufferYCbCrMatrix_ITU_R_601_4, 0) == kCFCompareEqualTo)
        {
            _preferredConversion = kYZColorConversion601FullRange;
        } else {
            _preferredConversion = kYZColorConversion709;
        }
    } else {
        _preferredConversion = kYZColorConversion601FullRange;
    }
    
    CMTime currentTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    [YZContextTool useImageProcessingContext];
    //if
    CVOpenGLESTextureRef luminanceTextureRef = NULL;
    CVOpenGLESTextureRef chrominanceTextureRef = NULL;
    
    if (CVPixelBufferGetPlaneCount(cameraFrame) > 0) // Check for YUV planar inputs to do RGB conversion
    {
        CVPixelBufferLockBaseAddress(cameraFrame, 0);
        
        if ((_imageBufferWidth != bufferWidth) && (_imageBufferHeight != bufferHeight)) {
            _imageBufferWidth = bufferWidth;
            _imageBufferHeight = bufferHeight;
        }
        
        CVReturn err;
        // Y-plane y数据因为只包含一个通道，所以设成了GL_LUMINANCE（灰度图）
        glActiveTexture(GL_TEXTURE4);
        if ([YZContextTool deviceSupportsRedTextures])
        {
            err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, [[YZContextTool shared] coreVideoTextureCache], cameraFrame, NULL, GL_TEXTURE_2D, GL_LUMINANCE, bufferWidth, bufferHeight, GL_LUMINANCE, GL_UNSIGNED_BYTE, 0, &luminanceTextureRef);
        }
        else
        {
            err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, [[YZContextTool shared] coreVideoTextureCache], cameraFrame, NULL, GL_TEXTURE_2D, GL_LUMINANCE, bufferWidth, bufferHeight, GL_LUMINANCE, GL_UNSIGNED_BYTE, 0, &luminanceTextureRef);
        }
        if (err)
        {
            NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
        }
        
        _luminanceTexture = CVOpenGLESTextureGetName(luminanceTextureRef);
        glBindTexture(GL_TEXTURE_2D, _luminanceTexture);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        // UV-plane uv数据则包含2个通道，所以设成了GL_LUMINANCE_ALPHA（带alpha的灰度图）
        glActiveTexture(GL_TEXTURE5);
        if ([YZContextTool deviceSupportsRedTextures])
        {
            err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, [[YZContextTool shared] coreVideoTextureCache], cameraFrame, NULL, GL_TEXTURE_2D, GL_LUMINANCE_ALPHA, bufferWidth/2, bufferHeight/2, GL_LUMINANCE_ALPHA, GL_UNSIGNED_BYTE, 1, &chrominanceTextureRef);
        }
        else
        {
            err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, [[YZContextTool shared] coreVideoTextureCache], cameraFrame, NULL, GL_TEXTURE_2D, GL_LUMINANCE_ALPHA, bufferWidth/2, bufferHeight/2, GL_LUMINANCE_ALPHA, GL_UNSIGNED_BYTE, 1, &chrominanceTextureRef);
        }
        if (err)
        {
            NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
        }
        
        _chrominanceTexture = CVOpenGLESTextureGetName(chrominanceTextureRef);
        glBindTexture(GL_TEXTURE_2D, _chrominanceTexture);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        [self convertYUVToRGBOutput];

        int rotatedImageBufferWidth = bufferWidth, rotatedImageBufferHeight = bufferHeight;

        if (YZGPUImageRotationSwapsWidthAndHeight(_internalRotation)) {
            rotatedImageBufferWidth = bufferHeight;
            rotatedImageBufferHeight = bufferWidth;
        }

        [self updateTargetsForVideoCameraUsingCacheTextureAtWidth:rotatedImageBufferWidth height:rotatedImageBufferHeight time:currentTime];
        CVPixelBufferUnlockBaseAddress(cameraFrame, 0);
        CFRelease(luminanceTextureRef);
        CFRelease(chrominanceTextureRef);
    }
    
    //_runBenchmark
    
    if ([_delegate respondsToSelector:@selector(capture:buffer:)]) {
        [_delegate capture:self buffer:pixerBuffer];
    }

}

- (void)convertYUVToRGBOutput {
    [YZContextTool setActiveShaderProgram:_yuvConversionProgram];
    
    int rotatedImageBufferWidth = _imageBufferWidth, rotatedImageBufferHeight = _imageBufferHeight;
    
    if (YZGPUImageRotationSwapsWidthAndHeight(_internalRotation))
    {
        rotatedImageBufferWidth = _imageBufferHeight;
        rotatedImageBufferHeight = _imageBufferWidth;
    }

#pragma mark - todo
    CGSize size = CGSizeMake(rotatedImageBufferWidth, rotatedImageBufferHeight);
    _frameBuffer = [[YZContextTool sharedFramebufferCache] fetchFramebufferForSize:size textureOptions:self.outputTextureOptions onlyTexture:NO];
    [_frameBuffer activateFramebuffer];
    
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    static const GLfloat squareVertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };
    
    glActiveTexture(GL_TEXTURE4);
    glBindTexture(GL_TEXTURE_2D, _luminanceTexture);
    glUniform1i(_yuvConversionLuminanceTextureUniform, 4);
    
    glActiveTexture(GL_TEXTURE5);
    glBindTexture(GL_TEXTURE_2D, _chrominanceTexture);
    glUniform1i(_yuvConversionChrominanceTextureUniform, 5);
    
    glUniformMatrix3fv(_yuvConversionMatrixUniform, 1, GL_FALSE, _preferredConversion);
    
    glVertexAttribPointer(_yuvConversionPositionAttribute, 2, GL_FLOAT, 0, 0, squareVertices);
    glVertexAttribPointer(_yuvConversionTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, [YZHelper textureCoordinatesForRotation:_internalRotation]);
    
#warning mark - 卡死
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    /*
    1). 向frameBufferCache申请一个outputFrameBuffer
    2). 将申请得到的outputFrameBuffer激活并设为渲染对象
    3). glClear清除画布
    4). 设置输入纹理
    5). 传入顶点
    6). 传入纹理坐标
    7). 调用绘制方法
     */
}

#pragma mark - todo
- (void)updateTargetsForVideoCameraUsingCacheTextureAtWidth:(int)bufferWidth height:(int)bufferHeight time:(CMTime)currentTime {
    
    /*
    // First, update all the framebuffers in the targets
    for (id<T3GPUImageInput> currentTarget in targets)
    {
        if ([currentTarget enabled])
        {
            NSInteger indexOfObject = [targets indexOfObject:currentTarget];
            NSInteger textureIndexOfTarget = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];
            
            if (currentTarget != self.targetToIgnoreForUpdates)
            {
                [currentTarget setInputRotation:outputRotation atIndex:textureIndexOfTarget];
                [currentTarget setInputSize:CGSizeMake(bufferWidth, bufferHeight) atIndex:textureIndexOfTarget];
                
                if ([currentTarget wantsMonochromeInput] && captureAsYUV)
                {
                    [currentTarget setCurrentlyReceivingMonochromeInput:YES];
                    // TODO: Replace optimization for monochrome output
                    [currentTarget setInputFramebuffer:outputFramebuffer atIndex:textureIndexOfTarget];
                }
                else
                {
                    [currentTarget setCurrentlyReceivingMonochromeInput:NO];
                    [currentTarget setInputFramebuffer:outputFramebuffer atIndex:textureIndexOfTarget];
                }
            }
            else
            {
                [currentTarget setInputRotation:outputRotation atIndex:textureIndexOfTarget];
                [currentTarget setInputFramebuffer:outputFramebuffer atIndex:textureIndexOfTarget];
            }
        }
    }
    
    // Then release our hold on the local framebuffer to send it back to the cache as soon as it's no longer needed
    [outputFramebuffer unlock];
    outputFramebuffer = nil;
    
    // Finally, trigger rendering as needed
    for (id<T3GPUImageInput> currentTarget in targets)
    {
        if ([currentTarget enabled])
        {
            NSInteger indexOfObject = [targets indexOfObject:currentTarget];
            NSInteger textureIndexOfTarget = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];
            
            if (currentTarget != self.targetToIgnoreForUpdates)
            {
                [currentTarget newFrameReadyAtTime:currentTime atIndex:textureIndexOfTarget];
            }
        }
    }
     */
}

#pragma mark - help


- (void)setOutputImageOrientation:(UIInterfaceOrientation)outputImageOrientation {
    _outputImageOrientation = outputImageOrientation;
    [self updateOrientationSendToTargets];
}

- (void)updateOrientationSendToTargets;
{
    YZrunSynchronouslyOnVideoProcessingQueue(^{
        if ([YZContextTool supportsFastTextureUpload])
        {
            self->_outputRotation = kYZGPUImageNoRotation;
            if (0)
            {
                if (self->_horizontallyMirrorRearFacingCamera)
                {
                    switch(self->_outputImageOrientation)
                    {
                        case UIInterfaceOrientationPortrait:self->_internalRotation = kYZGPUImageRotateRightFlipVertical; break;
                        case UIInterfaceOrientationPortraitUpsideDown:self->_internalRotation = kYZGPUImageRotate180; break;
                        case UIInterfaceOrientationLandscapeLeft:self->_internalRotation = kYZGPUImageFlipHorizonal; break;
                        case UIInterfaceOrientationLandscapeRight:self->_internalRotation = kYZGPUImageFlipVertical; break;
                        default:self->_internalRotation = kYZGPUImageNoRotation;
                    }
                }
                else
                {
                    switch(self->_outputImageOrientation)
                    {
                        case UIInterfaceOrientationPortrait:self->_internalRotation = kYZGPUImageRotateRight; break;
                        case UIInterfaceOrientationPortraitUpsideDown:self->_internalRotation = kYZGPUImageRotateLeft; break;
                        case UIInterfaceOrientationLandscapeLeft:self->_internalRotation = kYZGPUImageRotate180; break;
                        case UIInterfaceOrientationLandscapeRight:self->_internalRotation = kYZGPUImageNoRotation; break;
                        default:self->_internalRotation = kYZGPUImageNoRotation;
                    }
                }
            }
            else
            {
                if (self->_horizontallyMirrorFrontFacingCamera)
                {
                    switch(self->_outputImageOrientation)
                    {
                        case UIInterfaceOrientationPortrait:self->_internalRotation = kYZGPUImageRotateRightFlipVertical; break;
                        case UIInterfaceOrientationPortraitUpsideDown:self->_internalRotation = kYZGPUImageRotateRightFlipHorizontal; break;
                        case UIInterfaceOrientationLandscapeLeft:self->_internalRotation = kYZGPUImageFlipHorizonal; break;
                        case UIInterfaceOrientationLandscapeRight:self->_internalRotation = kYZGPUImageFlipVertical; break;
                        default:self->_internalRotation = kYZGPUImageNoRotation;
                    }
                }
                else
                {
                    switch(self->_outputImageOrientation)
                    {
                        case UIInterfaceOrientationPortrait:self->_internalRotation = kYZGPUImageRotateRight; break;
                        case UIInterfaceOrientationPortraitUpsideDown:self->_internalRotation = kYZGPUImageRotateLeft; break;
                        case UIInterfaceOrientationLandscapeLeft:self->_internalRotation = kYZGPUImageNoRotation; break;
                        case UIInterfaceOrientationLandscapeRight:self->_internalRotation = kYZGPUImageRotate180; break;
                        default:self->_internalRotation = kYZGPUImageNoRotation;
                    }
                }
            }
        }
        else
        {
            if (0)
            {
                if (self->_horizontallyMirrorRearFacingCamera)
                {
                    switch(self->_outputImageOrientation)
                    {
                        case UIInterfaceOrientationPortrait:self->_outputRotation = kYZGPUImageRotateRightFlipVertical; break;
                        case UIInterfaceOrientationPortraitUpsideDown:self->_outputRotation = kYZGPUImageRotate180; break;
                        case UIInterfaceOrientationLandscapeLeft:self->_outputRotation = kYZGPUImageFlipHorizonal; break;
                        case UIInterfaceOrientationLandscapeRight:self->_outputRotation = kYZGPUImageFlipVertical; break;
                        default:self->_outputRotation = kYZGPUImageNoRotation;
                    }
                }
                else
                {
                    switch(self->_outputImageOrientation)
                    {
                        case UIInterfaceOrientationPortrait:self->_outputRotation = kYZGPUImageRotateRight; break;
                        case UIInterfaceOrientationPortraitUpsideDown:self->_outputRotation = kYZGPUImageRotateLeft; break;
                        case UIInterfaceOrientationLandscapeLeft:self->_outputRotation = kYZGPUImageRotate180; break;
                        case UIInterfaceOrientationLandscapeRight:self->_outputRotation = kYZGPUImageNoRotation; break;
                        default:self->_outputRotation = kYZGPUImageNoRotation;
                    }
                }
            }
            else
            {
                if (self->_horizontallyMirrorFrontFacingCamera)
                {
                    switch(self->_outputImageOrientation)
                    {
                        case UIInterfaceOrientationPortrait:self->_outputRotation = kYZGPUImageRotateRightFlipVertical; break;
                        case UIInterfaceOrientationPortraitUpsideDown:self->_outputRotation = kYZGPUImageRotateRightFlipHorizontal; break;
                        case UIInterfaceOrientationLandscapeLeft:self->_outputRotation = kYZGPUImageFlipHorizonal; break;
                        case UIInterfaceOrientationLandscapeRight:self->_outputRotation = kYZGPUImageFlipVertical; break;
                        default:self->_outputRotation = kYZGPUImageNoRotation;
                    }
                }
                else
                {
                    switch(self->_outputImageOrientation)
                    {
                        case UIInterfaceOrientationPortrait:self->_outputRotation = kYZGPUImageRotateRight; break;
                        case UIInterfaceOrientationPortraitUpsideDown:self->_outputRotation = kYZGPUImageRotateLeft; break;
                        case UIInterfaceOrientationLandscapeLeft:self->_outputRotation = kYZGPUImageNoRotation; break;
                        case UIInterfaceOrientationLandscapeRight:self->_outputRotation = kYZGPUImageRotate180; break;
                        default:self->_outputRotation = kYZGPUImageNoRotation;
                    }
                }
            }
        }
        
//        for (id<T3GPUImageInput> currentTarget in targets)
//        {
//            NSInteger indexOfObject = [targets indexOfObject:currentTarget];
//            [currentTarget setInputRotation:outputRotation atIndex:[[targetTextureIndices objectAtIndex:indexOfObject] integerValue]];
//        }
    });
}
@end
