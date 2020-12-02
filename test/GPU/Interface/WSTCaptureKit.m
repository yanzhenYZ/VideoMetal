//
//  WSTCaptureKit.m
//
//  Created by doubon on 16/10/28.
//  Copyright © 2016年 wushuangtech All rights reserved.
//

#import "WSTCaptureKit.h"
#import "T3VideoCapture.h"
#import "T3GPUImageBeautyFilter.h"

@interface WSTCaptureKit () <T3VideoCaptureDelegate>
/// 视频配置
@property (nonatomic, strong) T3LiveVideoConfiguration *videoConfiguration;
/// 视频采集
@property (nonatomic, strong) T3VideoCapture *videoCaptureSource;
/// 当前直播type
@property (nonatomic, assign, readwrite) T3LiveCaptureTypeMask captureType;

@end

@interface WSTCaptureKit ()

/// 音视频是否对齐
@property (nonatomic, assign) BOOL AVAlignment;
/// 当前是否采集到了音频
@property (nonatomic, assign) BOOL hasCaptureAudio;
/// 当前是否采集到了关键帧
@property (nonatomic, assign) BOOL hasKeyFrameVideo;

@end

@implementation WSTCaptureKit

#pragma mark -- LifeCycle


- (nullable instancetype)initWithAudioConfiguration:(nullable T3LiveVideoConfiguration *)videoConfiguration captureType:(T3LiveCaptureTypeMask)captureType{
    if (self = [super init]) {
        _videoConfiguration = videoConfiguration;
        _adaptiveBitrate = NO;
        _captureType = captureType;
    }
    return self;
}

- (void)dealloc {
    _videoCaptureSource.running = NO;
}

#pragma mark -- CaptureDelegate
- (void)captureOutput:(nullable T3VideoCapture *)capture pixelBuffer:(nullable CVPixelBufferRef)pixelBuffer {
    if (self.delegate && [self.delegate respondsToSelector:@selector(outputCaptured:)]) {
        [self.delegate outputCaptured:pixelBuffer];
    }
}


- (void)willOutput:(T3VideoCapture *)capture pixelBuffer:(CVPixelBufferRef)pixelBuffer {
    if ([self.delegate respondsToSelector:@selector(willOutputCaptured:)]) {
        [self.delegate willOutputCaptured:pixelBuffer];
    }
}

#pragma mark -- Getter Setter
- (void)setVideoFrameRate:(NSInteger)videoFrameRate {
    if (videoFrameRate == _videoFrameRate) { return; }
    _videoFrameRate = videoFrameRate;
    self.videoCaptureSource.videoFrameRate = videoFrameRate;
}

- (void)setRunning:(BOOL)running {
    if (_running == running)
        return;
    _running = running;
    self.videoCaptureSource.running = _running;
}

- (void)setPreView:(UIView *)preView {
    [self.videoCaptureSource setPreView:preView];
}

- (UIView *)preView {
    return self.videoCaptureSource.preView;
}

- (void)setCaptureDevicePosition:(AVCaptureDevicePosition)captureDevicePosition {
    [self.videoCaptureSource setCaptureDevicePosition:captureDevicePosition];
}

- (AVCaptureDevicePosition)captureDevicePosition {
    return self.videoCaptureSource.captureDevicePosition;
}

- (void)setBeautyFace:(BOOL)beautyFace {
    [self.videoCaptureSource setBeautyFace:beautyFace];
}

- (BOOL)saveLocalVideo{
    return self.videoCaptureSource.saveLocalVideo;
}

- (void)setSaveLocalVideo:(BOOL)saveLocalVideo{
    [self.videoCaptureSource setSaveLocalVideo:saveLocalVideo];
}


- (NSURL*)saveLocalVideoPath{
    return self.videoCaptureSource.saveLocalVideoPath;
}

- (void)setSaveLocalVideoPath:(NSURL*)saveLocalVideoPath{
    [self.videoCaptureSource setSaveLocalVideoPath:saveLocalVideoPath];
}

- (BOOL)beautyFace {
    return self.videoCaptureSource.beautyFace;
}

- (void)setBeautyLevel:(CGFloat)beautyLevel {
    [self.videoCaptureSource setBeautyLevel:beautyLevel];
}

- (CGFloat)beautyLevel {
    return self.videoCaptureSource.beautyLevel;
}

- (void)setBrightLevel:(CGFloat)brightLevel {
    [self.videoCaptureSource setBrightLevel:brightLevel];
}

- (CGFloat)brightLevel {
    return self.videoCaptureSource.brightLevel;
}

- (void)setZoomScale:(CGFloat)zoomScale {
    [self.videoCaptureSource setZoomScale:zoomScale];
}

- (CGFloat)zoomScale {
    return self.videoCaptureSource.zoomScale;
}

- (void)setTorch:(BOOL)torch {
    [self.videoCaptureSource setTorch:torch];
}

- (BOOL)torch {
    return self.videoCaptureSource.torch;
}

- (void)setMirror:(BOOL)mirror {
    [self.videoCaptureSource setMirror:mirror];
}

- (BOOL)mirror {
    return self.videoCaptureSource.mirror;
}

- (void)setWarterMarkView:(UIView *)warterMarkView{
    [self.videoCaptureSource setWarterMarkView:warterMarkView];
}

- (nullable UIView*)warterMarkView{
    return self.videoCaptureSource.warterMarkView;
}

- (nullable UIImage *)currentImage{
    return self.videoCaptureSource.currentImage;
}

- (T3VideoCapture *)videoCaptureSource {
    if (!_videoCaptureSource) {
        if(self.captureType & T3LiveCaptureMaskVideo){
            _videoCaptureSource = [[T3VideoCapture alloc] initWithVideoConfiguration:_videoConfiguration];
            _videoCaptureSource.delegate = self;
        }
    }
    return _videoCaptureSource;
}

- (BOOL)AVAlignment{
    if((self.captureType & T3LiveCaptureMaskAudio || self.captureType & T3LiveInputMaskAudio) &&
       (self.captureType & T3LiveCaptureMaskVideo || self.captureType & T3LiveInputMaskVideo)
       ){
        if(self.hasCaptureAudio && self.hasKeyFrameVideo) return YES;
        else  return NO;
    }else{
        return YES;
    }
}

@end
