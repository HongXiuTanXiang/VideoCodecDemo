//
//  KKCaptureParams.m
//  VideoCodecDemo
//
//  Created by 李贺 on 2020/6/17.
//  Copyright © 2020 李贺. All rights reserved.
//

#import "KKCaptureParams.h"
#import <UIKit/UIKit.h>

@implementation KKCaptureParams
- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _devicePosition = AVCaptureDevicePositionFront;
        _sessionPreset = AVCaptureSessionPreset1280x720;
        _frameRate = 15;
        _videoOrientation = AVCaptureVideoOrientationPortrait;
        
        switch ([UIDevice currentDevice].orientation)
        {
            case UIDeviceOrientationPortrait:
            case UIDeviceOrientationPortraitUpsideDown:
                _videoOrientation = AVCaptureVideoOrientationPortrait;
                break;
            case UIDeviceOrientationLandscapeRight:
                _videoOrientation = AVCaptureVideoOrientationLandscapeRight;
                break;
            case UIDeviceOrientationLandscapeLeft:
                _videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
                break;
            default:
                break;
        }
    }
    return self;
}

@end
