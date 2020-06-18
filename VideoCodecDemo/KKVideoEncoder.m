//
//  KKVideoEncoder.m
//  VideoCodecDemo
//
//  Created by 李贺 on 2020/6/18.
//  Copyright © 2020 李贺. All rights reserved.
//

#import "KKVideoEncoder.h"

@implementation KKVideoEncoderParam

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.profileLevel = KKVideoEncoderProfileLevelBP;
        self.encodeType = kCMVideoCodecType_H264;
        self.bitRate = 1024 * 1024;
        self.frameRate = 15;
        self.maxKeyFrameInterval = 240;
        self.allowFrameReordering = NO;
    }
    return self;
}

@end

@interface KKVideoEncoder()
@property (assign, nonatomic) VTCompressionSessionRef compressionSessionRef;
@property (nonatomic, strong) dispatch_queue_t operationQueue;
@end

@implementation KKVideoEncoder

- (void)dealloc
{
    NSLog(@"%s", __func__);
    if (NULL == _compressionSessionRef)
    {
        return;
    }
    VTCompressionSessionCompleteFrames(_compressionSessionRef, kCMTimeInvalid);
    VTCompressionSessionInvalidate(_compressionSessionRef);
    CFRelease(_compressionSessionRef);
    _compressionSessionRef = NULL;
}

/**
 初始化方法

 @param param 编码参数
 @return 实例
 */
- (instancetype)initWithParam:(KKVideoEncoderParam *)param
{
    if (self = [super init])
    {
        self.videoEncodeParam = param;

        // 创建硬编码器
        OSStatus status = VTCompressionSessionCreate(NULL, (int)self.videoEncodeParam.encodeWidth, (int)self.videoEncodeParam.encodeHeight, self.videoEncodeParam.encodeType, NULL, NULL, NULL, encodeOutputDataCallback, (__bridge void *)(self), &_compressionSessionRef);
        if (noErr != status)
        {
            NSLog(@"VideoEncoder::VTCompressionSessionCreate:failed status:%d", (int)status);
            return nil;
        }
        if (NULL == self.compressionSessionRef)
        {
            NSLog(@"VideoEncoder::调用顺序错误");
            return nil;
        }

        // 设置码率 平均码率
        if (![self adjustBitRate:self.videoEncodeParam.bitRate])
        {
            return nil;
        }

        // ProfileLevel，h264的协议等级，不同的清晰度使用不同的ProfileLevel。
        CFStringRef profileRef = kVTProfileLevel_H264_Baseline_AutoLevel;
        switch (self.videoEncodeParam.profileLevel)
        {
            case KKVideoEncoderProfileLevelBP:
                profileRef = kVTProfileLevel_H264_Baseline_3_1;
                break;
            case KKVideoEncoderProfileLevelMP:
                profileRef = kVTProfileLevel_H264_Main_3_1;
                break;
            case KKVideoEncoderProfileLevelHP:
                profileRef = kVTProfileLevel_H264_High_3_1;
                break;
        }
        status = VTSessionSetProperty(_compressionSessionRef, kVTCompressionPropertyKey_ProfileLevel, profileRef);
        CFRelease(profileRef);
        if (noErr != status)
        {
            NSLog(@"VideoEncoder::kVTCompressionPropertyKey_ProfileLevel failed status:%d", (int)status);
            return nil;
        }

        // 设置实时编码输出（避免延迟）
        status = VTSessionSetProperty(_compressionSessionRef, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);
        if (noErr != status)
        {
            NSLog(@"VideoEncoder::kVTCompressionPropertyKey_RealTime failed status:%d", (int)status);
            return nil;
        }

        // 配置是否产生B帧
        status = VTSessionSetProperty(_compressionSessionRef, kVTCompressionPropertyKey_AllowFrameReordering, self.videoEncodeParam.allowFrameReordering ? kCFBooleanTrue : kCFBooleanFalse);
        if (noErr != status)
        {
            NSLog(@"VideoEncoder::kVTCompressionPropertyKey_AllowFrameReordering failed status:%d", (int)status);
            return nil;
        }

        // 配置I帧间隔
        
        // 配置关键帧 I 帧 数据流间隔
        status = VTSessionSetProperty(_compressionSessionRef,
                                      kVTCompressionPropertyKey_MaxKeyFrameInterval, (__bridge CFTypeRef)@(self.videoEncodeParam.frameRate * self.videoEncodeParam.maxKeyFrameInterval));
        if (noErr != status)
        {
            NSLog(@"VideoEncoder::kVTCompressionPropertyKey_MaxKeyFrameInterval failed status:%d", (int)status);
            return nil;
        }
        // 配置关键帧 I帧 时间间隔
        status = VTSessionSetProperty(_compressionSessionRef,
                                      kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration,
                                      (__bridge CFTypeRef)@(self.videoEncodeParam.maxKeyFrameInterval));
        if (noErr != status)
        {
            NSLog(@"VideoEncoder::kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration failed status:%d", (int)status);
            return nil;
        }

        // 编码器准备编码
        status = VTCompressionSessionPrepareToEncodeFrames(_compressionSessionRef);

        if (noErr != status)
        {
            NSLog(@"VideoEncoder::VTCompressionSessionPrepareToEncodeFrames failed status:%d", (int)status);
            return nil;
        }
    }
    return self;
}

