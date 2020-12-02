#import "T3GPUImageContext.h"
#import "T3GPUImageFramebuffer.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
// For now, just redefine this on the Mac
typedef NS_ENUM(NSInteger, UIImageOrientation) {
    UIImageOrientationUp,            // default orientation
    UIImageOrientationDown,          // 180 deg rotation
    UIImageOrientationLeft,          // 90 deg CCW
    UIImageOrientationRight,         // 90 deg CW
    UIImageOrientationUpMirrored,    // as above but image mirrored along other axis. horizontal flip
    UIImageOrientationDownMirrored,  // horizontal flip
    UIImageOrientationLeftMirrored,  // vertical flip
    UIImageOrientationRightMirrored, // vertical flip
};
#endif

dispatch_queue_attr_t T3GPUImageDefaultQueueAttribute(void);
void T3runOnMainQueueWithoutDeadlocking(void (^block)(void));
void T3runSynchronouslyOnVideoProcessingQueue(void (^block)(void));
void T3runAsynchronouslyOnVideoProcessingQueue(void (^block)(void));
void T3runSynchronouslyOnContextQueue(T3GPUImageContext *context, void (^block)(void));
void T3runAsynchronouslyOnContextQueue(T3GPUImageContext *context, void (^block)(void));
void T3reportAvailableMemoryForGPUImage(NSString *tag);

@class T3GPUImageMovieWriter;

/** GPUImage's base source object
 
 Images or frames of video are uploaded from source objects, which are subclasses of T3GPUImageOutput. These include:
 
 - T3GPUImageVideoCamera (for live video from an iOS camera) 
 - T3GPUImageStillCamera (for taking photos with the camera)
 - T3GPUImagePicture (for still images)
 - T3GPUImageMovie (for movies)
 
 Source objects upload still image frames to OpenGL ES as textures, then hand those textures off to the next objects in the processing chain.
 */
@interface T3GPUImageOutput : NSObject
{
    T3GPUImageFramebuffer *outputFramebuffer;
    
    NSMutableArray *targets, *targetTextureIndices;
    
    CGSize inputTextureSize, cachedMaximumOutputSize, forcedMaximumSize;
    
    BOOL overrideInputSize;
    
    BOOL allTargetsWantMonochromeData;
    BOOL usingNextFrameForImageCapture;
}

@property(readwrite, nonatomic) BOOL shouldSmoothlyScaleOutput;
@property(readwrite, nonatomic) BOOL shouldIgnoreUpdatesToThisTarget;
@property(readwrite, nonatomic, retain) T3GPUImageMovieWriter *audioEncodingTarget;
@property(readwrite, nonatomic, unsafe_unretained) id<T3GPUImageInput> targetToIgnoreForUpdates;
@property(nonatomic, copy) void(^frameProcessingCompletionBlock)(T3GPUImageOutput*, CMTime);
@property(nonatomic) BOOL enabled;
@property(readwrite, nonatomic) LFGPUTextureOptions outputTextureOptions;

/// @name Managing targets
- (void)setInputFramebufferForTarget:(id<T3GPUImageInput>)target atIndex:(NSInteger)inputTextureIndex;
- (T3GPUImageFramebuffer *)framebufferForOutput;
- (void)removeOutputFramebuffer;
- (void)notifyTargetsAboutNewOutputTexture;

/** Returns an array of the current targets.
 */
- (NSArray*)targets;

/** Adds a target to receive notifications when new frames are available.
 
 The target will be asked for its next available texture.
 
 See [T3GPUImageInput newFrameReadyAtTime:]
 
 @param newTarget Target to be added
 */
- (void)addTarget:(id<T3GPUImageInput>)newTarget;

/** Adds a target to receive notifications when new frames are available.
 
 See [T3GPUImageInput newFrameReadyAtTime:]
 
 @param newTarget Target to be added
 */
- (void)addTarget:(id<T3GPUImageInput>)newTarget atTextureLocation:(NSInteger)textureLocation;

/** Removes a target. The target will no longer receive notifications when new frames are available.
 
 @param targetToRemove Target to be removed
 */
- (void)removeTarget:(id<T3GPUImageInput>)targetToRemove;

/** Removes all targets.
 */
- (void)removeAllTargets;

/// @name Manage the output texture

- (void)forceProcessingAtSize:(CGSize)frameSize;
- (void)forceProcessingAtSizeRespectingAspectRatio:(CGSize)frameSize;

/// @name Still image processing

- (void)useNextFrameForImageCapture;
- (CGImageRef)newCGImageFromCurrentlyProcessedOutput;
- (CGImageRef)newCGImageByFilteringCGImage:(CGImageRef)imageToFilter;

// Platform-specific image output methods
// If you're trying to use these methods, remember that you need to set -useNextFrameForImageCapture before running -processImage or running video and calling any of these methods, or you will get a nil image
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
- (UIImage *)imageFromCurrentFramebuffer;
- (UIImage *)imageFromCurrentFramebufferWithOrientation:(UIImageOrientation)imageOrientation;
- (UIImage *)imageByFilteringImage:(UIImage *)imageToFilter;
- (CGImageRef)newCGImageByFilteringImage:(UIImage *)imageToFilter;
- (CVPixelBufferRef) getOutputPixelBuffer;
#else
- (NSImage *)imageFromCurrentFramebuffer;
- (NSImage *)imageFromCurrentFramebufferWithOrientation:(UIImageOrientation)imageOrientation;
- (NSImage *)imageByFilteringImage:(NSImage *)imageToFilter;
- (CGImageRef)newCGImageByFilteringImage:(NSImage *)imageToFilter;
#endif

- (BOOL)providesMonochromeOutput;

@end
