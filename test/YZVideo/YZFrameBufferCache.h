//
//  YZFrameBufferCache.h
//  test
//
//  Created by Work on 2019/10/22.
//  Copyright © 2019 yanzhen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YZFrameBuffer.h"
//#import "YZHelper.h"

@interface YZFrameBufferCache : NSObject {
    NSMutableDictionary *framebufferCache;
    NSMutableDictionary *framebufferTypeCounts;
}

- (YZFrameBuffer *)fetchFramebufferForSize:(CGSize)framebufferSize textureOptions:(YZGPUTextureOptions)textureOptions onlyTexture:(BOOL)onlyTexture;
- (void)returnFramebufferToCache:(YZFrameBuffer *)framebuffer;
@end


