#import <UIKit/UIKit.h>
#import "T3GPUImageContext.h"

typedef NS_ENUM(NSUInteger, T3GPUImageFillModeType) {
    kT3GPUImageFillModeStretch,                       // Stretch to fill the full view, which may distort the image outside of its normal aspect ratio
    kT3GPUImageFillModePreserveAspectRatio,           // Maintains the aspect ratio of the source image, adding bars of the specified background color
    kT3GPUImageFillModePreserveAspectRatioAndFill     // Maintains the aspect ratio of the source image, zooming in on its center to fill the view
};

@class T3GPUImageView;

@protocol T3GPUImageViewDelegate <NSObject>

- (void)firstFrameReady:(T3GPUImageView *)aT3GPUImageView size:(CGSize)size;

@end

/**
 UIView subclass to use as an endpoint for displaying GPUImage outputs
 */
@interface T3GPUImageView : UIView <T3GPUImageInput>
{
    T3GPUImageRotationMode inputRotation;
}

@property (nonatomic, weak) id<T3GPUImageViewDelegate> delegate;

/** The fill mode dictates how images are fit in the view, with the default being kT3GPUImageFillModePreserveAspectRatio
 */
@property(readwrite, nonatomic) T3GPUImageFillModeType fillMode;

/** This calculates the current display size, in pixels, taking into account Retina scaling factors
 */
@property(readonly, nonatomic) CGSize sizeInPixels;

@property(nonatomic) BOOL enabled;

@property (atomic, assign) BOOL isStoppingCapture;

/** Handling fill mode
 
 @param redComponent Red component for background color
 @param greenComponent Green component for background color
 @param blueComponent Blue component for background color
 @param alphaComponent Alpha component for background color
 */
- (void)setBackgroundColorRed:(GLfloat)redComponent green:(GLfloat)greenComponent blue:(GLfloat)blueComponent alpha:(GLfloat)alphaComponent;

- (void)setCurrentlyReceivingMonochromeInput:(BOOL)newValue;

@end
