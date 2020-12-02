//
//  MetalViewController.m
//  test
//
//  Created by 闫振 on 2020/12/1.
//  Copyright © 2020 yanzhen. All rights reserved.
//

#import "MetalViewController.h"
#import "WSTCaptureKit.h"
#import "MetalObj.h"

@interface MetalViewController ()<WSTCaptureKitDelegate>
@property (nonatomic, strong) CIContext *context;
@property (weak, nonatomic) IBOutlet UIImageView *player;
@property (nonatomic, strong) WSTCaptureKit *captureKit;

@property (nonatomic, strong) MetalObj *metalObj;
@end

@implementation MetalViewController
/** 
 todo
 1.0.4 读取metal文件
 1.0.5 旋转角度
 1.0.6 镜像
 1.0.7 根据帧类型设置矩阵
 
 */
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _metalObj = [[MetalObj alloc] init];
    [_metalObj setupView:self.view];
    
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self startCapture];
}

- (void)startCapture {
    _context = [CIContext contextWithOptions:nil];
    
    T3LiveVideoConfiguration *lfvideoConfig = [T3LiveVideoConfiguration new];
    lfvideoConfig.videoSize = CGSizeMake(720, 1280); //640x360  other
    lfvideoConfig.videoFrameRate = 15;
    //lfvideoConfig.videoMaxKeyframeInterval = mFps;
    lfvideoConfig.sessionPreset = LFCaptureSessionPreset720x1280;
    UIInterfaceOrientation outputOrientation = [UIApplication sharedApplication].statusBarOrientation;
    lfvideoConfig.outputImageOrientation = outputOrientation;
    lfvideoConfig.autorotate = NO;
    lfvideoConfig.devPos = AVCaptureDevicePositionFront;
    lfvideoConfig.imageFillMode = kT3GPUImageFillModePreserveAspectRatioAndFill;
    
    
    _captureKit = [[WSTCaptureKit alloc] initWithAudioConfiguration:lfvideoConfig captureType:T3LiveCaptureMaskVideo];
    _captureKit.delegate = self;
    
//    _captureKit.preView = self.player;
    
    _captureKit.beautyFace = YES;
    _captureKit.beautyLevel = 0.5;
    _captureKit.brightLevel = 0.5;
    _captureKit.videoFrameRate = 15;
    _captureKit.running = YES;
}


- (void)_captureVideoBuffer:(CVPixelBufferRef)imageBuffer {
    CVPixelBufferRetain(imageBuffer);
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:imageBuffer];
    if (ciImage == nil) {
        CVPixelBufferRelease(imageBuffer);
        return;
    }
    CGFloat imageWidth = CVPixelBufferGetWidth(imageBuffer);
    CGFloat imageHeight = CVPixelBufferGetHeight(imageBuffer);
    CGImageRef videoImage = [self.context createCGImage:ciImage fromRect:CGRectMake(0, 0, imageWidth, imageHeight)];
    if (videoImage == nil) {
        CVPixelBufferRelease(imageBuffer);
        return;
    }
    UIImage *image = [[UIImage alloc] initWithCGImage:videoImage];
    CGImageRelease(videoImage);
    CVPixelBufferRelease(imageBuffer);
    dispatch_async(dispatch_get_main_queue(), ^{
        self.player.image = image;
    });
}
#pragma mark - WSTCaptureKitDelegate
- (void)outputCaptured:(CVPixelBufferRef)pixelBuffer {
    //[self _captureVideoBuffer:pixelBuffer];
}

- (void)willOutputCaptured:(CVPixelBufferRef)pixelBuffer {
//    [self _captureVideoBuffer:pixelBuffer];
    [_metalObj displayPixelBuffer:pixelBuffer];
}
@end
