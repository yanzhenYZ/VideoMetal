#import "T3GPUImageOutput.h"

#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define SHADER_STRING(text) @ STRINGIZE2(text)

#define GPUImageHashIdentifier #
#define GPUImageWrappedLabel(x) x
#define GPUImageEscapedHashIdentifier(a) GPUImageWrappedLabel(GPUImageHashIdentifier)a

extern NSString *const kT3GPUImageVertexShaderString;
extern NSString *const kT3GPUImagePassthroughFragmentShaderString;

struct LFGPUVector4 {
    GLfloat one;
    GLfloat two;
    GLfloat three;
    GLfloat four;
};
typedef struct LFGPUVector4 LFGPUVector4;

struct LFGPUVector3 {
    GLfloat one;
    GLfloat two;
    GLfloat three;
};
typedef struct LFGPUVector3 LFGPUVector3;

struct LFGPUMatrix4x4 {
    LFGPUVector4 one;
    LFGPUVector4 two;
    LFGPUVector4 three;
    LFGPUVector4 four;
};
typedef struct LFGPUMatrix4x4 LFGPUMatrix4x4;

struct LFGPUMatrix3x3 {
    LFGPUVector3 one;
    LFGPUVector3 two;
    LFGPUVector3 three;
};
typedef struct LFGPUMatrix3x3 LFGPUMatrix3x3;

/** GPUImage's base filter class
 
 Filters and other subsequent elements in the chain conform to the T3GPUImageInput protocol, which lets them take in the supplied or processed texture from the previous link in the chain and do something with it. Objects one step further down the chain are considered targets, and processing can be branched by adding multiple targets to a single output or filter.
 */
@interface T3GPUImageFilter : T3GPUImageOutput <T3GPUImageInput>
{
    T3GPUImageFramebuffer *firstInputFramebuffer;
    
    T3GLProgram *filterProgram;
    GLint filterPositionAttribute, filterTextureCoordinateAttribute;
    GLint filterInputTextureUniform;
    GLfloat backgroundColorRed, backgroundColorGreen, backgroundColorBlue, backgroundColorAlpha;
    
    BOOL isEndProcessing;

    CGSize currentFilterSize;
    T3GPUImageRotationMode inputRotation;
    
    BOOL currentlyReceivingMonochromeInput;
    
    NSMutableDictionary *uniformStateRestorationBlocks;
    dispatch_semaphore_t imageCaptureSemaphore;
}

@property(readonly) CVPixelBufferRef renderTarget;
@property(readwrite, nonatomic) BOOL preventRendering;
@property(readwrite, nonatomic) BOOL currentlyReceivingMonochromeInput;

/// @name Initialization and teardown

/**
 Initialize with vertex and fragment shaders
 
 You make take advantage of the SHADER_STRING macro to write your shaders in-line.
 @param vertexShaderString Source code of the vertex shader to use
 @param fragmentShaderString Source code of the fragment shader to use
 */
- (id)initWithVertexShaderFromString:(NSString *)vertexShaderString fragmentShaderFromString:(NSString *)fragmentShaderString;

/**
 Initialize with a fragment shader
 
 You may take advantage of the SHADER_STRING macro to write your shader in-line.
 @param fragmentShaderString Source code of fragment shader to use
 */
- (id)initWithFragmentShaderFromString:(NSString *)fragmentShaderString;
/**
 Initialize with a fragment shader
 @param fragmentShaderFilename Filename of fragment shader to load
 */
- (id)initWithFragmentShaderFromFile:(NSString *)fragmentShaderFilename;
- (void)initializeAttributes;
- (void)setupFilterForSize:(CGSize)filterFrameSize;
- (CGSize)rotatedSize:(CGSize)sizeToRotate forIndex:(NSInteger)textureIndex;
- (CGPoint)rotatedPoint:(CGPoint)pointToRotate forRotation:(T3GPUImageRotationMode)rotation;

/// @name Managing the display FBOs
/** Size of the frame buffer object
 */
- (CGSize)sizeOfFBO;

/// @name Rendering
+ (const GLfloat *)textureCoordinatesForRotation:(T3GPUImageRotationMode)rotationMode;
- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates;
- (void)informTargetsAboutNewFrameAtTime:(CMTime)frameTime;
- (CGSize)outputFrameSize;

/// @name Input parameters
- (void)setBackgroundColorRed:(GLfloat)redComponent green:(GLfloat)greenComponent blue:(GLfloat)blueComponent alpha:(GLfloat)alphaComponent;
- (void)setInteger:(GLint)newInteger forUniformName:(NSString *)uniformName;
- (void)setFloat:(GLfloat)newFloat forUniformName:(NSString *)uniformName;
- (void)setSize:(CGSize)newSize forUniformName:(NSString *)uniformName;
- (void)setPoint:(CGPoint)newPoint forUniformName:(NSString *)uniformName;
- (void)setFloatVec3:(LFGPUVector3)newVec3 forUniformName:(NSString *)uniformName;
- (void)setFloatVec4:(LFGPUVector4)newVec4 forUniform:(NSString *)uniformName;
- (void)setFloatArray:(GLfloat *)array length:(GLsizei)count forUniform:(NSString*)uniformName;

- (void)setMatrix3f:(LFGPUMatrix3x3)matrix forUniform:(GLint)uniform program:(T3GLProgram *)shaderProgram;
- (void)setMatrix4f:(LFGPUMatrix4x4)matrix forUniform:(GLint)uniform program:(T3GLProgram *)shaderProgram;
- (void)setFloat:(GLfloat)floatValue forUniform:(GLint)uniform program:(T3GLProgram *)shaderProgram;
- (void)setPoint:(CGPoint)pointValue forUniform:(GLint)uniform program:(T3GLProgram *)shaderProgram;
- (void)setSize:(CGSize)sizeValue forUniform:(GLint)uniform program:(T3GLProgram *)shaderProgram;
- (void)setVec3:(LFGPUVector3)vectorValue forUniform:(GLint)uniform program:(T3GLProgram *)shaderProgram;
- (void)setVec4:(LFGPUVector4)vectorValue forUniform:(GLint)uniform program:(T3GLProgram *)shaderProgram;
- (void)setFloatArray:(GLfloat *)arrayValue length:(GLsizei)arrayLength forUniform:(GLint)uniform program:(T3GLProgram *)shaderProgram;
- (void)setInteger:(GLint)intValue forUniform:(GLint)uniform program:(T3GLProgram *)shaderProgram;

- (void)setAndExecuteUniformStateCallbackAtIndex:(GLint)uniform forProgram:(T3GLProgram *)shaderProgram toBlock:(dispatch_block_t)uniformStateBlock;
- (void)setUniformsForProgramAtIndex:(NSUInteger)programIndex;

@end
