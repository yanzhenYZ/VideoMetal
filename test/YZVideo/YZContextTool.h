//
//  YZContextTool.h
//  test
//
//  Created by Work on 2019/8/29.
//  Copyright © 2019 yanzhen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YZProgram.h"
#import "YZFrameBuffer.h"
#import "YZFrameBufferCache.h"

#define YZSTRINGIZE(x) #x
#define YZSTRINGIZE2(x) YZSTRINGIZE(x)
#define YZSHADER_STRING(text) @ YZSTRINGIZE2(text)

static NSString *const kYZGPUImageVertexShaderString = YZSHADER_STRING
(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 
 varying vec2 textureCoordinate;
 
 void main()
 {
     gl_Position = position;
     textureCoordinate = inputTextureCoordinate.xy;
 }
 );

static NSString *const kYZGPUImageYUVFullRangeConversionForLAFragmentShaderString = YZSHADER_STRING
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


@interface YZContextTool : NSObject
@property (readwrite, retain, nonatomic) YZProgram *currentShaderProgram;
@property (nonatomic) CVOpenGLESTextureCacheRef coreVideoTextureCache;
@property (nonatomic, strong) YZFrameBufferCache *framebufferCache;

+ (YZContextTool *)shared;

+ (void *)contextKey;

+ (BOOL)supportsFastTextureUpload;
+ (void)useImageProcessingContext;
+ (BOOL)deviceSupportsRedTextures;
+ (void)setActiveShaderProgram:(YZProgram *)shaderProgram;

+ (dispatch_queue_t)sharedContextQueue;
+ (YZFrameBufferCache *)sharedFramebufferCache;

- (YZProgram *)programForVertexShaderString:(NSString *)vertexShaderString fragmentShaderString:(NSString *)fragmentShaderString;

@end

