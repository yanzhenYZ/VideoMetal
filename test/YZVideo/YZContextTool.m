//
//  YZContextTool.m
//  test
//
//  Created by Work on 2019/8/29.
//  Copyright © 2019 yanzhen. All rights reserved.
//

#import "YZContextTool.h"
#import <CoreVideo/CoreVideo.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>

@interface YZContextTool ()
@property (nonatomic, strong) EAGLContext *context;
@property (nonatomic, strong) NSMutableDictionary *shaderProgramCache;
@property(readonly, nonatomic) dispatch_queue_t contextQueue;
@end

static void *YZopenGLESContextQueueKey;

@implementation YZContextTool {
    EAGLSharegroup *_sharegroup;
}

+ (YZContextTool *)shared;
{
    static dispatch_once_t once;
    static id context = nil;
    
    dispatch_once(&once, ^{
        context = [[[self class] alloc] init];
    });
    return context;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        dispatch_queue_attr_t attr = nil;
        if ([[[UIDevice currentDevice] systemVersion] compare:@"9.0" options:NSNumericSearch] != NSOrderedAscending)
        {
            attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_DEFAULT, 0);
        }
        YZopenGLESContextQueueKey = &YZopenGLESContextQueueKey;
        _contextQueue = dispatch_queue_create("com.sunsetlakesoftware.GPUImage.openGLESContextQueue", attr);
    
        dispatch_queue_set_specific(_contextQueue, YZopenGLESContextQueueKey, (__bridge void *)self, NULL);
    }
    return self;
}

+ (void *)contextKey {
    return YZopenGLESContextQueueKey;
}

+ (dispatch_queue_t)sharedContextQueue;
{
    return [[self shared] contextQueue];
}


+ (BOOL)supportsFastTextureUpload {
    return CVOpenGLESTextureCacheCreate != NULL;
}

+ (BOOL)deviceSupportsRedTextures;
{
    static dispatch_once_t pred;
    static BOOL supportsRedTextures = NO;
    
    dispatch_once(&pred, ^{
        supportsRedTextures = [YZContextTool deviceSupportsOpenGLESExtension:@"GL_EXT_texture_rg"];
    });
    
    return supportsRedTextures;
}

+ (BOOL)deviceSupportsOpenGLESExtension:(NSString *)extension;
{
    static dispatch_once_t pred;
    static NSArray *extensionNames = nil;
    
    // Cache extensions for later quick reference, since this won't change for a given device
    dispatch_once(&pred, ^{
        [YZContextTool useImageProcessingContext];
        NSString *extensionsString = [NSString stringWithCString:(const char *)glGetString(GL_EXTENSIONS) encoding:NSASCIIStringEncoding];
        extensionNames = [extensionsString componentsSeparatedByString:@" "];
    });
    
    return [extensionNames containsObject:extension];
}

+ (void)useImageProcessingContext;
{
    [[self shared] useAsCurrentContext];
}

+ (YZFrameBufferCache *)sharedFramebufferCache {
    return [[self shared] framebufferCache];
}

+ (void)setActiveShaderProgram:(YZProgram *)shaderProgram
{
    [YZContextTool.shared setContextShaderProgram:shaderProgram];
}

- (CVOpenGLESTextureCacheRef)coreVideoTextureCache
{
    if (_coreVideoTextureCache == NULL)
    {
        CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, [self context], NULL, &_coreVideoTextureCache);
        if (err)
        {
            NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreate %d", err);
        }
        
    }
    
    return _coreVideoTextureCache;
}

- (void)useAsCurrentContext;
{
    EAGLContext *imageProcessingContext = [self context];
    if ([EAGLContext currentContext] != imageProcessingContext)
    {
        [EAGLContext setCurrentContext:imageProcessingContext];
    }
}

- (EAGLContext *)context;
{
    if (_context == nil)
    {
        _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2 sharegroup:_sharegroup];
        [EAGLContext setCurrentContext:_context];
        
        // Set up a few global settings for the image processing pipeline
        glDisable(GL_DEPTH_TEST);
    }
    
    return _context;
}


- (YZProgram *)programForVertexShaderString:(NSString *)vertexShaderString fragmentShaderString:(NSString *)fragmentShaderString {
    NSString *lookupKeyForShaderProgram = [NSString stringWithFormat:@"V: %@ - F: %@", vertexShaderString, fragmentShaderString];
    YZProgram *programFromCache = [_shaderProgramCache objectForKey:lookupKeyForShaderProgram];
    
    if (programFromCache == nil)
    {
        programFromCache = [[YZProgram alloc] initWithVertexShaderString:vertexShaderString fragmentShaderString:fragmentShaderString];
        [_shaderProgramCache setObject:programFromCache forKey:lookupKeyForShaderProgram];
    }
    
    return programFromCache;
}

- (void)setContextShaderProgram:(YZProgram *)shaderProgram;
{
    EAGLContext *imageProcessingContext = [self context];
    if ([EAGLContext currentContext] != imageProcessingContext)
    {
        [EAGLContext setCurrentContext:imageProcessingContext];
    }
    
    if (self.currentShaderProgram != shaderProgram) {
        self.currentShaderProgram = shaderProgram;
        [shaderProgram use];
    }
}

-(YZFrameBufferCache *)framebufferCache {
    if (!_framebufferCache) {
        _framebufferCache = [[YZFrameBufferCache alloc] init];
    }
    return _framebufferCache;
}
@end
