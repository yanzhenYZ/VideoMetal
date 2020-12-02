//
//  YZImageOutput.m
//  test
//
//  Created by Work on 2019/10/22.
//  Copyright © 2019 yanzhen. All rights reserved.
//

#import "YZImageOutput.h"

@implementation YZImageOutput
- (instancetype)init
{
    self = [super init];
    if (self) {
        targets = [[NSMutableArray alloc] init];
        targetTextureIndices = [[NSMutableArray alloc] init];
        
//        _enabled = YES;
//        allTargetsWantMonochromeData = YES;
//        usingNextFrameForImageCapture = NO;
        
        // set default texture options
        _outputTextureOptions.minFilter = GL_LINEAR;
        _outputTextureOptions.magFilter = GL_LINEAR;
        _outputTextureOptions.wrapS = GL_CLAMP_TO_EDGE;
        _outputTextureOptions.wrapT = GL_CLAMP_TO_EDGE;
        _outputTextureOptions.internalFormat = GL_RGBA;
        _outputTextureOptions.format = GL_BGRA;
        _outputTextureOptions.type = GL_UNSIGNED_BYTE;
    }
    return self;
}


- (void)setOutputTextureOptions:(YZGPUTextureOptions)outputTextureOptions {
    _outputTextureOptions = outputTextureOptions;
    
    if(_frameBuffer.texture)
    {
        glBindTexture(GL_TEXTURE_2D,  _frameBuffer.texture);
        //_outputTextureOptions.format
        //_outputTextureOptions.internalFormat
        //_outputTextureOptions.magFilter
        //_outputTextureOptions.minFilter
        //_outputTextureOptions.type
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, _outputTextureOptions.wrapS);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, _outputTextureOptions.wrapT);
        glBindTexture(GL_TEXTURE_2D, 0);
    }
}
@end
