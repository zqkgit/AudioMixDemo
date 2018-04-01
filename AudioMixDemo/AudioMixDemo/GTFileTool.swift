//
//  GTFileTool.swift
//  GTDownload
//
//  Created by 五月 on 2018/3/2.
//  Copyright © 2018年 孙凯峰. All rights reserved.
//

import UIKit
import AVFoundation

class GTFileTool: NSObject {


  static func cachePath()->String{
    
        let arr = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        return arr.first!
    }

static func fileExists(filePath:String)->Bool{
    if filePath.count == 0 {
        return false
    }
    return FileManager.default.fileExists(atPath: filePath)
}

    static   func getMp3Name(_ filePath:String) -> String? {

        let fileUrl = URL.init(fileURLWithPath: filePath)
        let avUrlAsset = AVURLAsset.init(url: fileUrl, options: nil)
        for format in avUrlAsset.availableMetadataFormats {
            for metadata in avUrlAsset.metadata(forFormat: format) {
                if (metadata.commonKey != nil) {
                    if metadata.commonKey!.rawValue  == "title" {
                        guard let mp3Str = metadata.value as? String else {
                            return nil
                        }

                        return mp3Str


                    }
                }
            }
        }
        return nil


    }
static func fileSize(filePath:String)->Int{
    if !fileExists(filePath: filePath) {
        return 0
    }

    do {
        let fileInfo = try FileManager.default.attributesOfItem(atPath: filePath)
        return fileInfo[FileAttributeKey.size] as! Int
    } catch {
        dump(error)
        return 0
    }
}

static func moveFile(fromPath:String, toPath:String){

    if fileSize(filePath: fromPath) <= 0 {
        return
    }

    do {
        try FileManager.default.moveItem(atPath: fromPath, toPath: toPath)
    } catch {
        dump(error)
    }
}

static func removFile(filePath:String){
    do {
        try FileManager.default.removeItem(atPath: filePath)
    } catch {
        dump(error)
    }
}

}


