//
//  MetalHelper.m
//  test
//
//  Created by 闫振 on 2020/12/2.
//  Copyright © 2020 yanzhen. All rights reserved.
//

#import "MetalHelper.h"

//BT.601, which is the standard for SDTV.
static matrix_float3x3 kYZColorConversion601DefaultMatrix = (matrix_float3x3){
   (simd_float3){1.164,  1.164, 1.164},
   (simd_float3){0.0, -0.392, 2.017},
   (simd_float3){1.596, -0.813,   0.0},
};

// BT.601 full range
static matrix_float3x3 kYZColorConversion601FullRangeMatrix = (matrix_float3x3){
   (simd_float3){1.0,    1.0,    1.0},
   (simd_float3){0.0,    -0.343, 1.765},
   (simd_float3){1.4,    -0.711, 0.0},
};

// BT.709, which is the standard for HDTV.
static matrix_float3x3 kYZColorConversion709DefaultMatrix = (matrix_float3x3){
   (simd_float3){1.164,  1.164, 1.164},
   (simd_float3){0.0, -0.213, 2.112},
   (simd_float3){1.793, -0.533,   0.0},
};

@implementation MetalHelper

+ (matrix_float3x3)getDefaultFloat3x3Matrix {
    return kYZColorConversion601FullRangeMatrix;//kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
}

+ (matrix_float3x3)getFloat3x3Matrix:(CVPixelBufferRef)pixelBuffer {
    OSType type = CVPixelBufferGetPixelFormatType(pixelBuffer);
    BOOL fullYUVRange = NO;
    if (type == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) {
        fullYUVRange = YES;
    }
    CFTypeRef colorAttachments = CVBufferGetAttachment(pixelBuffer, kCVImageBufferYCbCrMatrixKey, NULL);
    if (colorAttachments != NULL) {
        if(CFStringCompare(colorAttachments, kCVImageBufferYCbCrMatrix_ITU_R_601_4, 0) != kCFCompareEqualTo) {
            return kYZColorConversion709DefaultMatrix; //kT3ColorConversion709;
        }
    }
    if (fullYUVRange) {
        return kYZColorConversion601FullRangeMatrix;
    } else {
        return kYZColorConversion601DefaultMatrix;
    }
}
@end
