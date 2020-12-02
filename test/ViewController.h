//
//  ViewController.h
//  test
//
//  Created by Work on 2019/8/28.
//  Copyright © 2019 yanzhen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

/*
 T3VideoCapture --
   -- T3GPUImageVideoCamera      视频采集
   -- T3GPUImageBeautyFilter     美颜
   -- T3GPUImageCropFilter       裁剪尺寸 360P需要裁剪
   -- T3GPUImageEmptyFilter
   -- T3GPUImageView             视频显示视图
   -- T3LiveVideoConfiguration   视频参数
   -- T3GPUImageAlphaBlendFilter 透明度混合滤镜
   -- T3GPUImageUIElement
   -- UIView                     水印视图的父视图
 */

/* 有美颜 -- 无水印 -- addTarget
    filter         T3GPUImageBeautyFilter --       1
    -- output         T3GPUImageEmptyFilter  --    2
       -- T3GPUImageView T3GPUImageView            3
 */






/* T3GPUImageVideoCamera
 
 Planar: 平面；BiPlanar：双平面
 平面／双平面主要应用在yuv上。uv分开存储的为Planar，反之是BiPlanar
 kCVPixelFormatType_420YpCbCr8PlanarFullRange是420p，
 kCVPixelFormatType_420YpCbCr8BiPlanarFullRange是nv12.
 

 video type: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
 filter    : T3GPUImageCropFilter 裁剪
 */
@end

