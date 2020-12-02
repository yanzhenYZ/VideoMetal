#import "T3GPUImageTwoInputFilter.h"

@interface T3GPUImageAlphaBlendFilter : T3GPUImageTwoInputFilter
{
    GLint mixUniform;
}

// Mix ranges from 0.0 (only image 1) to 1.0 (only image 2), with 1.0 as the normal level
@property(readwrite, nonatomic) CGFloat mix; 

@end
