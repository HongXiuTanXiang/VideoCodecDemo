//
//  KKCaptureParams.h
//  VideoCodecDemo
//
//  Created by 李贺 on 2020/6/17.
//  Copyright © 2020 李贺. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KKCaptureParams : NSObject

/** 摄像头位置，默认为前置摄像头AVCaptureDevicePositionFront */
@property (nonatomic, assign) AVCaptureDevicePosition devicePosition;
/** 视频分辨率 默认AVCaptureSessionPreset1280x720 */
@property (nonatomic, assign) AVCaptureSessionPreset sessionPreset;
/** 帧率 单位为 帧/秒, 默认为15帧/秒 */
@property (nonatomic, assign) NSInteger frameRate;
/** 摄像头方向 默认为当前手机屏幕方向 */
@property (nonatomic, assign) AVCaptureVideoOrientation videoOrientation;

@end

NS_ASSUME_NONNULL_END
