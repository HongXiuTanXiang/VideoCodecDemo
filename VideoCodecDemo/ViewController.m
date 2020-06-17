//
//  ViewController.m
//  VideoCodecDemo
//
//  Created by 李贺 on 2020/6/17.
//  Copyright © 2020 李贺. All rights reserved.
//

#import "ViewController.h"
#import "VideoStreamPlayLayer.h"
#import "KKVideoEncoder.h"
#import "H264Decoder.h"
#import "KKVideoCapture.h"
#import "MetalPlayer.h"
#import "KKCaptureParams.h"

#define USED_METAL

@interface ViewController () <H264DecoderDelegate, KKVideoEncoderDelegate, KKVideoCaptureSampleDelegate>

/** 视频流播放器 */
#ifdef USED_METAL
@property (nonatomic, strong) MetalPlayer *playLayer;
#else
@property (nonatomic, strong) VideoStreamPlayLayer *playLayer;
#endif
/** 解码播放视图 */
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *recordLayer;

/** H264解码器 */
@property (nonatomic, strong) H264Decoder *h264Decoder;
/** 视频采集 */
@property (nonatomic, strong) KKVideoCapture *videoCapture;
/** 视频编码器 */
@property (nonatomic, strong) KKVideoEncoder *videoEncoder;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    // 初始化视频采集参数
    KKCaptureParams *param = [[KKCaptureParams alloc] init];
    // 设置分辨率
    param.sessionPreset = AVCaptureSessionPreset1280x720;
    // 初始化采集
    self.videoCapture = [[KKVideoCapture alloc] initWithParams:param error:nil];
    self.videoCapture.delegate = self;
    
    // 初始化并开启视频编码
    KKVideoEncoderParam *encodeParam = [[KKVideoEncoderParam alloc] init];
    encodeParam.encodeWidth = 180;
    encodeParam.encodeHeight = 320;
    encodeParam.bitRate = 512 * 1024;
    self.videoEncoder = [[KKVideoEncoder alloc] initWithParam:encodeParam];
    self.videoEncoder.delegate = self;
    [self.videoEncoder startVideoEncode];
    
    // 初始化视频解码
    self.h264Decoder = [[H264Decoder alloc] init];
    self.h264Decoder.delegate = self;
    
    
    CGFloat layerMargin = 15;
    CGFloat layerW = (self.view.frame.size.width - 3 * layerMargin) * 0.5;
    CGFloat layerH = layerW * 16 / 9.00;
    CGFloat layerY = 120;
    
    // 初始化视频采集的预览画面
    self.recordLayer = self.videoCapture.previewLayer;
    self.recordLayer.frame = CGRectMake(layerMargin, layerY, layerW, layerH);

    // 初始化视频编码解码后的播放画面
#ifdef USED_METAL
    self.playLayer = [[MetalPlayer alloc] initWithFrame:CGRectMake(layerMargin * 2 + layerW, layerY, layerW, layerH)];
#else
    self.playLayer = [[VideoStreamPlayLayer alloc] initWithFrame:CGRectMake(layerMargin * 2 + layerW, layerY, layerW, layerH)];
#endif
    self.playLayer.backgroundColor = [UIColor blackColor].CGColor;
    
    CGFloat buttonW = self.view.frame.size.width * 0.4;
    CGFloat buttonH = 40;
    CGFloat buttonMargin = (self.view.frame.size.width - buttonW * 2) / 3.0;
    CGFloat buttonY = 60;
    
    UIButton *cameraButton = [[UIButton alloc] initWithFrame:CGRectMake(buttonMargin, buttonY, buttonW, buttonH)];
    [cameraButton setTitle:@"开启/关闭 摄像头" forState:UIControlStateNormal];
    [cameraButton setBackgroundColor:[UIColor lightGrayColor]];
    [cameraButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [cameraButton addTarget:self action:@selector(cameraButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:cameraButton];
    
    UIButton *revertCameraButton = [[UIButton alloc] initWithFrame:CGRectMake(buttonMargin * 2 + buttonW, buttonY, buttonW, buttonH)];
    [revertCameraButton setTitle:@"切换摄像头" forState:UIControlStateNormal];
    [revertCameraButton setBackgroundColor:[UIColor lightGrayColor]];
    [revertCameraButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [revertCameraButton addTarget:self action:@selector(revertCameraButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:revertCameraButton];
}

- (void)cameraButtonAction:(UIButton *)button
{
    button.selected = !button.selected;
    if (button.selected)
    {
        [self.videoCapture startCapture];
        [self.view.layer addSublayer:self.recordLayer];
        [self.view.layer addSublayer:self.playLayer];
    }
    else
    {
        [self.videoCapture stopCapture];
        [self.videoCapture.previewLayer removeFromSuperlayer];
        [self.playLayer removeFromSuperlayer];
    }
}

- (void)revertCameraButtonAction:(UIButton *)button
{
    [self.videoCapture reverseCamera];
}



#pragma mark - 视频采集回调
- (void)videoCaptureOutputDataCallback:(CMSampleBufferRef)sampleBuffer
{
    [self.videoEncoder videoEncodeInputData:sampleBuffer forceKeyFrame:NO];
}

#pragma mark - H264编码回调
- (void)videoEncodeOutputDataCallback:(NSData *)data isKeyFrame:(BOOL)isKeyFrame
{
    [self.h264Decoder decodeNaluData:data];
}

#pragma mark - H264解码回调
- (void)videoDecodeOutputDataCallback:(CVImageBufferRef)imageBuffer
{
    [self.playLayer inputPixelBuffer:imageBuffer];
    CVPixelBufferRelease(imageBuffer);
}
@end
