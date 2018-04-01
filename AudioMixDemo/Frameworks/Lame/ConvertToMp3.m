//
//  ConvertToMp3.m
//  RecorderDemo
//
//  Created by 五月 on 2018/3/28.
//  Copyright © 2018年 xuxiwen. All rights reserved.
//

#import "ConvertToMp3.h"
#import <lame/lame.h>
#import <AVFoundation/AVFoundation.h>
@implementation ConvertToMp3
+ (void)conventToMp3WithCafFilePath:(NSString *)cafFilePath
                        mp3FilePath:(NSString *)mp3FilePath
                         sampleRate:(int)sampleRate
                           callback:(void(^)(BOOL result))callback
{

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        @try {
            int read, write;
            FILE *pcm = fopen([cafFilePath cStringUsingEncoding:1], "rb");  //source 被转换的音频文件位置
            fseek(pcm, 4*1024, SEEK_CUR);                                   //skip file header
            FILE *mp3 = fopen([mp3FilePath cStringUsingEncoding:1], "wb");  //output 输出生成的Mp3文件位置

            const int PCM_SIZE = 8192;
            const int MP3_SIZE = 8192;
            short int pcm_buffer[PCM_SIZE*2];
            unsigned char mp3_buffer[MP3_SIZE];
            lame_t lame = lame_init();

            lame_set_in_samplerate(lame, sampleRate);
            lame_set_VBR(lame, vbr_default);
            lame_set_num_channels(lame,2);//默认为2双通道
            lame_set_brate(lame,8);
            lame_set_mode(lame,3);
            lame_set_quality(lame,2); /* 2=high 5 = medium 7=low 音质*/
            lame_init_params(lame);

            do {

                read = (int)fread(pcm_buffer, 2*sizeof(short int), PCM_SIZE, pcm);
                if (read == 0) {
                    write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);

                } else {
                    write = lame_encode_buffer_interleaved(lame, pcm_buffer, read, mp3_buffer, MP3_SIZE);
                }

                fwrite(mp3_buffer, write, 1, mp3);

            } while (read != 0);

            lame_mp3_tags_fid(lame, mp3);

            lame_close(lame);
            fclose(mp3);
            fclose(pcm);
        }
        @catch (NSException *exception) {
            NSLog(@"%@",[exception description]);
            if (callback) {
                callback(NO);
            }
        }
        @finally {
            NSLog(@"-----\n  MP3生成成功: %@   -----  \n", mp3FilePath);
            if (callback) {
                callback(YES);
            }
        }
    });
}
+(void)transformToCafWithPath:(NSString*)path :(NSString*)desPath complete:(void (^)(BOOL, NSString *))complete {

    NSString * fileName = [NSString stringWithFormat:@"%ld111.caf", (long)[[NSDate date] timeIntervalSince1970]];
    //    NSString * path1 = [[[KVTool sharedTool] getMediaPath] stringByAppendingPathComponent:fileName];
    NSString *path1 = desPath;
    NSLog(@"%@",path);

    NSString * filePath = [NSString stringWithFormat:@"file://%@", path];
    AVURLAsset * asset = [AVURLAsset URLAssetWithURL:[NSURL URLWithString:filePath] options:nil];
    AVAssetReader * reader = [AVAssetReader assetReaderWithAsset:asset error:nil];

    AVAssetReaderOutput * output = [AVAssetReaderAudioMixOutput assetReaderAudioMixOutputWithAudioTracks:asset.tracks audioSettings:nil];

    [reader addOutput:output];

    AVAssetWriter * writer = [AVAssetWriter assetWriterWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"file://%@", path1]] fileType:AVFileTypeCoreAudioFormat error:nil];

    AudioChannelLayout layout;
    memset(&layout, 0, sizeof(AudioChannelLayout));
    layout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;

    NSDictionary * setting = @{AVFormatIDKey : [NSNumber numberWithInt:kAudioFormatLinearPCM],
                               AVSampleRateKey : @(16000),
                               AVNumberOfChannelsKey : @2,
                               AVChannelLayoutKey : [NSData dataWithBytes:&layout length:sizeof(AudioChannelLayout)],
                               AVLinearPCMBitDepthKey : @(16),
                               AVLinearPCMIsNonInterleaved : [NSNumber numberWithBool:NO],
                               AVLinearPCMIsFloatKey : [NSNumber numberWithBool:NO],
                               AVLinearPCMIsBigEndianKey : [NSNumber numberWithBool:NO]};

    AVAssetWriterInput * input = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:setting];
    [writer addInput:input];

    input.expectsMediaDataInRealTime = YES;

    [writer startWriting];
    [reader startReading];

    AVAssetTrack * track = [asset.tracks objectAtIndex:0];
    CMTime startTime = CMTimeMake(0, track.naturalTimeScale);
    [writer startSessionAtSourceTime:startTime];

    __block UInt64 convertedByteCount = 0;
    dispatch_queue_t mediaInputQueue = dispatch_queue_create("mediaInputQueue", NULL);
    [input requestMediaDataWhenReadyOnQueue:mediaInputQueue usingBlock:^{
        while (input.readyForMoreMediaData) {
            CMSampleBufferRef nextBuffer = [output copyNextSampleBuffer];
            if (nextBuffer) {
                [input appendSampleBuffer: nextBuffer];
                convertedByteCount += CMSampleBufferGetTotalSampleSize (nextBuffer);
            } else {
                [input markAsFinished];
                [writer finishWritingWithCompletionHandler:^{
                }];
                [reader cancelReading];

                //转mp3
                //                NSString * fileName1 = [NSString stringWithFormat:@"%ld222.mp3", (long)[[NSDate date] timeIntervalSince1970]];
                //                NSString * path2 = [[[KVTool sharedTool] getMediaPath] stringByAppendingPathComponent:fileName1];

                //                [KVTool transformToMP3WithResoursePath:path1 target:path2];

                dispatch_async(dispatch_get_main_queue(), ^{
                    if (complete) {
                        complete(YES, path1);
                    }
                });

                break;
            }
        }
    }];
}

@end