/**
 开始编码

 @return 结果
 */
- (BOOL)startVideoEncode
{
    if (NULL == self.compressionSessionRef)
    {
        NSLog(@"VideoEncoder::调用顺序错误");
        return NO;
    }
   
    // 编码器准备编码
    OSStatus status = VTCompressionSessionPrepareToEncodeFrames(_compressionSessionRef);
    if (noErr != status)
    {
        NSLog(@"VideoEncoder::VTCompressionSessionPrepareToEncodeFrames failed status:%d", (int)status);
        return NO;
    }
    return YES;
}

/**
 停止编码

 @return 结果
 */
- (BOOL)stopVideoEncode
{
    if (NULL == _compressionSessionRef)
    {
        return NO;
    }
    
    OSStatus status = VTCompressionSessionCompleteFrames(_compressionSessionRef, kCMTimeInvalid);
    
    if (noErr != status)
    {
        NSLog(@"VideoEncoder::VTCompressionSessionCompleteFrames failed! status:%d", (int)status);
        return NO;
    }
    return YES;
}

/**
 编码过程中调整码率

 @param bitRate 码率
 @return 结果
 */
- (BOOL)adjustBitRate:(NSInteger)bitRate
{
    if (bitRate <= 0)
    {
        NSLog(@"VideoEncoder::adjustBitRate failed! bitRate <= 0");
        return NO;
    }
    OSStatus status = VTSessionSetProperty(_compressionSessionRef, kVTCompressionPropertyKey_AverageBitRate, (__bridge CFTypeRef)@(bitRate));
    if (noErr != status)
    {
        NSLog(@"VideoEncoder::kVTCompressionPropertyKey_AverageBitRate failed status:%d", (int)status);
        return NO;
    }
    
    // 参考webRTC 限制最大码率不超过平均码率的1.5倍
    int64_t dataLimitBytesPerSecondValue =
    bitRate * 1.5 / 8;
    CFNumberRef bytesPerSecond = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt64Type, &dataLimitBytesPerSecondValue);
    int64_t oneSecondValue = 1;
    CFNumberRef oneSecond = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt64Type, &oneSecondValue);
    const void* nums[2] = {bytesPerSecond, oneSecond};
    CFArrayRef dataRateLimits = CFArrayCreate(NULL, nums, 2, &kCFTypeArrayCallBacks);
    status = VTSessionSetProperty( _compressionSessionRef, kVTCompressionPropertyKey_DataRateLimits, dataRateLimits);
    if (noErr != status)
    {
        NSLog(@"VideoEncoder::kVTCompressionPropertyKey_DataRateLimits failed status:%d", (int)status);
        return NO;
    }
    return YES;
}

/**
 输入待编码数据

 @param sampleBuffer 待编码数据
 @param forceKeyFrame 是否强制I帧
 @return 结果
 */
