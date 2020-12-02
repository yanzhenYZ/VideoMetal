//
//  YZHelper.h
//  test
//
//  Created by Work on 2019/8/29.
//  Copyright © 2019 yanzhen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YZContextTool.h"

static void YZrunAsynchronouslyOnVideoProcessingQueue(void (^block)(void))
{
    dispatch_queue_t videoProcessingQueue = [YZContextTool sharedContextQueue];
#if !OS_OBJECT_USE_OBJC
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (dispatch_get_current_queue() == videoProcessingQueue)
#pragma clang diagnostic pop
#else
        if (dispatch_get_specific([YZContextTool contextKey]))
#endif
        {
            block();
        }else
        {
            dispatch_async(videoProcessingQueue, block);
        }
}


static void YZrunSynchronouslyOnVideoProcessingQueue(void (^block)(void))
{
    dispatch_queue_t videoProcessingQueue = [YZContextTool sharedContextQueue];
#if !OS_OBJECT_USE_OBJC
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (dispatch_get_current_queue() == videoProcessingQueue)
#pragma clang diagnostic pop
#else
        if (dispatch_get_specific([YZContextTool contextKey]))
#endif
        {
            block();
        }else
        {
            dispatch_sync(videoProcessingQueue, block);
        }
}

static GLfloat YZcolorConversion601Default[] = {
    1.164,  1.164, 1.164,
    0.0, -0.392, 2.017,
    1.596, -0.813,   0.0,
};

// BT.601 full range (ref: http://www.equasys.de/colorconversion.html)
static GLfloat YZcolorConversion601FullRangeDefault[] = {
    1.0,    1.0,    1.0,
    0.0,    -0.343, 1.765,
    1.4,    -0.711, 0.0,
};

// BT.709, which is the standard for HDTV.
static GLfloat YZcolorConversion709Default[] = {
    1.164,  1.164, 1.164,
    0.0, -0.213, 2.112,
    1.793, -0.533,   0.0,
};


static GLfloat *kYZColorConversion601 = YZcolorConversion601Default;
static GLfloat *kYZColorConversion601FullRange = YZcolorConversion601FullRangeDefault;
static GLfloat *kYZColorConversion709 = YZcolorConversion709Default;

typedef NS_ENUM(NSUInteger, YZGPUImageRotationMode) {
    kYZGPUImageNoRotation,
    kYZGPUImageRotateLeft,
    kYZGPUImageRotateRight,
    kYZGPUImageFlipVertical,
    kYZGPUImageFlipHorizonal,
    kYZGPUImageRotateRightFlipVertical,
    kYZGPUImageRotateRightFlipHorizontal,
    kYZGPUImageRotate180
};

#define YZGPUImageRotationSwapsWidthAndHeight(rotation) ((rotation) == kYZGPUImageRotateLeft || (rotation) == kYZGPUImageRotateRight || (rotation) == kYZGPUImageRotateRightFlipVertical || (rotation) == kYZGPUImageRotateRightFlipHorizontal)



@interface YZHelper : NSObject
+ (const GLfloat *)textureCoordinatesForRotation:(YZGPUImageRotationMode)rotationMode;
@end

