//
//  GTRecordTool.swift
//  GTRecordDemo
//
//  Created by 五月 on 2018/2/28.
//  Copyright © 2018年 孙凯峰. All rights reserved.
//

import UIKit
import AVFoundation
class GTRecordTool: NSObject {
    // 获取音频长度
  static  func getVedioLength(_ vedioUrl:URL) -> Int {
        let firstAsset = AVURLAsset(url: vedioUrl)
        let duration = Int(CMTimeGetSeconds(firstAsset.duration))
        return duration
    
    }
    // 删除音频
    static func deleteWithFileURL(fileUrl: URL) {
        // 查看文件是否存在，存在删除音频
        //     return FileManager.default.fileExists(atPath: filePath)

        if GTFileTool.fileExists(filePath: fileUrl.path){
        do {
            try FileManager.default.removeItem(at: fileUrl)
        } catch let error {
            print("删除音频\(error)")
            }

        }

    }
    //  Converted to Swift 4 by Swiftify v4.1.6632 - https://objectivec2swift.com/
    static  func addAudioFile(_ fromPath: URL, toAudioFile toPath: URL, savePath: String,complted:(() -> Void)? = nil) {
        
        
        // 1. 获取两个音频资源
        let audioAsset1 = AVURLAsset(url:fromPath)
        let audioAsset2 = AVURLAsset(url: toPath)
        // 2. 表示素材轨道
        let audioAssetTrack1: AVAssetTrack? = audioAsset1.tracks(withMediaType: .audio).first
        let audioAssetTrack2: AVAssetTrack? = audioAsset2.tracks(withMediaType: .audio).first
        // 2. 结合了媒体数据，可以看成是track(音频轨道)的集合，用来合成音视频
        let composition = AVMutableComposition()
        // 3. 用来表示一个track，包含了媒体类型、音轨标识符等信息，可以插入、删除、缩放track片段
        let audioTrack: AVMutableCompositionTrack? = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: CMPersistentTrackID(0))
        // 音频合并 - 插入音轨文件
        if let aTrack2 = audioAssetTrack2 {
            try? audioTrack?.insertTimeRange(CMTimeRangeMake(kCMTimeZero, audioAsset2.duration), of: aTrack2, at: kCMTimeZero)
        }
        if let aTrack1 = audioAssetTrack1 {
            try? audioTrack?.insertTimeRange(CMTimeRangeMake(kCMTimeZero, audioAsset1.duration), of: aTrack1, at: audioAsset2.duration)
        }
//        AVFileTypeMPEGLayer3
        // 5. 用来对一个AVAsset源对象进行转码，并导出为事先设置好的格式
        let session = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A)
        session?.outputURL = URL(fileURLWithPath: savePath)
        session?.outputFileType = .m4a
        session?.exportAsynchronously(completionHandler: {() -> Void in

            print("合并完成----\(savePath)")
            complted?()
            
        })
    }
    // 获取当前时间字符串
    static func getCurrentTimeString() -> String {
        let dateformat = DateFormatter()
        dateformat.dateFormat = "yyyyMMddHHmmssSSS"
        return dateformat.string(from: Date())
    }
     // caf 转 mp3
    static func conventToMp3(withCafFilePath cafFilePath: String?, mp3FilePath: String?, sampleRate: Int, callback: @escaping (_ result: Bool) -> Void) {
        ConvertToMp3.conventToMp3(withCafFilePath: cafFilePath, mp3FilePath: mp3FilePath, sampleRate: Int32(sampleRate)) { (isfinish) in

            callback(isfinish)


        }

    }


 // m4a 转 caf
    static func transformToCaf(withPath path: String?,to desPath:String?,complete: @escaping (_ isComplete:Bool,_ filePath: String?) -> Void) {
        ConvertToMp3.transformToCaf(withPath: path!, desPath!) { (isfinish, despath) in
            print("完成")
            complete(isfinish,desPath)
        }

    }
////        let fileName = "\(Int(Date().timeIntervalSince1970))111.caf"
////        let path1 = URL(fileURLWithPath: (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last) ?? "").appendingPathComponent(fileName).absoluteString
////        print("\(path ?? "")")
//        // 目标路径
//        guard let desPath = desPath else { return }
////        let filePath = "file://\(path ?? "")"
//        var asset: AVURLAsset? = nil
//         let aPath = URL.init(fileURLWithPath: desPath)
//        asset = AVURLAsset(url: aPath, options: nil)
//        var reader: AVAssetReader? = nil
//        if let anAsset = asset {
//            reader = try? AVAssetReader(asset: anAsset)
//        }
//        var output: AVAssetReaderOutput? = nil
//        if let aTracks = asset?.tracks {
//            output = AVAssetReaderAudioMixOutput(audioTracks: aTracks, audioSettings: nil)
//        }
//        if let anOutput = output {
//            reader?.add(anOutput)
//        }
//         var writer: AVAssetWriter? = nil
//         let aPath1 = URL.init(fileURLWithPath: desPath)
//
//        if  aPath1.absoluteString != "" {
//            writer = try? AVAssetWriter(url: aPath1, fileType: .caf)
//        }
//        var layout: AudioChannelLayout!
//        memset(&layout, 0, MemoryLayout<AudioChannelLayout>.size)
//        layout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo
//        let setting = [AVFormatIDKey: kAudioFormatLinearPCM, AVSampleRateKey: 16000, AVNumberOfChannelsKey: 2, AVChannelLayoutKey: Data.init(bytes: &layout, count: MemoryLayout<AudioChannelLayout>.size), AVLinearPCMBitDepthKey: 16, AVLinearPCMIsNonInterleaved: (0), AVLinearPCMIsFloatKey: (0), AVLinearPCMIsBigEndianKey: (0)] as [String : Any]
//        let input = AVAssetWriterInput(mediaType: .audio, outputSettings: setting)
//        writer?.add(input)
//        input.expectsMediaDataInRealTime = true
//        writer?.startWriting()
//        reader?.startReading()
//        let track: AVAssetTrack? = asset?.tracks[0]
//        let startTime: CMTime = CMTimeMake(0, (track?.naturalTimeScale)!)
//        writer?.startSession(atSourceTime: startTime)
//        var convertedByteCount: UInt64 = 0
//        let mediaInputQueue = DispatchQueue(label: "mediaInputQueue")
//        input.requestMediaDataWhenReady(on: mediaInputQueue, using: {() -> Void in
//            while input.isReadyForMoreMediaData {
//                let nextBuffer = output?.copyNextSampleBuffer()
//                if nextBuffer != nil {
//                    if let aBuffer = nextBuffer {
//                        input.append(aBuffer)
//                    }
//                    convertedByteCount = convertedByteCount + UInt64(CMSampleBufferGetTotalSampleSize(nextBuffer!))
//                } else {
//                    input.markAsFinished()
//                    writer?.finishWriting(completionHandler: {() -> Void in
//                    })
//                    reader?.cancelReading()
//                    DispatchQueue.main.async {
//                        complete(true,desPath)
//                    }
//                    //转mp3
//                    //                NSString * fileName1 = [NSString stringWithFormat:@"%ld222.mp3", (long)[[NSDate date] timeIntervalSince1970]];
//                    //                NSString * path2 = [[[KVTool sharedTool] getMediaPath] stringByAppendingPathComponent:fileName1];
//                    //                [KVTool transformToMP3WithResoursePath:path1 target:path2];
////                    DispatchQueue.main.async(execute: {() -> Void in
////                        if complete {
////                            //                        complete(YES, fileName1, path2);
////                        }
////                    })
//                    break
//                }
//            }
//        })
//    }




}
