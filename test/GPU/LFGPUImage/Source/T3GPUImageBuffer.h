#import "T3GPUImageFilter.h"

@interface T3GPUImageBuffer : T3GPUImageFilter
{
    NSMutableArray *bufferedFramebuffers;
}

@property(readwrite, nonatomic) NSUInteger bufferSize;

@end
