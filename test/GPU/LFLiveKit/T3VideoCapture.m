//
//  T3VideoCapture.m
//  LFLiveKit
//
//  Created by LaiFeng on 16/5/20.
//  Copyright © 2016年 LaiFeng All rights reserved.
//

#import "T3VideoCapture.h"
#import "T3GPUImageBeautyFilter.h"
#import "T3GPUImageEmptyFilter.h"
//#import "T3GPUImageCuteFilter.h"

#if __has_include(<GPUImage/GPUImage.h>)
#import <GPUImage/GPUImage.h>
#elif __has_include("GPUImage/GPUImage.h")
#import "GPUImage/GPUImage.h"
#else
#import "T3GPUImage.h"
#endif

@interface T3VideoCapture () <T3GPUImageVideoCameraDelegate, T3GPUImageViewDelegate>

@property (nonatomic, strong) T3GPUImageVideoCamera *videoCamera;
@property (nonatomic, strong) T3GPUImageBeautyFilter *beautyFilter;
@property (nonatomic, strong) T3GPUImageOutput<T3GPUImageInput> *filter;
@property (nonatomic, strong) T3GPUImageCropFilter *cropfilter;
@property (nonatomic, strong) T3GPUImageOutput<T3GPUImageInput> *output;
@property (nonatomic, strong) T3GPUImageView *T3GPUImageView;
@property (nonatomic, strong) T3LiveVideoConfiguration *configuration;

@property (nonatomic, strong) T3GPUImageAlphaBlendFilter *blendFilter;
@property (nonatomic, strong) T3GPUImageUIElement *uiElementInput;
@property (nonatomic, strong) UIView *waterMarkContentView;

@property (nonatomic, strong) T3GPUImageMovieWriter *movieWriter;

@end

@implementation T3VideoCapture
@synthesize torch = _torch;
@synthesize beautyLevel = _beautyLevel;
@synthesize brightLevel = _brightLevel;
@synthesize zoomScale = _zoomScale;

#pragma mark -- LifeCycle
- (instancetype)initWithVideoConfiguration:(T3LiveVideoConfiguration *)configuration {
    if (self = [super init]) {
        _configuration = configuration;

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterBackground:) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground:) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarChanged:) name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];

        self.beautyFace = YES;
        self.beautyLevel = 0.5;
        self.brightLevel = 0.5;
        self.zoomScale = 1.0;
        self.mirror = YES;
    }
    return self;
}

- (void)dealloc {
    //[UIApplication sharedApplication].idleTimerDisabled = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.T3GPUImageView.isStoppingCapture = YES;
    [_videoCamera stopCameraCapture];
    if(_T3GPUImageView){
        
        if ([NSThread isMainThread]){
            [_T3GPUImageView removeFromSuperview];
        } else {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [_T3GPUImageView removeFromSuperview];
            });
        }
        _T3GPUImageView = nil;
    }
}

#pragma mark -- Setter Getter

- (T3GPUImageVideoCamera *)videoCamera{
    if(!_videoCamera){
        _videoCamera = [[T3GPUImageVideoCamera alloc] initWithSessionPreset:_configuration.avSessionPreset cameraPosition:_configuration.devPos];
        _videoCamera.delegate = self;
        _videoCamera.outputImageOrientation = _configuration.outputImageOrientation;
        _videoCamera.horizontallyMirrorFrontFacingCamera = NO;
        _videoCamera.horizontallyMirrorRearFacingCamera = NO;
        _videoCamera.frameRate = (int32_t)_configuration.videoFrameRate;
    }
    return _videoCamera;
}

- (void)setRunning:(BOOL)running {
    if (_running == running) return;
    _running = running;
    
    if (!_running) {
        //[UIApplication sharedApplication].idleTimerDisabled = NO;
        self.T3GPUImageView.isStoppingCapture = YES;
        [self.videoCamera stopCameraCapture];
        if(self.saveLocalVideo) [self.movieWriter finishRecording];
    } else {
        //[UIApplication sharedApplication].idleTimerDisabled = YES;
        self.T3GPUImageView.isStoppingCapture = NO;
        [self reloadFilter];
        [self.videoCamera startCameraCapture];
        if(self.saveLocalVideo) [self.movieWriter startRecording];
    }
    //if not do, second, will show first time last frame
    [T3GPUImageContext clearFrameBufferCache];
}

