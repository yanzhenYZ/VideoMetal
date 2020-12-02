#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import "T3GPUImageFramebuffer.h"

@interface T3GPUImageFramebufferCache : NSObject

// Framebuffer management
- (T3GPUImageFramebuffer *)fetchFramebufferForSize:(CGSize)framebufferSize textureOptions:(LFGPUTextureOptions)textureOptions onlyTexture:(BOOL)onlyTexture;
- (T3GPUImageFramebuffer *)fetchFramebufferForSize:(CGSize)framebufferSize onlyTexture:(BOOL)onlyTexture;
- (void)returnFramebufferToCache:(T3GPUImageFramebuffer *)framebuffer;
- (void)purgeAllUnassignedFramebuffers;
- (void)addFramebufferToActiveImageCaptureList:(T3GPUImageFramebuffer *)framebuffer;
- (void)removeFramebufferFromActiveImageCaptureList:(T3GPUImageFramebuffer *)framebuffer;

@end
