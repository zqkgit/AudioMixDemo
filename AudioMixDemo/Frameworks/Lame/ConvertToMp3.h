//
//  ConvertToMp3.h
//  RecorderDemo
//
//  Created by 五月 on 2018/3/28.
//  Copyright © 2018年 xuxiwen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ConvertToMp3 : NSObject
+ (void)conventToMp3WithCafFilePath:(NSString *)cafFilePath
                        mp3FilePath:(NSString *)mp3FilePath
                         sampleRate:(int)sampleRate
                           callback:(void(^)(BOOL result))callback;
+(void)transformToCafWithPath:(NSString*)path :(NSString*)desPath complete:(void (^)(BOOL, NSString *))complete;
@end