- (void)setPreView:(UIView *)preView {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.T3GPUImageView.superview)
            [self.T3GPUImageView removeFromSuperview];
        [preView insertSubview:self.T3GPUImageView atIndex:0];
        self.T3GPUImageView.frame = CGRectMake(0, 0, preView.frame.size.width, preView.frame.size.height);
    });
}

- (UIView *)preView {
    return self.T3GPUImageView.superview;
}

- (void)setCaptureDevicePosition:(AVCaptureDevicePosition)captureDevicePosition {
    [self.videoCamera rotateCamera];
    self.videoCamera.frameRate = (int32_t)_configuration.videoFrameRate;
    [self reloadMirror];
}

- (AVCaptureDevicePosition)captureDevicePosition {
    return [self.videoCamera cameraPosition];
}

- (void)setVideoFrameRate:(NSInteger)videoFrameRate {
    if (videoFrameRate <= 0) return;
    if (videoFrameRate == self.videoCamera.frameRate) return;
    self.videoCamera.frameRate = (uint32_t)videoFrameRate;
}

- (NSInteger)videoFrameRate {
    return self.videoCamera.frameRate;
}

- (void)setTorch:(BOOL)torch {
    BOOL ret;
    if (!self.videoCamera.captureSession) return;
    AVCaptureSession *session = (AVCaptureSession *)self.videoCamera.captureSession;
    [session beginConfiguration];
    if (self.videoCamera.inputCamera) {
        if (self.videoCamera.inputCamera.torchAvailable) {
            NSError *err = nil;
            if ([self.videoCamera.inputCamera lockForConfiguration:&err]) {
                [self.videoCamera.inputCamera setTorchMode:(torch ? AVCaptureTorchModeOn : AVCaptureTorchModeOff) ];
                [self.videoCamera.inputCamera unlockForConfiguration];
                ret = (self.videoCamera.inputCamera.torchMode == AVCaptureTorchModeOn);
            } else {
                NSLog(@"Error while locking device for torch: %@", err);
                ret = false;
            }
        } else {
            NSLog(@"Torch not available in current camera input");
        }
    }
    [session commitConfiguration];
    _torch = ret;
}

- (BOOL)torch {
    return self.videoCamera.inputCamera.torchMode;
}

- (void)setMirror:(BOOL)mirror {
    _mirror = mirror;
    [self reloadMirror];
}

- (void)setBeautyFace:(BOOL)beautyFace{
    _beautyFace = beautyFace;
    [self reloadFilter];
}

- (void)setBeautyLevel:(CGFloat)beautyLevel {
    _beautyLevel = beautyLevel;
    if (self.beautyFilter) {
        [self.beautyFilter setBeautyLevel:_beautyLevel];
    }
}

- (CGFloat)beautyLevel {
    return _beautyLevel;
}

- (void)setBrightLevel:(CGFloat)brightLevel {
    _brightLevel = brightLevel;
    if (self.beautyFilter) {
        [self.beautyFilter setBrightLevel:brightLevel];
    }
}

- (CGFloat)brightLevel {
    return _brightLevel;
}

- (void)setZoomScale:(CGFloat)zoomScale {
    if (self.videoCamera && self.videoCamera.inputCamera) {
        AVCaptureDevice *device = (AVCaptureDevice *)self.videoCamera.inputCamera;
        if ([device lockForConfiguration:nil]) {
            device.videoZoomFactor = zoomScale;
            [device unlockForConfiguration];
            _zoomScale = zoomScale;
        }
    }
}

- (CGFloat)zoomScale {
    return _zoomScale;
}

