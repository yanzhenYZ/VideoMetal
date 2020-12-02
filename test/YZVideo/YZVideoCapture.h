//
//  YZVideoCapture.h
//  test
//
//  Created by Work on 2019/8/29.
//  Copyright © 2019 yanzhen. All rights reserved.
//

#import "YZImageOutput.h"
#import <AVFoundation/AVFoundation.h>
#import "YZProgram.h"

@class YZVideoCapture;

@protocol YZVideoCaptureDelegate <NSObject>

- (void)capture:(YZVideoCapture *)capture buffer:(CVPixelBufferRef)pixerBuffer;

@end

@interface YZVideoCapture : YZImageOutput
@property (nonatomic, weak) id<YZVideoCaptureDelegate> delegate;
@property (nonatomic) UIInterfaceOrientation outputImageOrientation;
@property (nonatomic) BOOL horizontallyMirrorFrontFacingCamera;
@property (nonatomic) BOOL horizontallyMirrorRearFacingCamera;
@property (nonatomic) BOOL runBenchmark;

- (void)startCapture;
@end
