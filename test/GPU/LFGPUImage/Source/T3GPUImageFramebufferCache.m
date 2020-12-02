#import "T3GPUImageFramebufferCache.h"
#import "T3GPUImageContext.h"
#import "T3GPUImageOutput.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#endif

@interface T3GPUImageFramebufferCache()
{
//    NSCache *framebufferCache;
    NSMutableDictionary *framebufferCache;
    NSMutableDictionary *framebufferTypeCounts;
    NSMutableArray *activeImageCaptureList; // Where framebuffers that may be lost by a filter, but which are still needed for a UIImage, etc., are stored
    id memoryWarningObserver;

    dispatch_queue_t framebufferCacheQueue;
}

- (NSString *)hashForSize:(CGSize)size textureOptions:(LFGPUTextureOptions)textureOptions onlyTexture:(BOOL)onlyTexture;

@end


@implementation T3GPUImageFramebufferCache

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super init]))
    {
		return nil;
    }
    
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
    __unsafe_unretained __typeof__ (self) weakSelf = self;
    memoryWarningObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidReceiveMemoryWarningNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        __typeof__ (self) strongSelf = weakSelf;
        if (strongSelf) {
            [strongSelf purgeAllUnassignedFramebuffers];
        }
    }];
#else
#endif

//    framebufferCache = [[NSCache alloc] init];
    framebufferCache = [[NSMutableDictionary alloc] init];
    framebufferTypeCounts = [[NSMutableDictionary alloc] init];
    activeImageCaptureList = [[NSMutableArray alloc] init];
    framebufferCacheQueue = dispatch_queue_create("com.sunsetlakesoftware.GPUImage.framebufferCacheQueue", T3GPUImageDefaultQueueAttribute());
    
    return self;
}

- (void)dealloc;
{
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
    [[NSNotificationCenter defaultCenter] removeObserver:self];
#else
#endif
}

#pragma mark -
#pragma mark Framebuffer management

- (NSString *)hashForSize:(CGSize)size textureOptions:(LFGPUTextureOptions)textureOptions onlyTexture:(BOOL)onlyTexture;
{
    if (onlyTexture)
    {
        return [NSString stringWithFormat:@"%.1fx%.1f-%d:%d:%d:%d:%d:%d:%d-NOFB", size.width, size.height, textureOptions.minFilter, textureOptions.magFilter, textureOptions.wrapS, textureOptions.wrapT, textureOptions.internalFormat, textureOptions.format, textureOptions.type];
    }
    else
    {
        return [NSString stringWithFormat:@"%.1fx%.1f-%d:%d:%d:%d:%d:%d:%d", size.width, size.height, textureOptions.minFilter, textureOptions.magFilter, textureOptions.wrapS, textureOptions.wrapT, textureOptions.internalFormat, textureOptions.format, textureOptions.type];
    }
}

- (T3GPUImageFramebuffer *)fetchFramebufferForSize:(CGSize)framebufferSize textureOptions:(LFGPUTextureOptions)textureOptions onlyTexture:(BOOL)onlyTexture;
{
    __block T3GPUImageFramebuffer *framebufferFromCache = nil;
//    dispatch_sync(framebufferCacheQueue, ^{
    T3runSynchronouslyOnVideoProcessingQueue(^{
        NSString *lookupHash = [self hashForSize:framebufferSize textureOptions:textureOptions onlyTexture:onlyTexture];
        NSNumber *numberOfMatchingTexturesInCache = [framebufferTypeCounts objectForKey:lookupHash];
        NSInteger numberOfMatchingTextures = [numberOfMatchingTexturesInCache integerValue];
        
        if ([numberOfMatchingTexturesInCache integerValue] < 1)
        {
            // Nothing in the cache, create a new framebuffer to use
            framebufferFromCache = [[T3GPUImageFramebuffer alloc] initWithSize:framebufferSize textureOptions:textureOptions onlyTexture:onlyTexture];
        }
        else
        {
            // Something found, pull the old framebuffer and decrement the count
            NSInteger currentTextureID = (numberOfMatchingTextures - 1);
            while ((framebufferFromCache == nil) && (currentTextureID >= 0))
            {
                NSString *textureHash = [NSString stringWithFormat:@"%@-%ld", lookupHash, (long)currentTextureID];
                framebufferFromCache = [framebufferCache objectForKey:textureHash];
                // Test the values in the cache first, to see if they got invalidated behind our back
                if (framebufferFromCache != nil)
                {
                    // Withdraw this from the cache while it's in use
                    [framebufferCache removeObjectForKey:textureHash];
                }
                currentTextureID--;
            }
            
            currentTextureID++;
            
            [framebufferTypeCounts setObject:[NSNumber numberWithInteger:currentTextureID] forKey:lookupHash];
            
            if (framebufferFromCache == nil)
            {
                framebufferFromCache = [[T3GPUImageFramebuffer alloc] initWithSize:framebufferSize textureOptions:textureOptions onlyTexture:onlyTexture];
            }
        }
    });

    [framebufferFromCache lock];
    return framebufferFromCache;
}