- (void)setWarterMarkView:(UIView *)warterMarkView{
    if(_warterMarkView && _warterMarkView.superview){
        [_warterMarkView removeFromSuperview];
        _warterMarkView = nil;
    }
    _warterMarkView = warterMarkView;
    self.blendFilter.mix = warterMarkView.alpha;
    [self.waterMarkContentView addSubview:_warterMarkView];
    [self reloadFilter];
}

- (T3GPUImageUIElement *)uiElementInput{
    if(!_uiElementInput){
        _uiElementInput = [[T3GPUImageUIElement alloc] initWithView:self.waterMarkContentView];
    }
    return _uiElementInput;
}

- (T3GPUImageAlphaBlendFilter *)blendFilter{
    if(!_blendFilter){
        _blendFilter = [[T3GPUImageAlphaBlendFilter alloc] init];
        _blendFilter.mix = 1.0;
        [_blendFilter disableSecondFrameCheck];
    }
    return _blendFilter;
}

- (UIView *)waterMarkContentView{
    if(!_waterMarkContentView){
        _waterMarkContentView = [UIView new];
        _waterMarkContentView.frame = CGRectMake(0, 0, self.configuration.videoSize.width, self.configuration.videoSize.height);
        _waterMarkContentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return _waterMarkContentView;
}

- (T3GPUImageView *)T3GPUImageView{
    if(!_T3GPUImageView){
        _T3GPUImageView = [[T3GPUImageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        [_T3GPUImageView setFillMode:_configuration.imageFillMode];
        [_T3GPUImageView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
        _T3GPUImageView.delegate = self;
    }
    return _T3GPUImageView;
}

-(UIImage *)currentImage{
    if(_filter){
        [_filter useNextFrameForImageCapture];
        return _filter.imageFromCurrentFramebuffer;
    }
    return nil;
}

- (T3GPUImageMovieWriter*)movieWriter{
    if(!_movieWriter){
        _movieWriter = [[T3GPUImageMovieWriter alloc] initWithMovieURL:self.saveLocalVideoPath size:self.configuration.videoSize];
        _movieWriter.encodingLiveVideo = YES;
        _movieWriter.shouldPassthroughAudio = YES;
        self.videoCamera.audioEncodingTarget = self.movieWriter;
    }
    return _movieWriter;
}

#pragma mark -- Custom Method
- (void)processVideo:(T3GPUImageOutput *)output {
    __weak typeof(self) _self = self;
    @autoreleasepool {
        /*
        T3GPUImageFramebuffer *imageFramebuffer = output.framebufferForOutput;
        CVPixelBufferRef pixelBuffer = [imageFramebuffer pixelBuffer];
         */
        CVPixelBufferRef pixelBuffer = [output getOutputPixelBuffer];
        if (pixelBuffer && _self.delegate && [_self.delegate respondsToSelector:@selector(captureOutput:pixelBuffer:)]) {
            [_self.delegate captureOutput:_self pixelBuffer:pixelBuffer];
        }
    }
}

- (void)reloadFilter{
    [self.filter removeAllTargets];
    [self.blendFilter removeAllTargets];
    [self.uiElementInput removeAllTargets];
    [self.videoCamera removeAllTargets];
    [self.output removeAllTargets];
    [self.cropfilter removeAllTargets];
    
#ifdef BUILD_CUTE_FACE
//    if (self.cuteface) {
        self.output = [[T3GPUImageCuteFilter alloc] init];
    /*
    } else {
        self.output = [[T3GPUImageEmptyFilter alloc] init];
    }
     */
#else
    self.output = [[T3GPUImageEmptyFilter alloc] init];
#endif
    
    if (self.beautyFace) {
        self.filter = [[T3GPUImageBeautyFilter alloc] init];
        self.beautyFilter = (T3GPUImageBeautyFilter*)self.filter;
    } else {
        self.filter = [[T3GPUImageEmptyFilter alloc] init];
        self.beautyFilter = nil;
    }
    
    ///< 调节镜像
    [self reloadMirror];
    
    ///< 480*640 比例为4:3  强制转换为16:9
    if([self.configuration.avSessionPreset isEqualToString:AVCaptureSessionPreset640x480]){
        CGRect cropRect = self.configuration.landscape ? CGRectMake(0, 0.125, 1, 0.75) : CGRectMake(0.125, 0, 0.75, 1);
        self.cropfilter = [[T3GPUImageCropFilter alloc] initWithCropRegion:cropRect];
        [self.videoCamera addTarget:self.cropfilter];
        [self.cropfilter addTarget:self.filter];
    }else{
        [self.videoCamera addTarget:self.filter];
    }
    
    ///< 添加水印
    if(self.warterMarkView){
        [self.filter addTarget:self.blendFilter];
        [self.uiElementInput addTarget:self.blendFilter];
        [self.blendFilter addTarget:self.output];
        [self.output addTarget:self.T3GPUImageView];
        [self.uiElementInput update];
    }else{
        [self.filter addTarget:self.output];
        [self.output addTarget:self.T3GPUImageView];
    }
    if(self.saveLocalVideo) [self.output addTarget:self.movieWriter];
    
    [self.filter forceProcessingAtSize:self.configuration.videoSize];
    [self.output forceProcessingAtSize:self.configuration.videoSize];
    [self.blendFilter forceProcessingAtSize:self.configuration.videoSize];
    [self.uiElementInput forceProcessingAtSize:self.configuration.videoSize];
    
    ///< 输出数据
    __weak typeof(self) _self = self;
    [self.output setFrameProcessingCompletionBlock:^(T3GPUImageOutput *output, CMTime time) {
        [_self processVideo:output];
        [_self.uiElementInput update];
    }];
}

- (void)reloadMirror{
    if(self.mirror && self.captureDevicePosition == AVCaptureDevicePositionFront){
        self.videoCamera.horizontallyMirrorFrontFacingCamera = YES;
    }else{
        self.videoCamera.horizontallyMirrorFrontFacingCamera = NO;
    }
}

#pragma mark Notification

- (void)willEnterBackground:(NSNotification *)notification {
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [self.videoCamera pauseCameraCapture];
    T3runSynchronouslyOnVideoProcessingQueue(^{
        glFinish();
    });
}

- (void)willEnterForeground:(NSNotification *)notification {
    [self.videoCamera resumeCameraCapture];
    [UIApplication sharedApplication].idleTimerDisabled = YES;
}

- (void)statusBarChanged:(NSNotification *)notification {
    NSLog(@"UIApplicationWillChangeStatusBarOrientationNotification. UserInfo: %@", notification.userInfo);
    UIInterfaceOrientation statusBar = [[UIApplication sharedApplication] statusBarOrientation];

    if(self.configuration.autorotate){
        if (self.configuration.landscape) {
            if (statusBar == UIInterfaceOrientationLandscapeLeft) {
                self.videoCamera.outputImageOrientation = UIInterfaceOrientationLandscapeRight;
            } else if (statusBar == UIInterfaceOrientationLandscapeRight) {
                self.videoCamera.outputImageOrientation = UIInterfaceOrientationLandscapeLeft;
            }
        } else {
            if (statusBar == UIInterfaceOrientationPortrait) {
                self.videoCamera.outputImageOrientation = UIInterfaceOrientationPortraitUpsideDown;
            } else if (statusBar == UIInterfaceOrientationPortraitUpsideDown) {
                self.videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
            }
        }
    }
}

- (void)firstFrameReady:(T3GPUImageView *)aT3GPUImageView size:(CGSize)size {
//    if (self.delegate && [self.delegate respondsToSelector:@selector(firstLocalVideoFrameRenderedWithSize:)]) {
//        [self.delegate firstLocalVideoFrameRenderedWithSize:size];
//    }
}

- (void)willOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    if ([self.delegate respondsToSelector:@selector(willOutput:pixelBuffer:)]) {
        [_delegate willOutput:self pixelBuffer:CMSampleBufferGetImageBuffer(sampleBuffer)];
    }
}


@end
