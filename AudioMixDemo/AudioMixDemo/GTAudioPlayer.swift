//
//  GTAudioPlayer.swift
//  GenialTone
//
//  Created by 孙凯峰 on 2017/7/17.
//  Copyright © 2017年 Kent. All rights reserved.
//

import UIKit
import AVFoundation

enum GTAudioPlayState {
    case none
    case playing
    case pause
    case failed
    case end

}

//TODO: 添加监听 AVAudioSessionRouteChangeNotification
//http://www.jianshu.com/p/3e0a399380df  从而使得 拔出耳机时 播放动画有恢复

class GTAudioPlayer: NSObject {
    var state: GTAudioPlayState = .none
    var progress: CGFloat {
        if self.duration == 0.0 {
            return 0
        }
        return CGFloat(self.currentTime/self.duration)
    }
    var duration: TimeInterval = 0
    var totolTime: TimeInterval {
        if player == nil {
            return 0
        }
        let currTime  = CMTimeGetSeconds(player!.currentItem!.currentTime())
        if currTime.isNaN {
            return 0.0
        }
        return currTime
    }
    
    fileprivate var playCompletedBlock: (() -> Void)?
    fileprivate var playStateBlock: ((GTAudioPlayState) -> Void)?
    fileprivate var playduration: ((Int) -> Void)?
    var currentTime: TimeInterval {
        if player == nil {
            return 0
        }
        let currTime  = CMTimeGetSeconds(player!.currentItem!.currentTime())
        if currTime.isNaN {
            return 0.0
        }
        return currTime
    }

    fileprivate var player: AVPlayer?
    fileprivate var oldItem: AVPlayerItem?
    var urlStr: String?
    static let share  = GTAudioPlayer()
    override init() {}

    deinit {
        oldItem?.removeObserver(self, forKeyPath: "status")
        NotificationCenter.default.removeObserver(self)
        oldItem = nil
        player = nil
    }
    // MARK: - play
    func play(urlStr: String?, playState: ((GTAudioPlayState) -> Void)? = nil, duration: ((Int) -> Void)? = nil, completed:(() -> Void)? = nil) {
        GTAudioPlayer.share.playCompletedBlock = completed
        GTAudioPlayer.share.playStateBlock = playState
        GTAudioPlayer.share.playduration = duration
        guard let urlStr = urlStr, !urlStr.isEmpty else {
            GTAudioPlayer.share.playStateBlock?(.failed)
            return
        }
        let url: URL!
        if urlStr.hasPrefix("/") {
            url = URL(fileURLWithPath: urlStr)
        } else {
            url = URL(string: urlStr)
        }
        self.urlStr = urlStr
        let item = AVPlayerItem(url: url)
        if player == nil {
            player = AVPlayer(playerItem: item)
            player?.volume = AVAudioSession.sharedInstance().outputVolume < 0.5 ? 0.5 : AVAudioSession.sharedInstance().outputVolume
        } else {
            oldItem?.removeObserver(self, forKeyPath: "status")
            NotificationCenter.default.removeObserver(self)
            player?.replaceCurrentItem(with: item)
        }
        item.addObserver(self, forKeyPath: "status", options: .new, context: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playToEndTime(_:)), name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        oldItem = item
    }

    func pause() {
        player?.pause()
        state = .pause
        GTAudioPlayer.share.playStateBlock?(.pause)
    }

    func resume() {
        player?.play()
        state = .playing
    }
    // MARK: - stop
    func stop() {
        player?.pause()
        oldItem?.removeObserver(self, forKeyPath: "status")
        NotificationCenter.default.removeObserver(self)
        oldItem = nil
        player = nil
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {

        if keyPath == #keyPath(AVPlayerItem.status) {
            let status: AVPlayerItemStatus
            if let statusNumber = change?[.newKey] as? NSNumber {
                status = AVPlayerItemStatus(rawValue: statusNumber.intValue)!
            } else {
                status = .unknown
            }
            switch status {
            case .readyToPlay:
                guard let tmpDuration = player?.currentItem?.duration.value,
                    let tmpTimescale = player?.currentItem?.duration.timescale
                    else {
                        state = .none
                        return
                }
                let seconds = TimeInterval(tmpDuration) / TimeInterval(tmpTimescale)
                //切换扬声器播放
                do {//AVAudioSessionCategoryAmbient
                    try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategorySoloAmbient, with: AVAudioSessionCategoryOptions.defaultToSpeaker)
                } catch let error {
                    print(error)
                }

//                do {
//                    try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
//                } catch let error {
//                    print(error)
//                }

                player?.play()
                state = .playing
                GTAudioPlayer.share.playStateBlock?(.playing)
                GTAudioPlayer.share.playduration?(Int(seconds))
                duration = seconds
            case .failed:
                state = .failed
                GTAudioPlayer.share.playStateBlock?(.failed)
                stop()
            case .unknown:
                state = .failed
                GTAudioPlayer.share.playStateBlock?(.failed)
                stop()
            }
        }
    }
    // MARK: - Completed
    @objc func playToEndTime(_ notification: NSNotification) {
        guard let playItem = notification.object as? AVPlayerItem else { return }
        if playItem == oldItem {
            GTAudioPlayer.share.playCompletedBlock?()
            state = .end
            
            print("播放完成")
        }

    }
}
