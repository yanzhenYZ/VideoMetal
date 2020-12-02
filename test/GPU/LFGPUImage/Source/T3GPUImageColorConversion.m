#import "T3GPUImageFilter.h"

// Color Conversion Constants (YUV to RGB) including adjustment from 16-235/16-240 (video range)

// BT.601, which is the standard for SDTV.
GLfloat T3ColorConversion601Default[] = {
    1.164,  1.164, 1.164,
    0.0, -0.392, 2.017,
    1.596, -0.813,   0.0,
};

// BT.601 full range (ref: http://www.equasys.de/colorconversion.html)
GLfloat T3ColorConversion601FullRangeDefault[] = {
    1.0,    1.0,    1.0,
    0.0,    -0.343, 1.765,
    1.4,    -0.711, 0.0,
};

// BT.709, which is the standard for HDTV.
GLfloat T3ColorConversion709Default[] = {
    1.164,  1.164, 1.164,
    0.0, -0.213, 2.112,
    1.793, -0.533,   0.0,
};


GLfloat *kT3ColorConversion601 = T3ColorConversion601Default;
GLfloat *kT3ColorConversion601FullRange = T3ColorConversion601FullRangeDefault;
GLfloat *kT3ColorConversion709 = T3ColorConversion709Default;

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kT3GPUImageYUVVideoRangeConversionForRGFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D luminanceTexture;
 uniform sampler2D chrominanceTexture;
 uniform mediump mat3 colorConversionMatrix;
 
 void main()
 {
     mediump vec3 yuv;
     lowp vec3 rgb;
     
     yuv.x = texture2D(luminanceTexture, textureCoordinate).r;
     yuv.yz = texture2D(chrominanceTexture, textureCoordinate).rg - vec2(0.5, 0.5);
     rgb = colorConversionMatrix * yuv;
     
     gl_FragColor = vec4(rgb, 1);
 }
 );
#else
NSString *const kT3GPUImageYUVVideoRangeConversionForRGFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 
 uniform sampler2D luminanceTexture;
 uniform sampler2D chrominanceTexture;
 
 void main()
 {
     vec3 yuv;
     vec3 rgb;
     
     yuv.x = texture2D(luminanceTexture, textureCoordinate).r;
     yuv.yz = texture2D(chrominanceTexture, textureCoordinate).rg - vec2(0.5, 0.5);
     
     // BT.601, which is the standard for SDTV is provided as a reference
     /*
      rgb = mat3(      1,       1,       1,
      0, -.39465, 2.03211,
      1.13983, -.58060,       0) * yuv;
      */
     
     // Using BT.709 which is the standard for HDTV
     rgb = mat3(      1,       1,       1,
                0, -.21482, 2.12798,
                1.28033, -.38059,       0) * yuv;
     
     gl_FragColor = vec4(rgb, 1);
 }
 );
#endif

NSString *const kT3GPUImageYUVFullRangeConversionForLAFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D luminanceTexture;
 uniform sampler2D chrominanceTexture;
 uniform mediump mat3 colorConversionMatrix;
 
 void main()
 {
     mediump vec3 yuv;
     lowp vec3 rgb;
     
     yuv.x = texture2D(luminanceTexture, textureCoordinate).r;
     yuv.yz = texture2D(chrominanceTexture, textureCoordinate).ra - vec2(0.5, 0.5);
     rgb = colorConversionMatrix * yuv;
     
     gl_FragColor = vec4(rgb, 1);
 }
 );

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kT3GPUImageYUVVideoRangeConversionForLAFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D luminanceTexture;
 uniform sampler2D chrominanceTexture;
 uniform mediump mat3 colorConversionMatrix;
 
 void main()
 {
     mediump vec3 yuv;
     lowp vec3 rgb;
     
     yuv.x = texture2D(luminanceTexture, textureCoordinate).r - (16.0/255.0);
     yuv.yz = texture2D(chrominanceTexture, textureCoordinate).ra - vec2(0.5, 0.5);
     rgb = colorConversionMatrix * yuv;
     
     gl_FragColor = vec4(rgb, 1);
 }
 );
#else
NSString *const kT3GPUImageYUVVideoRangeConversionForLAFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 
 uniform sampler2D luminanceTexture;
 uniform sampler2D chrominanceTexture;
 
 void main()
 {
     vec3 yuv;
     vec3 rgb;
     
     yuv.x = texture2D(luminanceTexture, textureCoordinate).r;
     yuv.yz = texture2D(chrominanceTexture, textureCoordinate).ra - vec2(0.5, 0.5);
     
     // BT.601, which is the standard for SDTV is provided as a reference
     /*
      rgb = mat3(      1,       1,       1,
      0, -.39465, 2.03211,
      1.13983, -.58060,       0) * yuv;
      */
     
     // Using BT.709 which is the standard for HDTV
     rgb = mat3(      1,       1,       1,
                0, -.21482, 2.12798,
                1.28033, -.38059,       0) * yuv;
     
     gl_FragColor = vec4(rgb, 1);
 }
 );
#endif

