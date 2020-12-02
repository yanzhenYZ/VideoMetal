#import "T3GLProgram.h"
#import "T3GPUImageFramebuffer.h"
#import "T3GPUImageFramebufferCache.h"

#define GPUImageRotationSwapsWidthAndHeight(rotation) ((rotation) == kT3GPUImageRotateLeft || (rotation) == kT3GPUImageRotateRight || (rotation) == kT3GPUImageRotateRightFlipVertical || (rotation) == kT3GPUImageRotateRightFlipHorizontal)

typedef NS_ENUM(NSUInteger, T3GPUImageRotationMode) {
	kT3GPUImageNoRotation,
	kT3GPUImageRotateLeft,
	kT3GPUImageRotateRight,
	kT3GPUImageFlipVertical,
	kT3GPUImageFlipHorizonal,
	kT3GPUImageRotateRightFlipVertical,
	kT3GPUImageRotateRightFlipHorizontal,
	kT3GPUImageRotate180
};

@interface T3GPUImageContext : NSObject

@property(readonly, nonatomic) dispatch_queue_t contextQueue;
@property(readwrite, retain, nonatomic) T3GLProgram *currentShaderProgram;
@property(readonly, retain, nonatomic) EAGLContext *context;
@property(readonly) CVOpenGLESTextureCacheRef coreVideoTextureCache;
@property(readonly) T3GPUImageFramebufferCache *framebufferCache;

+ (void *)contextKey;
+ (T3GPUImageContext *)sharedImageProcessingContext;
+ (dispatch_queue_t)sharedContextQueue;
+ (T3GPUImageFramebufferCache *)sharedFramebufferCache;
+ (void)clearFrameBufferCache;
+ (void)useImageProcessingContext;
- (void)useAsCurrentContext;
+ (void)setActiveShaderProgram:(T3GLProgram *)shaderProgram;
- (void)setContextShaderProgram:(T3GLProgram *)shaderProgram;
+ (GLint)maximumTextureSizeForThisDevice;
+ (GLint)maximumTextureUnitsForThisDevice;
+ (GLint)maximumVaryingVectorsForThisDevice;
+ (BOOL)deviceSupportsOpenGLESExtension:(NSString *)extension;
+ (BOOL)deviceSupportsRedTextures;
+ (BOOL)deviceSupportsFramebufferReads;
+ (CGSize)sizeThatFitsWithinATextureForSize:(CGSize)inputSize;

- (void)presentBufferForDisplay;
- (T3GLProgram *)programForVertexShaderString:(NSString *)vertexShaderString fragmentShaderString:(NSString *)fragmentShaderString;

- (void)useSharegroup:(EAGLSharegroup *)sharegroup;

// Manage fast texture upload
+ (BOOL)supportsFastTextureUpload;

@end

@protocol T3GPUImageInput <NSObject>
- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex;
- (void)setInputFramebuffer:(T3GPUImageFramebuffer *)newInputFramebuffer atIndex:(NSInteger)textureIndex;
- (NSInteger)nextAvailableTextureIndex;
- (void)setInputSize:(CGSize)newSize atIndex:(NSInteger)textureIndex;
- (void)setInputRotation:(T3GPUImageRotationMode)newInputRotation atIndex:(NSInteger)textureIndex;
- (CGSize)maximumOutputSize;
- (void)endProcessing;
- (BOOL)shouldIgnoreUpdatesToThisTarget;
- (BOOL)enabled;
- (BOOL)wantsMonochromeInput;
- (void)setCurrentlyReceivingMonochromeInput:(BOOL)newValue;
@end
