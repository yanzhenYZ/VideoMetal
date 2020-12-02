#ifdef BUILD_CUTE_FACE

#import "T3GPUImageCuteFilter.h"
#import <facekit/facekit.h>

NSString *const kT3GPUImageCuteFragmentShaderString = SHADER_STRING
                                                       (
    varying highp vec2 textureCoordinate;

    uniform sampler2D inputImageTexture;

    void main(){
    lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);

    gl_FragColor = vec4((textureColor.rgb), textureColor.w);
}

                                                       );

static LMRenderEngine *renderEngine = nil;
@interface T3GPUImageCuteFilter()
{
    CVPixelBufferRef outputPixelbuffer;
}

@end

@implementation T3GPUImageCuteFilter

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kT3GPUImageCuteFragmentShaderString])) {
        return nil;
    }
    
    LMRenderEngineOption option;
    option.faceless = NO;
    option.orientation = AVCaptureVideoOrientationPortrait;
    if (renderEngine == nil)
    {
        renderEngine = [LMRenderEngine engineForTextureWithGLContext:[T3GPUImageContext sharedImageProcessingContext].context queue:[T3GPUImageContext sharedContextQueue] option:option];
    
        NSBundle *resBundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"LMEffectResource" ofType:@"bundle"]];
        NSString *sandboxPath = [resBundle pathForResource:@"effect/cat_ear" ofType:@""];
        LMFilterPos pos = [renderEngine applyWithPath:sandboxPath];
    }

    return self;
}

- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates;
{
    if (self.preventRendering)
    {
        [firstInputFramebuffer unlock];
        return;
    }
    
    GLuint _videoTexture = [firstInputFramebuffer texture];
    /*
    [T3GPUImageContext useImageProcessingContext];
    glBindTexture(GL_TEXTURE_2D, _videoTexture);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
     */
    
    CGSize size = [self sizeOfFBO];
    
    GLuint tex;
    [renderEngine processTexture:_videoTexture size:size outputTexture:&tex outputPixelBuffer:&outputPixelbuffer];
    
    [T3GPUImageContext setActiveShaderProgram:filterProgram];
    
    outputFramebuffer = [[T3GPUImageContext sharedFramebufferCache] fetchFramebufferForSize:[self sizeOfFBO] textureOptions:self.outputTextureOptions onlyTexture:NO];
    [outputFramebuffer activateFramebuffer];
    if (usingNextFrameForImageCapture)
    {
        [outputFramebuffer lock];
    }
    
    [self setUniformsForProgramAtIndex:0];
    
    glClearColor(backgroundColorRed, backgroundColorGreen, backgroundColorBlue, backgroundColorAlpha);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glActiveTexture(GL_TEXTURE2);
    //glBindTexture(GL_TEXTURE_2D, [firstInputFramebuffer texture]);
    glBindTexture(GL_TEXTURE_2D, tex);
    
    glUniform1i(filterInputTextureUniform, 2);
    
    glVertexAttribPointer(filterPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
    glVertexAttribPointer(filterTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    [firstInputFramebuffer unlock];
    
    if (usingNextFrameForImageCapture)
    {
        dispatch_semaphore_signal(imageCaptureSemaphore);
    }
}

- (void)informTargetsAboutNewFrameAtTime:(CMTime)frameTime;
{
    if (self.frameProcessingCompletionBlock != NULL)
    {
        self.frameProcessingCompletionBlock(self, frameTime);
    }
    
    // Get all targets the framebuffer so they can grab a lock on it
    for (id<T3GPUImageInput> currentTarget in targets)
    {
        if (currentTarget != self.targetToIgnoreForUpdates)
        {
            NSInteger indexOfObject = [targets indexOfObject:currentTarget];
            NSInteger textureIndex = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];
            
            [self setInputFramebufferForTarget:currentTarget atIndex:textureIndex];
            [currentTarget setInputSize:[self outputFrameSize] atIndex:textureIndex];
        }
    }
    
    // Release our hold so it can return to the cache immediately upon processing
    [[self framebufferForOutput] unlock];
    
    if (usingNextFrameForImageCapture)
    {
        //        usingNextFrameForImageCapture = NO;
    }
    else
    {
        [self removeOutputFramebuffer];
    }
    
    // Trigger processing last, so that our unlock comes first in serial execution, avoiding the need for a callback
    for (id<T3GPUImageInput> currentTarget in targets)
    {
        if (currentTarget != self.targetToIgnoreForUpdates)
        {
            NSInteger indexOfObject = [targets indexOfObject:currentTarget];
            NSInteger textureIndex = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];
            [currentTarget newFrameReadyAtTime:frameTime atIndex:textureIndex];
        }
    }
}

- (CVPixelBufferRef) getOutputPixelBuffer
{
    return outputPixelbuffer;
}

@end

#endif

