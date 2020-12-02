#import "T3GPUImageFilter.h"

extern NSString *const kT3GPUImageTwoInputTextureVertexShaderString;

@interface T3GPUImageTwoInputFilter : T3GPUImageFilter
{
    T3GPUImageFramebuffer *secondInputFramebuffer;

    GLint filterSecondTextureCoordinateAttribute;
    GLint filterInputTextureUniform2;
    T3GPUImageRotationMode inputRotation2;
    CMTime firstFrameTime, secondFrameTime;
    
    BOOL hasSetFirstTexture, hasReceivedFirstFrame, hasReceivedSecondFrame, firstFrameWasVideo, secondFrameWasVideo;
    BOOL firstFrameCheckDisabled, secondFrameCheckDisabled;
}

- (void)disableFirstFrameCheck;
- (void)disableSecondFrameCheck;

@end
