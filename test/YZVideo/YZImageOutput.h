//
//  YZImageOutput.h
//  test
//
//  Created by Work on 2019/10/22.
//  Copyright © 2019 yanzhen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YZFrameBuffer.h"
#import "YZImageInput.h"

@interface YZImageOutput : NSObject {
    YZFrameBuffer *_frameBuffer;
    
    NSMutableArray *targets, *targetTextureIndices;
    
    CGSize inputTextureSize, cachedMaximumOutputSize, forcedMaximumSize;
    
    BOOL overrideInputSize;
    
    BOOL allTargetsWantMonochromeData;
    BOOL usingNextFrameForImageCapture;
}

@property(readwrite, nonatomic) YZGPUTextureOptions outputTextureOptions;

@end

