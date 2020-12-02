//
//  YZFrameBuffer.h
//  test
//
//  Created by Work on 2019/10/22.
//  Copyright © 2019 yanzhen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

typedef struct YZGPUTextureOptions {
    GLenum minFilter;
    GLenum magFilter;
    GLenum wrapS;
    GLenum wrapT;
    GLenum internalFormat;
    GLenum format;
    GLenum type;
} YZGPUTextureOptions;

@interface YZFrameBuffer : NSObject
@property(readonly) CGSize size;
@property(readonly) YZGPUTextureOptions textureOptions;
@property(readonly) GLuint texture;
@property(readonly) BOOL missingFramebuffer;
@property (nonatomic, assign) BOOL preventReleaseTexture;

- (instancetype)initWithSize:(CGSize)framebufferSize textureOptions:(YZGPUTextureOptions)fboTextureOptions onlyTexture:(BOOL)onlyGenerateTexture;

- (void)activateFramebuffer;

- (void)lock;
- (void)unlock;
- (void)clearAllLocks;
@end

