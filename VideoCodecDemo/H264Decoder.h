//
//  H264Decoder.h
//  VideoCodecDemo
//
//  Created by 李贺 on 2020/6/18.
//  Copyright © 2020 李贺. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>

@protocol H264DecoderDelegate <NSObject>

/** H264解码数据回调 */
- (void)videoDecodeOutputDataCallback:(CVImageBufferRef)imageBuffer;

@end


@interface H264Decoder : NSObject

/** 代理 */
@property (weak, nonatomic) id<H264DecoderDelegate> delegate;

/** 解码NALU数据 */
-(void)decodeNaluData:(NSData *)naluData;

@end
