//
//  KKVideoCapture.h
//  VideoCodecDemo
//
//  Created by 李贺 on 2020/6/17.
//  Copyright © 2020 李贺. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KKCaptureParams.h"

@protocol KKVideoCaptureSampleDelegate <NSObject>

- (void)videoCaptureOutputDataCallback:(CMSampleBufferRef)sampleBuffer;

@end

NS_ASSUME_NONNULL_BEGIN

@interface KKVideoCapture : NSObject
/// 相机数据回调代理
@property(nonatomic, weak) id <KKVideoCaptureSampleDelegate> delegate;
/// 相机参数
@property(nonatomic, strong) KKCaptureParams * params;
/// 预览层
@property(nonatomic, strong, readonly) AVCaptureVideoPreviewLayer * previewLayer;
/**初始化方法*/
-(instancetype)initWithParams:(KKCaptureParams*) params error: (NSError ** _Nullable)error;
/** 开始采集 */
- (NSError *)startCapture;

/** 停止采集 */
- (NSError *)stopCapture;

/** 抓图 block返回UIImage */
- (void)imageCapture:(void(^)(UIImage *image))completion;

/** 动态调整帧率 */
- (NSError *)adjustFrameRate:(NSInteger)frameRate;

/** 翻转摄像头 */
- (NSError *)reverseCamera;

/** 采集过程中动态修改视频分辨率 */
- (void)changeSessionPreset:(AVCaptureSessionPreset)sessionPreset;

@end

NS_ASSUME_NONNULL_END
