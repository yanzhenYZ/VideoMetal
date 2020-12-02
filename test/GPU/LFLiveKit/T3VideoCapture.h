//
//  T3VideoCapture.h
//  LFLiveKit
//
//  Created by LaiFeng on 16/5/20.
//  Copyright © 2016年 LaiFeng All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "T3LiveVideoConfiguration.h"

@class T3VideoCapture;
/** T3VideoCapture callback videoData */
@protocol T3VideoCaptureDelegate <NSObject>
- (void)captureOutput:(T3VideoCapture *)capture pixelBuffer:(CVPixelBufferRef)pixelBuffer;
- (void)willOutput:(T3VideoCapture *)capture pixelBuffer:(CVPixelBufferRef)pixelBuffer;
//- (void)firstLocalVideoFrameRenderedWithSize:(CGSize)size;
@end

@interface T3VideoCapture : NSObject

#pragma mark - Attribute
///=============================================================================
/// @name Attribute
///=============================================================================

/** The delegate of the capture. captureData callback */
@property (nullable, nonatomic, weak) id<T3VideoCaptureDelegate> delegate;

/** The running control start capture or stop capture*/
@property (nonatomic, assign) BOOL running;

/** The preView will show OpenGL ES view*/
@property (null_resettable, nonatomic, strong) UIView *preView;

/** The captureDevicePosition control camraPosition ,default front*/
@property (nonatomic, assign) AVCaptureDevicePosition captureDevicePosition;

/** The beautyFace control capture shader filter empty or beautiy */
@property (nonatomic, assign) BOOL beautyFace;

/** The torch control capture flash is on or off */
@property (nonatomic, assign) BOOL torch;

/** The mirror control mirror of front camera is on or off */
@property (nonatomic, assign) BOOL mirror;

/** The beautyLevel control beautyFace Level, default 0.5, between 0.0 ~ 1.0 */
@property (nonatomic, assign) CGFloat beautyLevel;

/** The brightLevel control brightness Level, default 0.5, between 0.0 ~ 1.0 */
@property (nonatomic, assign) CGFloat brightLevel;

/** The torch control camera zoom scale default 1.0, between 1.0 ~ 3.0 */
@property (nonatomic, assign) CGFloat zoomScale;

/** The videoFrameRate control videoCapture output data count */
@property (nonatomic, assign) NSInteger videoFrameRate;

/*** The warterMarkView control whether the watermark is displayed or not ,if set ni,will remove watermark,otherwise add *.*/
@property (nonatomic, strong, nullable) UIView *warterMarkView;

/* The currentImage is videoCapture shot */
@property (nonatomic, strong, nullable) UIImage *currentImage;

/* The saveLocalVideo is save the local video */
@property (nonatomic, assign) BOOL saveLocalVideo;

/* The saveLocalVideoPath is save the local video  path */
@property (nonatomic, strong, nullable) NSURL *saveLocalVideoPath;

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
- (nullable instancetype)initWithVideoConfiguration:(nullable T3LiveVideoConfiguration *)configuration NS_DESIGNATED_INITIALIZER;

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
