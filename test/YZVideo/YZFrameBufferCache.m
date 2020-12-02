//
//  YZFrameBufferCache.m
//  test
//
//  Created by Work on 2019/10/22.
//  Copyright © 2019 yanzhen. All rights reserved.
//

#import "YZFrameBufferCache.h"
#import "YZHelper.h"

@implementation YZFrameBufferCache

- (YZFrameBuffer *)fetchFramebufferForSize:(CGSize)framebufferSize textureOptions:(YZGPUTextureOptions)textureOptions onlyTexture:(BOOL)onlyTexture;
{
    __block YZFrameBuffer *framebufferFromCache = nil;
    YZrunSynchronouslyOnVideoProcessingQueue(^{
        NSString *lookupHash = [self hashForSize:framebufferSize textureOptions:textureOptions onlyTexture:onlyTexture];
        NSNumber *numberOfMatchingTexturesInCache = [framebufferTypeCounts objectForKey:lookupHash];
        NSInteger numberOfMatchingTextures = [numberOfMatchingTexturesInCache integerValue];

        if ([numberOfMatchingTexturesInCache integerValue] < 1)
        {
            // Nothing in the cache, create a new framebuffer to use
            framebufferFromCache = [[YZFrameBuffer alloc] initWithSize:framebufferSize textureOptions:textureOptions onlyTexture:onlyTexture];
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
                framebufferFromCache = [[YZFrameBuffer alloc] initWithSize:framebufferSize textureOptions:textureOptions onlyTexture:onlyTexture];
            }
        }
    });

    [framebufferFromCache lock];
    return framebufferFromCache;
}

- (void)returnFramebufferToCache:(YZFrameBuffer *)framebuffer;
{
    [framebuffer clearAllLocks];
    
//    dispatch_async(framebufferCacheQueue, ^{
    YZrunAsynchronouslyOnVideoProcessingQueue(^{
        CGSize framebufferSize = framebuffer.size;
        YZGPUTextureOptions framebufferTextureOptions = framebuffer.textureOptions;
        NSString *lookupHash = [self hashForSize:framebufferSize textureOptions:framebufferTextureOptions onlyTexture:framebuffer.missingFramebuffer];
        NSNumber *numberOfMatchingTexturesInCache = [framebufferTypeCounts objectForKey:lookupHash];
        NSInteger numberOfMatchingTextures = [numberOfMatchingTexturesInCache integerValue];
        
        NSString *textureHash = [NSString stringWithFormat:@"%@-%ld", lookupHash, (long)numberOfMatchingTextures];
        
        [framebufferCache setObject:framebuffer forKey:textureHash];
        [framebufferTypeCounts setObject:[NSNumber numberWithInteger:(numberOfMatchingTextures + 1)] forKey:lookupHash];
    });
}

- (NSString *)hashForSize:(CGSize)size textureOptions:(YZGPUTextureOptions)textureOptions onlyTexture:(BOOL)onlyTexture;
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

@end
