//
//  MetalPlayer.h
//  VideoCodecDemo
//
//  Created by 李贺 on 2020/6/18.
//  Copyright © 2020 李贺. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <CoreVideo/CoreVideo.h>

@interface MetalPlayer : CAMetalLayer

- (void)adjustSize:(CGSize)size;

- (void)inputPixelBuffer:(CVPixelBufferRef)pixelBuffer;

- (instancetype)initWithFrame:(CGRect)frame;

@end
