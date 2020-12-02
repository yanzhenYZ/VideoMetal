//
//  YZHelper.m
//  test
//
//  Created by Work on 2019/8/29.
//  Copyright © 2019 yanzhen. All rights reserved.
//

#import "YZHelper.h"

@implementation YZHelper
+ (const GLfloat *)textureCoordinatesForRotation:(YZGPUImageRotationMode)rotationMode
{
    static const GLfloat noRotationTextureCoordinates[] = {
        0.0f, 0.0f,
        1.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 1.0f,
    };
    
    static const GLfloat rotateLeftTextureCoordinates[] = {
        1.0f, 0.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        0.0f, 1.0f,
    };
    
    static const GLfloat rotateRightTextureCoordinates[] = {
        0.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 1.0f,
        1.0f, 0.0f,
    };
    
    static const GLfloat verticalFlipTextureCoordinates[] = {
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f,  0.0f,
        1.0f,  0.0f,
    };
    
    static const GLfloat horizontalFlipTextureCoordinates[] = {
        1.0f, 0.0f,
        0.0f, 0.0f,
        1.0f,  1.0f,
        0.0f,  1.0f,
    };
    
    static const GLfloat rotateRightVerticalFlipTextureCoordinates[] = {
        0.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 0.0f,
        1.0f, 1.0f,
    };
    
    static const GLfloat rotateRightHorizontalFlipTextureCoordinates[] = {
        1.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 1.0f,
        0.0f, 0.0f,
    };
    
    static const GLfloat rotate180TextureCoordinates[] = {
        1.0f, 1.0f,
        0.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 0.0f,
    };
    
    switch(rotationMode)
    {
        case kYZGPUImageNoRotation: return noRotationTextureCoordinates;
        case kYZGPUImageRotateLeft: return rotateLeftTextureCoordinates;
        case kYZGPUImageRotateRight: return rotateRightTextureCoordinates;
        case kYZGPUImageFlipVertical: return verticalFlipTextureCoordinates;
        case kYZGPUImageFlipHorizonal: return horizontalFlipTextureCoordinates;
        case kYZGPUImageRotateRightFlipVertical: return rotateRightVerticalFlipTextureCoordinates;
        case kYZGPUImageRotateRightFlipHorizontal: return rotateRightHorizontalFlipTextureCoordinates;
        case kYZGPUImageRotate180: return rotate180TextureCoordinates;
    }
}

@end