- (BOOL)videoEncodeInputData:(CMSampleBufferRef)sampleBuffer forceKeyFrame:(BOOL)forceKeyFrame
{
    if (NULL == _compressionSessionRef)
    {
        return NO;
    }
    
    if (nil == sampleBuffer)
    {
        return NO;
    }
    
    CVImageBufferRef pixelBuffer = (CVImageBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
    
    NSDictionary *frameProperties = @{(__bridge NSString *)kVTEncodeFrameOptionKey_ForceKeyFrame: @(forceKeyFrame)};
    
    OSStatus status = VTCompressionSessionEncodeFrame(_compressionSessionRef, pixelBuffer, kCMTimeInvalid, kCMTimeInvalid, (__bridge CFDictionaryRef)frameProperties, sampleBuffer, NULL);
    if (noErr != status)
    {
        NSLog(@"VideoEncoder::VTCompressionSessionEncodeFrame failed! status:%d", (int)status);
        return NO;
    }
    return YES;
}


/// 编码后的回调函数
/// @param outputCallbackRefCon 一般就是self  ,一般在传入函数指针的地方,也会将self传入
/// @param sourceFrameRefCon 原始的编码钱的帧的引用,VTCompressionSessionEncodeFrame的sourceFrameRefCon
/// @param status 回调状态
/// @param infoFlags asynchronous, 指示是异步编码, frameDropped,如果帧被丢弃了就是这个值
/// @param sampleBuffer 编码后的数据
void encodeOutputDataCallback(void * CM_NULLABLE outputCallbackRefCon, void * CM_NULLABLE sourceFrameRefCon, OSStatus status, VTEncodeInfoFlags infoFlags, CM_NULLABLE CMSampleBufferRef sampleBuffer)
{
    if (noErr != status || nil == sampleBuffer)
    {
        NSLog(@"VideoEncoder::encodeOutputCallback Error : %d!", (int)status);
        return;
    }
    
    if (nil == outputCallbackRefCon)
    {
        return;
    }
    
    if (!CMSampleBufferDataIsReady(sampleBuffer))
    {
        return;
    }
    // 帧被丢弃了,所以应该return
    if (infoFlags & kVTEncodeInfo_FrameDropped)
    {
        NSLog(@"VideoEncoder::H264 encode dropped frame.");
        return;
    }
    
    KKVideoEncoder *encoder = (__bridge KKVideoEncoder *)outputCallbackRefCon;
    const char header[] = "\x00\x00\x00\x01"; //h264 头,4字节
    size_t headerLen = (sizeof header) - 1;// c 字符串最后默认有\0
    NSData *headerData = [NSData dataWithBytes:header length:headerLen];
    
    // 判断是否是关键帧
    
    // CMSampleBufferGetSampleAttachmentsArray, 返回一个CMSampleBuffer 样本附件的数组, CMSampleBuffer中每个样本附件一个字典
    CFArrayRef arrRef = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true);
    CFDictionaryRef dicRef = (CFDictionaryRef)CFArrayGetValueAtIndex(arrRef, 0);
    // kCMSampleAttachmentKey_NotSync, 非同步,异步 再取反,就是同步帧,也就是关键帧
    bool isKeyFrame = !CFDictionaryContainsKey(dicRef, (const void *)kCMSampleAttachmentKey_NotSync);
    
    if (isKeyFrame)
    {
        NSLog(@"VideoEncoder::编码了一个关键帧");
        CMFormatDescriptionRef formatDescriptionRef = CMSampleBufferGetFormatDescription(sampleBuffer);
        
        // 关键帧需要加上SPS
        size_t sParameterSetSize, sParameterSetCount;
        const uint8_t *sParameterSet;
        OSStatus spsStatus = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(formatDescriptionRef, 0, &sParameterSet, &sParameterSetSize, &sParameterSetCount, 0);
        // 关键帧需要加上PPS信息
        size_t pParameterSetSize, pParameterSetCount;
        const uint8_t *pParameterSet;
        OSStatus ppsStatus = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(formatDescriptionRef, 1, &pParameterSet, &pParameterSetSize, &pParameterSetCount, 0);
        
        if (noErr == spsStatus && noErr == ppsStatus)
        {
            NSData *sps = [NSData dataWithBytes:sParameterSet length:sParameterSetSize];
            NSData *pps = [NSData dataWithBytes:pParameterSet length:pParameterSetSize];
            NSMutableData *spsData = [NSMutableData data];
            [spsData appendData:headerData];
            [spsData appendData:sps];
            // 先回调出去一个 spsData
            if ([encoder.delegate respondsToSelector:@selector(videoEncodeOutputDataCallback:isKeyFrame:)])
            {
                [encoder.delegate videoEncodeOutputDataCallback:spsData isKeyFrame:isKeyFrame];
            }
            
            NSMutableData *ppsData = [NSMutableData data];
            [ppsData appendData:headerData];
            [ppsData appendData:pps];
            // 再回调出一个ppsData
            if ([encoder.delegate respondsToSelector:@selector(videoEncodeOutputDataCallback:isKeyFrame:)])
            {
                [encoder.delegate videoEncodeOutputDataCallback:ppsData isKeyFrame:isKeyFrame];
            }
        }
    }
    
    // 每次编码出来的是一个数据块
    CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    size_t length, totalLength;
    char *dataPointer;
    status = CMBlockBufferGetDataPointer(blockBuffer, 0, &length, &totalLength, &dataPointer);
    if (noErr != status)
    {
        NSLog(@"VideoEncoder::CMBlockBufferGetDataPointer Error : %d!", (int)status);
        return;
    }
    // 下面的操作是将这个块切成流
    // 这是是AVCC格式的H264, NAL开始的固定4
    size_t bufferOffset = 0;
    static const int avcHeaderLength = 4;
    while (bufferOffset < totalLength - avcHeaderLength)
    {
        // 读取 NAL 单元长度
        uint32_t nalUnitLength = 0;
        memcpy(&nalUnitLength, dataPointer + bufferOffset, avcHeaderLength);
        
        // 大端转小端, 大小为大,数据的大字节,保存在内存的低地址中, iOS中的内存模式是小端模式,低地址保存数据的低字节,高地址保存数据的高字节
        // NAL的长度就存储在了 nalUnitLength中
        nalUnitLength = CFSwapInt32BigToHost(nalUnitLength);
        // 帧数据
        NSData *frameData = [[NSData alloc] initWithBytes:(dataPointer + bufferOffset + avcHeaderLength) length:nalUnitLength];
        
        NSMutableData *outputFrameData = [NSMutableData data];
        [outputFrameData appendData:headerData];
        [outputFrameData appendData:frameData];
        // 下个数据指针的起始地址  += 4 + NAL的长度
        bufferOffset += avcHeaderLength + nalUnitLength;
        
        if ([encoder.delegate respondsToSelector:@selector(videoEncodeOutputDataCallback:isKeyFrame:)])
        {
            [encoder.delegate videoEncodeOutputDataCallback:outputFrameData isKeyFrame:isKeyFrame];
        }
    }
    
}

@end
