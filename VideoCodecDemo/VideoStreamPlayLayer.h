//
//  VideoStreamPlayLayer.h
//  VideoCodecDemo
//
//  Created by 李贺 on 2020/6/18.
//  Copyright © 2020 李贺. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <CoreVideo/CoreVideo.h>

@interface VideoStreamPlayLayer : CAEAGLLayer

/** 根据frame初始化播放器 */
- (id)initWithFrame:(CGRect)frame;

- (void)inputPixelBuffer:(CVPixelBufferRef)pixelBuffer;


@end
