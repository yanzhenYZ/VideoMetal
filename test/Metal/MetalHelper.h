//
//  MetalHelper.h
//  test
//
//  Created by 闫振 on 2020/12/2.
//  Copyright © 2020 yanzhen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>
#import <MetalKit/MetalKit.h>

@interface MetalHelper : NSObject

+ (matrix_float3x3)getDefaultFloat3x3Matrix;

+ (matrix_float3x3)getFloat3x3Matrix:(CVPixelBufferRef)pixelBuffer;

@end


