//
//  TTTHelpPlayer.m
//  TTTLive
//
//  Created by yanzhen on 2019/8/22.
//  Copyright © 2019 yanzhen. All rights reserved.
//

#import "TTTHelpPlayer.h"

@interface TTTHelpPlayer ()
@property (nonatomic, strong) AVSampleBufferDisplayLayer *videoLayer;
@end

@implementation TTTHelpPlayer

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _videoLayer = [AVSampleBufferDisplayLayer layer];
        _videoLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        _videoLayer.backgroundColor = [UIColor blackColor].CGColor;
        _videoLayer.frame = self.bounds;
        [self.layer addSublayer:_videoLayer];
    }
    return self;
}

- (void)enqueueSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    if (UIApplicationStateActive !=[UIApplication sharedApplication].applicationState) return;
    if (CMSampleBufferDataIsReady(sampleBuffer) && CMSampleBufferIsValid(sampleBuffer)) {
        if (_videoLayer.status == AVQueuedSampleBufferRenderingStatusFailed) return;
        if (_videoLayer.isReadyForMoreMediaData) {
            [_videoLayer enqueueSampleBuffer:sampleBuffer];
        }
    }
    
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _videoLayer.frame = self.bounds;
}


@end
