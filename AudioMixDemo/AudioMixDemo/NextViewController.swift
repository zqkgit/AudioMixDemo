//
//  NextViewController.swift
//  AudioMixDemo
//
//  Created by 五月 on 2018/4/2.
//  Copyright © 2018年 Kent. All rights reserved.
//

import UIKit

class NextViewController: UIViewController {
    var mixAudioUrl:String = ""
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white

        let button = UIButton.init(type: .custom)
        button.backgroundColor = .grey2
        button.setTitle("获取转换的Mp3", for: .normal)

        button.titleLabel?.font = UIFont.systemFont(ofSize: 18)

        button.titleLabel?.textColor = .red

        self.view.addSubview(button)
        button.addTarget(self, action: #selector(buttonClick), for: .touchUpInside)
        button.snp.makeConstraints { (make) in
            make.top.equalTo(100)
            make.size.equalTo(CGSize(width: 30, height: 300))
            make.centerX.equalToSuperview()
        }

        // Do any additional setup after loading the view.
    }

    @objc  func buttonClick()  {
        let path = "\(GTFileTool.cachePath())/transformM4a-----\(GTRecordTool.getCurrentTimeString()).caf"
        GTRecordTool.transformToCaf(withPath: self.mixAudioUrl, to: path, complete: { (isFinish, path) in
            if isFinish{
                guard let path = path else {return}
                let mp3Path = "\(GTFileTool.cachePath())/transformCaf-----\(GTRecordTool.getCurrentTimeString()).mp3"
                GTRecordTool.conventToMp3(withCafFilePath: path, mp3FilePath: mp3Path, sampleRate: 16000, callback: { (isFinish) in
                    if isFinish  {
                        // 删除 本地 caf
                        GTRecordTool.deleteWithFileURL(fileUrl: URL.init(fileURLWithPath: path))
                        print("完成转换mp3 路径\(mp3Path)")
                    }
                    else {
                        print("caf 转 mp3 失败了")
                    }
                })
            }
                // 转 Caf失败
            else {
                print("转 Caf失败")
            }
        })
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */

}
