#import "T3GPUImageOutput.h"

@interface T3GPUImageUIElement : T3GPUImageOutput

// Initialization and teardown
- (id)initWithView:(UIView *)inputView;
- (id)initWithLayer:(CALayer *)inputLayer;

// Layer management
- (CGSize)layerSizeInPixels;
- (void)update;
- (void)updateUsingCurrentTime;
- (void)updateWithTimestamp:(CMTime)frameTime;

@end
