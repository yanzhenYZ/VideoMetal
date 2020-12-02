//
//  TTTHelpPlayer.h
//  TTTLive
//
//  Created by yanzhen on 2019/8/22.
//  Copyright © 2019 yanzhen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface TTTHelpPlayer : UIView
- (void)enqueueSampleBuffer:(CMSampleBufferRef)sampleBuffer;
@end


