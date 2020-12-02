//
//  MetalObj.h
//  test
//
//  Created by 闫振 on 2020/12/1.
//  Copyright © 2020 yanzhen. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MetalObj : NSObject

- (void)setupView:(UIView *)view;
- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer;
@end

NS_ASSUME_NONNULL_END
