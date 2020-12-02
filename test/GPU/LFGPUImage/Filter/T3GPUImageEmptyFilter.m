#import "T3GPUImageEmptyFilter.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kT3GPUImageEmptyFragmentShaderString = SHADER_STRING
                                                       (
    varying highp vec2 textureCoordinate;

    uniform sampler2D inputImageTexture;

    void main(){
    lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);

    gl_FragColor = vec4((textureColor.rgb), textureColor.w);
}

                                                       );
#else
NSString *const kT3GPUImageInvertFragmentShaderString = SHADER_STRING
                                                      (
    varying vec2 textureCoordinate;

    uniform sampler2D inputImageTexture;

    void main(){
    vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);

    gl_FragColor = vec4((textureColor.rgb), textureColor.w);
}

                                                      );
#endif

@implementation T3GPUImageEmptyFilter

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kT3GPUImageEmptyFragmentShaderString])) {
        return nil;
    }

    return self;
}

@end

