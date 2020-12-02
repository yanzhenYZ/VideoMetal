//
//  WSTCaptureKit.h
//
//
//  Created by doubon on 16/10/28.
//  Copyright © 2016年 wushuangtech All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "T3LiveVideoConfiguration.h"

/**
 1. 替换新的BeautyFace工程
 2. 修改VideoWorker里面新的对象名称
 3. MyVideoApi.m 修改监听GPUImage通知
 4. 修改myvideo工程搜索路径
 5. 修改编译脚本
 */

typedef NS_ENUM(NSInteger, T3LiveCaptureType) {
    T3LiveCaptureAudio,         // capture only audio
    T3LiveCaptureVideo,         // capture only video
    T3LiveInputAudio,           // only audio (External input audio)
    T3LiveInputVideo,           // only video (External input video)
};


///< 用来控制采集类型（可以内部采集也可以外部传入等各种组合，支持单音频与单视频,外部输入适用于录屏，无人机等外设介入）
typedef NS_ENUM(NSInteger,T3LiveCaptureTypeMask) {
    T3LiveCaptureMaskAudio = (1 << T3LiveCaptureAudio),                                 ///< only inner capture audio (no video)
    T3LiveCaptureMaskVideo = (1 << T3LiveCaptureVideo),                                 ///< only inner capture video (no audio)
    T3LiveInputMaskAudio = (1 << T3LiveInputAudio),                                     ///< only outer input audio (no video)
    T3LiveInputMaskVideo = (1 << T3LiveInputVideo),                                     ///< only outer input video (no audio)
    T3LiveCaptureMaskAll = (T3LiveCaptureMaskAudio | T3LiveCaptureMaskVideo),           ///< inner capture audio and video
    T3LiveInputMaskAll = (T3LiveInputMaskAudio | T3LiveInputMaskVideo),                 ///< outer input audio and video(method see pushVideo and pushAudio)
    T3LiveCaptureMaskAudioInputVideo = (T3LiveCaptureMaskAudio | T3LiveInputMaskVideo), ///< inner capture audio and outer input video(method pushVideo and setRunning)
    T3LiveCaptureMaskVideoInputAudio = (T3LiveCaptureMaskVideo | T3LiveInputMaskAudio), ///< inner capture video and outer input audio(method pushAudio and setRunning)
    T3LiveCaptureDefaultMask = T3LiveCaptureMaskAll                                     ///< default is inner capture audio and video
};

@class WSTCaptureKit;

@protocol WSTCaptureKitDelegate <NSObject>

- (void)outputCaptured:(nullable CVPixelBufferRef)pixelBuffer;


- (void)willOutputCaptured:(nullable CVPixelBufferRef)pixelBuffer;
@end

@interface WSTCaptureKit : NSObject

#pragma mark - Attribute
///=============================================================================
/// @name Attribute
///=============================================================================
/** The delegate of the capture. captureData callback */
@property (nullable, nonatomic, weak) id<WSTCaptureKitDelegate> delegate;

/** The running control start capture or stop capture*/
@property (nonatomic, assign) BOOL running;

/** The preView will show OpenGL ES view*/
@property (nonatomic, strong, null_resettable) UIView *preView;

/** The captureDevicePosition control camraPosition ,default front*/
@property (nonatomic, assign) AVCaptureDevicePosition captureDevicePosition;

/** The beautyFace control capture shader filter empty or beautiy */
@property (nonatomic, assign) BOOL beautyFace;

/** The beautyLevel control beautyFace Level. Default is 0.5, between 0.0 ~ 1.0 */
@property (nonatomic, assign) CGFloat beautyLevel;

/** The brightLevel control brightness Level, Default is 0.5, between 0.0 ~ 1.0 */
@property (nonatomic, assign) CGFloat brightLevel;

/** The torch control camera zoom scale default 1.0, between 1.0 ~ 3.0 */
@property (nonatomic, assign) CGFloat zoomScale;

/** The torch control capture flash is on or off */
@property (nonatomic, assign) BOOL torch;

/** The mirror control mirror of front camera is on or off */
@property (nonatomic, assign) BOOL mirror;

/** The muted control callbackAudioData,muted will memset 0.*/
@property (nonatomic, assign) BOOL muted;

/*  The adaptiveBitrate control auto adjust bitrate. Default is NO */
@property (nonatomic, assign) BOOL adaptiveBitrate;

/** The captureType control inner or outer audio and video .*/
@property (nonatomic, assign, readonly) T3LiveCaptureTypeMask captureType;

/*** The warterMarkView control whether the watermark is displayed or not ,if set ni,will remove watermark,otherwise add.
 set alpha represent mix.Position relative to outVideoSize.
 *.*/
@property (nonatomic, strong, nullable) UIView *warterMarkView;

/* The currentImage is videoCapture shot */
@property (nonatomic, strong,readonly ,nullable) UIImage *currentImage;

/* The saveLocalVideo is save the local video */
@property (nonatomic, assign) BOOL saveLocalVideo;

/* The saveLocalVideoPath is save the local video  path */
@property (nonatomic, strong, nullable) NSURL *saveLocalVideoPath;

/** The videoFrameRate control videoCapture output data count 3T*/
@property (nonatomic, assign) NSInteger videoFrameRate;

#pragma mark - Initializer
///=============================================================================
/// @name Initializer
///=============================================================================
- (nullable instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (nullable instancetype)new UNAVAILABLE_ATTRIBUTE;

/**
 The designated initializer. Multiple instances with the same configuration will make the
 capture unstable.
 */
- (nullable instancetype)initWithAudioConfiguration:(nullable T3LiveVideoConfiguration *)videoConfiguration captureType:(T3LiveCaptureTypeMask)captureType NS_DESIGNATED_INITIALIZER;
#if TARGET_OS_IOS
//闪光灯
- (BOOL)isCameraTorchSupported;
- (int)setCameraTorchOn:(BOOL)isOn;

//1~3 摄像头缩放比例
- (CGFloat)cameraMaxZoomFactor;
- (int)setCameraZoomFactor:(CGFloat)zoom;

//手动对焦位置，并触发对焦 [0~1][0~1]
- (BOOL)isCameraFocusPointOfInterestSupported;
- (int)setCameraFocusPointOfInterest:(CGPoint)point;
//摄像头曝光位置 [0~1][0~1]
- (BOOL)isCameraExposurePointOfInterestSupported;
- (int)setCameraExposurePointOfInterest:(CGPoint)point;
#endif

@end