- (T3GPUImageFramebuffer *)fetchFramebufferForSize:(CGSize)framebufferSize onlyTexture:(BOOL)onlyTexture;
{
    LFGPUTextureOptions defaultTextureOptions;
    defaultTextureOptions.minFilter = GL_LINEAR;
    defaultTextureOptions.magFilter = GL_LINEAR;
    defaultTextureOptions.wrapS = GL_CLAMP_TO_EDGE;
    defaultTextureOptions.wrapT = GL_CLAMP_TO_EDGE;
    defaultTextureOptions.internalFormat = GL_RGBA;
    defaultTextureOptions.format = GL_BGRA;
    defaultTextureOptions.type = GL_UNSIGNED_BYTE;
    
    return [self fetchFramebufferForSize:framebufferSize textureOptions:defaultTextureOptions onlyTexture:onlyTexture];
}

- (void)returnFramebufferToCache:(T3GPUImageFramebuffer *)framebuffer;
{
    [framebuffer clearAllLocks];
    
//    dispatch_async(framebufferCacheQueue, ^{
    T3runAsynchronouslyOnVideoProcessingQueue(^{
        CGSize framebufferSize = framebuffer.size;
        LFGPUTextureOptions framebufferTextureOptions = framebuffer.textureOptions;
        NSString *lookupHash = [self hashForSize:framebufferSize textureOptions:framebufferTextureOptions onlyTexture:framebuffer.missingFramebuffer];
        NSNumber *numberOfMatchingTexturesInCache = [framebufferTypeCounts objectForKey:lookupHash];
        NSInteger numberOfMatchingTextures = [numberOfMatchingTexturesInCache integerValue];
        
        NSString *textureHash = [NSString stringWithFormat:@"%@-%ld", lookupHash, (long)numberOfMatchingTextures];
        
//        [framebufferCache setObject:framebuffer forKey:textureHash cost:round(framebufferSize.width * framebufferSize.height * 4.0)];
        [framebufferCache setObject:framebuffer forKey:textureHash];
        [framebufferTypeCounts setObject:[NSNumber numberWithInteger:(numberOfMatchingTextures + 1)] forKey:lookupHash];
    });
}

- (void)purgeAllUnassignedFramebuffers;
{
    T3runAsynchronouslyOnVideoProcessingQueue(^{
//    dispatch_async(framebufferCacheQueue, ^{
        [framebufferCache removeAllObjects];
        [framebufferTypeCounts removeAllObjects];
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
        CVOpenGLESTextureCacheFlush([[T3GPUImageContext sharedImageProcessingContext] coreVideoTextureCache], 0);
#else
#endif
    });
}

- (void)addFramebufferToActiveImageCaptureList:(T3GPUImageFramebuffer *)framebuffer;
{
    T3runAsynchronouslyOnVideoProcessingQueue(^{
//    dispatch_async(framebufferCacheQueue, ^{
        [activeImageCaptureList addObject:framebuffer];
    });
}

- (void)removeFramebufferFromActiveImageCaptureList:(T3GPUImageFramebuffer *)framebuffer;
{
    T3runAsynchronouslyOnVideoProcessingQueue(^{
//  dispatch_async(framebufferCacheQueue, ^{
        [activeImageCaptureList removeObject:framebuffer];
    });
}

@end
