//
//  PublishPage.swift
//  GenialTone
//
//  Created by 五月 on 2018/3/1.
//  Copyright © 2018年 Kent. All rights reserved.
// 

import UIKit
import AVFoundation
import SnapKit

class PublishPage: UIViewController{
    var topBackGroungView:UIImageView!
    var timeBackGroundView:UIImageView!
    var recordTimeMarkLabel0:UILabel!
    var timeLabel:UILabel!
    var recordTimeMarkLabel1:UILabel!
    var addWordLabel:UILabel!
    var addMusicLabel:UILabel!
    var uploadRemarkLabel:PublishRemakrView!
    var testListenBtn:UIButton!
    var recordBrn:UIButton!
    var retryRecord:UIButton!
    var hasAddWordView:UIView!
    var retrySelectWordBtn:UILabel!
    var wordTextView:UITextView!
    var hasAddMusicView:UIView!
    var retryMusicWordBtn:UILabel!
    var puwordStr:String = ""
    var puaudioPath:String = ""
    var selectMusicSwitch:UISwitch!
    var musicLabel:UILabel!
    var testListenLabel:UILabel!
    var retryLabel:UILabel!
    var slider:UISlider!


    var audioController:AEAudioController?
    var audioUnitFile:AudioFileID!
    var loop1:AEAudioFilePlayer!
    var audioUnitPlayer:AEAudioUnitChannel!
    var group:AEChannelGroupRef!
    var recorder:AERecorder?
    var player:AEAudioFilePlayer?
    var timer:Timer?
    var totoalSeconds:Int = 0

    var vedioPath:String = ""
    var lastVedio:String = ""

    var testplayView: CircleProgressView!
    var link: CADisplayLink?
    var isTestPlay:Bool = false // 试听是否正在播放
    var recordLabel:UILabel!



    override func viewDidLoad() {
        super.viewDidLoad()
        self.setUpAudioController()

        EventBus.getDefault().subscribe(self) { [weak self](notice: SelectWordEvent) in
            self?.hasAddWord(notice.word)

        }

        EventBus.getDefault().subscribe(self) { [weak self] (notice: SelectMusicEvent) in
            self?.hasAddMusic(notice.musicUrl, audioTitle: notice.musicTitle)
        }
        // 监听耳机拔出
        NotificationCenter.default.addObserver(self, selector: #selector(earphonePullOut), name: NSNotification.Name(rawValue: EarphonePullOut), object: nil)
        self.buildView()


    }
    // MARK:- 耳机拔出
    @objc func earphonePullOut()  {

        //                do {//AVAudioSessionCategoryAmbient
        //                    try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord, with: AVAudioSessionCategoryOptions.defaultToSpeaker)
        //                } catch let error {
        //                    print(error)
        //                }

        //      切换音频输入源 为扬声器
        do {
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
        } catch let error {
            print(error)
        }

    }

    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    // MARK:- 下一步
    @IBAction func nextClick(_ sender: Any) {
        /*let session = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A)*/
        // finishRecord 完成录音后，得到的音频格式是通过 AVAssetExportSession 设置为 AVAssetExportPresetAppleM4A 的.m4a格式的，这种文件 可以通过 AVPlyer播放。但是通过 FreeStreamer或者 DOUAudioStreamer 等流媒体播放器，都会播放失败，通过测试，可以将拼接的.m4a的文件，先转为 .caf,然后在通过 lame 转为 .mp3 文件，即可正常播放，为了效率，录制暂停（调用finishRecord，其实是完成录音，再次录制会把后面录制的和上一次的拼接）时，不必转换，可以在上传前进行转换
        stopTestPlayAndPlayBackGroundVoice()

        let vc = NextViewController()
        vc.mixAudioUrl = self.lastVedio

        if (recorder != nil) {
            self.finishRecord { [weak self] in
                if (self?.totoalSeconds)! < 15 {
                    print("录音时间少于15s")
                    return
                }
                DispatchQueue.main.async {

                    self?.navigationController?.pushViewController(vc, animated: true)

                }

            }
        }
        else {

            if totoalSeconds < 15 {
                print("录音时间少于15s")
                return
            }
            DispatchQueue.main.async {
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }





    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        view.layoutIfNeeded()


    }



    func setUpAudioController() {
        audioController = AEAudioController.init(audioDescription: AEAudioStreamBasicDescriptionNonInterleavedFloatStereo, inputEnabled: true)
        audioController?.preferredBufferDuration = 0.005
        audioController?.useMeasurementMode = true
        try? audioController?.start()
        audioUnitPlayer = AEAudioUnitChannel(componentDescription: AEAudioComponentDescriptionMake(kAudioUnitManufacturer_Apple, kAudioUnitType_Generator, kAudioUnitSubType_AudioFilePlayer))
        audioController?.addChannels([audioUnitPlayer])
    }
    // MARK: - 返回上个页面
    func backButtonClicked(_ sender: UIBarButtonItem) {

        let alertController = UIAlertController(title: "提示",
                                                message: "是否放弃录音？", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        let okAction = UIAlertAction(title: "好的", style: .default, handler: {
            action in
            print("点击了确定")
            //删除本地录制的音频
            if (self.recorder != nil) {
                self.finishRecord({
                    GTRecordTool.deleteWithFileURL(fileUrl: URL.init(fileURLWithPath: self.lastVedio))
                })
            }
            else {

                GTRecordTool.deleteWithFileURL(fileUrl: URL.init(fileURLWithPath: self.lastVedio))

            }
            self.audioController = nil

            //            alertView.dismiss()
            self.navigationController?.popViewController(animated: true)

        })
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)



    }

    // MARK:- 选择歌词以后

    func hasAddWord(_ wordStr: String)  {

        addWordLabel.isHidden = true
        puwordStr = wordStr
        hasAddWordView = UIView()
        hasAddWordView.backgroundColor = .white
        hasAddWordView.layer.shadowColor = UIColor.grey2.cgColor
        hasAddWordView.layer.shadowOffset = CGSize(width: 0, height:0)
        hasAddWordView.layer.shadowRadius = 2
        hasAddWordView.layer.shadowOpacity = 0.8
        hasAddWordView.layer.cornerRadius = 10
        hasAddWordView.layer.masksToBounds = true
        view.addSubview(hasAddWordView)
        hasAddWordView.snp.makeConstraints { (make) in
            make.left.equalTo(13)
            make.right.equalTo(-13)
            make.top.equalTo(timeBackGroundView.snp.bottom).offset(20)
            make.height.equalTo(GTSize_width(160))
        }

        wordTextView = UITextView.init(frame: .zero)
        wordTextView.isEditable = false
        wordTextView.text = wordStr
        wordTextView.font = UIFont.systemFont(ofSize: 14)
        wordTextView.textColor = UIColor(red: 51.0 / 255.0, green: 51.0 / 255.0, blue: 51.0 / 255.0, alpha: 1.0)
        wordTextView.textAlignment = .center
        hasAddWordView.addSubview(wordTextView)
        wordTextView.snp.makeConstraints { (make) in
            make.top.left.equalTo(27)
            make.bottom.right.equalTo(-20)
        }
        retrySelectWordBtn = UILabel.init(frame: .zero)
        retrySelectWordBtn.text = "重新选择"
        retrySelectWordBtn.font =  UIFont.systemFont(ofSize: 12)
        retrySelectWordBtn.textAlignment = .center
        retrySelectWordBtn.isUserInteractionEnabled = true
        retrySelectWordBtn.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(addWordLabelTapped(_:))))
        retrySelectWordBtn.textColor = UIColor(red: 153.0 / 255.0, green: 153.0 / 255.0, blue: 153.0 / 255.0, alpha: 1.0)
        hasAddWordView.addSubview(retrySelectWordBtn)
        retrySelectWordBtn.snp.makeConstraints { (make) in
            make.top.equalTo(12)
            make.right.equalTo(-16)
            make.size.equalTo(CGSize(width: 60, height: 14))
        }
        uploadRemarkLabel.isHidden = true

        if puaudioPath == "" {
            addMusicLabel.snp.remakeConstraints { (make) in
                make.centerX.equalToSuperview()
                make.left.equalTo(GTSize_width(63))
                make.right.equalTo(-GTSize_width(63))
                make.height.equalTo(40)
                make.top.equalTo(hasAddWordView.snp.bottom).offset(GTSize_width(41))

            }
        }  else {

            hasAddMusicView.snp.remakeConstraints { (make) in
                make.left.equalTo(13)
                make.right.equalTo(-13)
                make.top.equalTo(hasAddWordView.snp.bottom).offset(11)
                make.height.equalTo(GTSize_width(120))
            }

        }

    }
    // MARK:- 选择背景音乐以后
    func hasAddMusic(_ audioUrl: String,audioTitle:String)  {

        addMusicLabel.isHidden = true
        uploadRemarkLabel.isHidden = true
        puaudioPath = audioUrl
        hasAddMusicView = UIView()
        hasAddMusicView.backgroundColor = .white
        hasAddMusicView.layer.shadowColor = UIColor.grey2.cgColor
        hasAddMusicView.layer.shadowOffset = CGSize(width: 0, height:0)
        hasAddMusicView.layer.shadowRadius = 2
        hasAddMusicView.layer.shadowOpacity = 0.8
        hasAddMusicView.layer.cornerRadius = 10
        hasAddMusicView.layer.masksToBounds = true
        view.addSubview(hasAddMusicView)
        hasAddMusicView.snp.makeConstraints { (make) in
            make.left.equalTo(13)
            make.right.equalTo(-13)
            make.top.equalTo(timeBackGroundView.snp.bottom).offset(20)
            make.height.equalTo(GTSize_width(120))
        }
        retryMusicWordBtn = UILabel.init(frame: .zero)
        retryMusicWordBtn.text = "重新选择"
        retryMusicWordBtn.font =  UIFont.systemFont(ofSize: 12)
        retryMusicWordBtn.textAlignment = .center
        retryMusicWordBtn.isUserInteractionEnabled = true
        retryMusicWordBtn.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(addMusicLabelTapped(_:))))
        retryMusicWordBtn.textColor = UIColor(red: 153.0 / 255.0, green: 153.0 / 255.0, blue: 153.0 / 255.0, alpha: 1.0)
        hasAddMusicView.addSubview(retryMusicWordBtn)
        retryMusicWordBtn.snp.makeConstraints { (make) in
            make.top.equalTo(12)
            make.right.equalTo(-16)
            make.size.equalTo(CGSize(width: 60, height: 14))
        }
        selectMusicSwitch = UISwitch.init(frame: .zero)
        selectMusicSwitch.onTintColor = .grey4
        selectMusicSwitch.thumbTintColor = .pink1
        hasAddMusicView.addSubview(selectMusicSwitch)
        selectMusicSwitch.snp.makeConstraints { (make) in
            make.left.equalTo(15)
            make.top.equalTo(10)
        }
        selectMusicSwitch.addTarget(self, action: #selector(selectMusicSwitchChanged(_:)), for: .valueChanged)

        musicLabel = UILabel.init(frame: .zero)
        musicLabel.text = ""
        musicLabel.textAlignment = .center
        musicLabel.font = UIFont.systemFont(ofSize: 12)
        musicLabel.textColor = UIColor(red: 51.0 / 255.0, green: 51.0 / 255.0, blue: 51.0 / 255.0, alpha: 1.0)
        hasAddMusicView.addSubview(musicLabel)
        musicLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(selectMusicSwitch.snp.centerY)
            make.left.equalTo(selectMusicSwitch.snp.right).offset(10)
        }

        if (GTFileTool.getMp3Name(puaudioPath) != nil) {
            musicLabel.text = GTFileTool.getMp3Name(puaudioPath)!
        }
        musicLabel.text = audioTitle
        let lineView:UIView =  UIView.init(frame: .zero)
        lineView.backgroundColor = .grey2
        hasAddMusicView.addSubview(lineView)
        lineView.snp.makeConstraints { (make) in
            make.left.equalTo(15)
            make.right.equalTo(-15)
            make.top.equalTo(musicLabel.snp.bottom).offset(23)
            make.height.equalTo(0.5)
        }
        let voiceImageView  = UIImageView.init(frame: .zero)
        voiceImageView.image = UIImage.init(named: "音量")
        hasAddMusicView.addSubview(voiceImageView)
        voiceImageView.snp.makeConstraints { (make) in
            make.left.equalTo(15)
            make.bottom.equalTo(-34)
            make.size.equalTo(CGSize(width: 17, height: 17))
        }

        slider = UISlider.init(frame: .zero)
        slider.minimumTrackTintColor = .pink1
        slider.value = 0.5
        slider.thumbTintColor = .pink1
        hasAddMusicView.addSubview(slider)
        slider.snp.makeConstraints { (make) in
            make.left.equalTo(voiceImageView.snp.right).offset(15)
            make.right.equalTo(-15)
            make.centerY.equalTo(voiceImageView.snp.centerY)
        }
        slider.addTarget(self, action: #selector(sliderChanged(_:)), for: .valueChanged)
        //         初始化 背景音乐 loop
        setUpBackgroundLoop()

        if puwordStr == "" {
            hasAddMusicView.snp.remakeConstraints { (make) in
                make.left.equalTo(13)
                make.right.equalTo(-13)
                make.top.equalTo(timeBackGroundView.snp.bottom).offset(20)
                make.height.equalTo(GTSize_width(120))

            }

            addWordLabel.snp.remakeConstraints { (make) in
                make.centerX.equalToSuperview()
                make.left.equalTo(GTSize_width(63))
                make.right.equalTo(-GTSize_width(63))
                make.height.equalTo(40)
                make.top.equalTo(hasAddMusicView.snp.bottom).offset(GTSize_width(41))

            }
        }
        else {
            hasAddMusicView.snp.remakeConstraints { (make) in
                make.left.equalTo(13)
                make.right.equalTo(-13)
                make.top.equalTo(hasAddWordView.snp.bottom).offset(11)

                make.height.equalTo(GTSize_width(120))

            }
        }
        


        //        Guide.
        //        view.layoutIfNeeded()
        //         GuidePage.ShowGuidePage(showPage: self, center:self.addMusicLabel.center, radius: GTSize_height(36.5), guideType: .publish1)
        //        GuidePage.showGuideOnPublish(showPage: self,switchFrame:selectMusicSwitch.frame,sliderFrame:slider.frame,guideType:.publish2)


    }
    func setUpBackgroundLoop()  {
        if puaudioPath != "" {
            let fileUrl = URL.init(fileURLWithPath: puaudioPath)
            self.loop1 = try? AEAudioFilePlayer.init(url: fileUrl)
            self.loop1.volume = 0.5
            loop1.loop = true
            loop1.channelIsPlaying = false
            group = audioController?.createChannelGroup()
            audioController?.addChannels([loop1], toChannelGroup: group)
            
        }


    }
    // MARK:-selectMusicSwitchChanged
    // MARK:- 播放背景音乐
    @objc func selectMusicSwitchChanged(_ sender:UISwitch)  {

        loop1.channelIsPlaying = sender.isOn

        stopTestPlay()
    }

    // MARK:-sliderChanged(_:)
    @objc   func sliderChanged(_ sender:UISlider)  {
        loop1.volume = sender.value
    }
    // MARK:- 移除所有通知
    deinit {

        if self.link != nil {
            self.link?.invalidate()
            self.link = nil
        }
        if self.timer != nil {
            self.timer?.invalidate()
            self.timer = nil
        }
        NotificationCenter.default.removeObserver(self)

        //        do {
        //            try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
        //        } catch let error {
        //            print(error)
        //        }


        //        do {//AVAudioSessionCategoryAmbient
        //            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord, with: AVAudioSessionCategoryOptions.defaultToSpeaker)
        //
        //            //                                do {
        //            //                                    try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
        //            //                                } catch let error {
        //            //                                    print(error)
        //            //                                }
        //
        //
        //        } catch let error {
        //
        //            print("切换扬声器播放 \(error)")
        //
        //        }



    }
    //    @available(iOS 11.0, *)
    //    override func viewSafeAreaInsetsDidChange() {
    //        topBackGroungView.snp.updateConstraints { (make) in
    //            make.top.equalTo(self.view.safeAreaInsets.top - 20)
    //        }
    //        timeBackGroundView.snp.updateConstraints { (make) in
    //            make.top.equalTo(61  + self.view.safeAreaInsets.top - 20)
    //
    //        }
    //
    //    }
    // MARK:- buildView
    func buildView() {
        view.backgroundColor = UIColor(rgb: 0xf0eff5)
        topBackGroungView = UIImageView(frame:.zero)
        topBackGroungView.image = UIImage.init(named: "navigationBar_back_98")
        view.addSubview(topBackGroungView)
        topBackGroungView.snp.makeConstraints { (make) in
            make.top.left.right.equalTo(0)
            make.height.equalTo(94)
        }
        timeBackGroundView = UIImageView.init(frame: .zero)
        timeBackGroundView.image = UIImage.init(named: "矢量智能对象")
        view.addSubview(timeBackGroundView)
        timeBackGroundView.snp.makeConstraints { (make) in
            make.top.equalTo(61)
            make.left.equalTo(40)
            make.right.equalTo(-40)
            make.height.equalTo(153)
        }
        recordTimeMarkLabel0 = UILabel.init(frame: .zero)
        recordTimeMarkLabel0.text = "录音时间"
        recordTimeMarkLabel0.textAlignment = .center
        recordTimeMarkLabel0.font = UIFont.systemFont(ofSize: 13)
        recordTimeMarkLabel0.textColor = UIColor(red: 102.0 / 255.0, green: 102.0 / 255.0, blue: 102.0 / 255.0, alpha: 1.0)
        timeBackGroundView.addSubview(recordTimeMarkLabel0)
        recordTimeMarkLabel0.snp.makeConstraints { (make) in
            make.top.equalTo(47)
            make.centerX.equalToSuperview()
            make.size.equalTo(CGSize(width: 60, height: 14))
        }


        timeLabel = UILabel.init(frame: .zero)
        timeLabel.text = "00:00"
        timeLabel.textAlignment = .center
        timeLabel.font = UIFont.boldSystemFont(ofSize: 26.0)
        timeLabel.textColor = .black
        timeBackGroundView.addSubview(timeLabel)
        timeLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(recordTimeMarkLabel0.snp.bottom).offset(0)
            make.height.equalTo(28)
        }

        recordTimeMarkLabel1 = UILabel.init(frame: .zero)
        recordTimeMarkLabel1.text = "可录制15秒—15分钟喔~"
        recordTimeMarkLabel1.textAlignment = .center
        recordTimeMarkLabel1.font = UIFont.systemFont(ofSize: 12)
        recordTimeMarkLabel1.textColor = UIColor(red: 153.0 / 255.0, green: 153.0 / 255.0, blue: 153.0 / 255.0, alpha: 1.0)
        timeBackGroundView.addSubview(recordTimeMarkLabel1)
        recordTimeMarkLabel1.snp.makeConstraints { (make) in
            make.bottom.equalTo(-15)
            make.centerX.equalToSuperview()

        }

        addWordLabel = UILabel.init(frame: .zero)
        addWordLabel.text = "＋ 选择台词"
        addWordLabel.backgroundColor = UIColor(red: 242.0 / 255.0, green: 242.0 / 255.0, blue: 242.0 / 255.0, alpha: 1.0)
        addWordLabel.textAlignment = .center
        addWordLabel.font = UIFont.systemFont(ofSize: 14)
        addWordLabel.textColor = UIColor(red: 102.0 / 255.0, green: 102.0 / 255.0, blue: 102.0 / 255.0, alpha: 1.0)
        view.addSubview(addWordLabel)
        addWordLabel.layer.cornerRadius = 10
        addWordLabel.isUserInteractionEnabled = true
        addWordLabel.layer.masksToBounds = true
        addWordLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(timeBackGroundView.snp.bottom).offset(GTSize_width(40))
            make.left.equalTo(GTSize_width(63))
            make.right.equalTo(-GTSize_width(63))
            make.height.equalTo(40)
        }
        addWordLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(addWordLabelTapped(_:))))

        addMusicLabel = UILabel.init(frame: .zero)
        addMusicLabel.text = "＋ 选择配乐"
        addMusicLabel.layer.cornerRadius = 10
        addMusicLabel.layer.masksToBounds = true


        addMusicLabel.backgroundColor = UIColor(red: 242.0 / 255.0, green: 242.0 / 255.0, blue: 242.0 / 255.0, alpha: 1.0)
        addMusicLabel.textAlignment = .center
        addMusicLabel.font = UIFont.systemFont(ofSize: 14)
        addMusicLabel.textColor = UIColor(red: 102.0 / 255.0, green: 102.0 / 255.0, blue: 102.0 / 255.0, alpha: 1.0)
        view.addSubview(addMusicLabel)
        addMusicLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(addWordLabel.snp.bottom).offset(GTSize_width(10))
            make.left.equalTo(GTSize_width(63))
            make.right.equalTo(-GTSize_width(63))
            make.height.equalTo(40)

        }
        addMusicLabel.isUserInteractionEnabled = true
        addMusicLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(addMusicLabelTapped(_:))))
        let left = (self.view.frame.size.width - 240)/2

        uploadRemarkLabel = PublishRemakrView.init(frame: CGRect(x: left, y: 0, width: 240, height: 97))
        view.addSubview(uploadRemarkLabel)
        uploadRemarkLabel.snp.makeConstraints { (make) in
            make.left.equalTo(left)
            make.top.equalTo(addMusicLabel.snp.bottom).offset(GTSize_width(42))

        }

        testListenLabel = UILabel.init(frame: .zero)
        testListenLabel.text = "试听"
        testListenLabel.textAlignment = .center
        testListenLabel.font = UIFont.systemFont(ofSize: 13)
        testListenLabel.textColor = UIColor(red: 135.0 / 255.0, green: 136.0 / 255.0, blue: 143.0 / 255.0, alpha: 1.0)
        view.addSubview(testListenLabel)
        testListenLabel.isHidden = true
        testListenLabel.snp.makeConstraints { (make) in
            make.left.equalTo(GTSize_width(66))
            make.bottom.equalTo(-25)
            make.size.equalTo(CGSize(width: 28, height: 14))
        }

        // testListenBtnClcik
        // testListenBtn
        //        testListenBtn = UIButton.init(frame:.zero)
        //        testListenBtn.setImage(UIImage.init(named: "icon_recommend_play"), for: .normal)
        //        //
        //        testListenBtn.setImage(UIImage.init(named: "btn_stop"), for: .selected)
        //        view.addSubview(testListenBtn)
        //        testListenBtn.addTarget(self, action: #selector(testListenBtnClcik(_:)), for: .touchUpInside)
        //        testListenBtn.snp.makeConstraints { (make) in
        //            make.centerX.equalTo(testListenLabel.snp.centerX)
        //            make.size.equalTo(CGSize(width: 40, height: 40))
        //            make.bottom.equalTo(testListenLabel.snp.top).offset(-7)
        //
        //        }


        testplayView = CircleProgressView.init(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        testplayView.lineWidth = 2
        // icon_recommend_play
        testplayView.imageView?.isUserInteractionEnabled = true
        testplayView.imageView?.image = UIImage(named: "icon_recommend_play")
        testplayView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(testplayViewwClick(tap: ))))

        view.addSubview(testplayView)
        testplayView.isHidden = true
        testplayView.snp.makeConstraints { (make) in
            make.centerX.equalTo(testListenLabel.snp.centerX)
            make.size.equalTo(CGSize(width: 40, height: 40))
            make.bottom.equalTo(testListenLabel.snp.top).offset(-7)
        }


        recordLabel = UILabel.init(frame: .zero)
        recordLabel.text = "录音"
        recordLabel.textAlignment = .center
        recordLabel.font = UIFont.systemFont(ofSize: 13)
        recordLabel.textColor = UIColor(red: 135.0 / 255.0, green: 136.0 / 255.0, blue: 143.0 / 255.0, alpha: 1.0)
        view.addSubview(recordLabel)
        recordLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(-15)
            make.size.equalTo(CGSize(width: 70, height: 14))
        }
        // 正在录音
        recordBrn = UIButton.init(frame:.zero)
        recordBrn.setImage(UIImage.init(named: "录音"), for: .normal)
        recordBrn.setImage(UIImage.init(named: "正在录音"), for: .selected)

        view.addSubview(recordBrn)
        recordBrn.addTarget(self, action: #selector(recordBrnClcik(_:)), for: .touchUpInside)
        recordBrn.snp.makeConstraints { (make) in
            make.centerX.equalTo(recordLabel.snp.centerX)
            make.size.equalTo(CGSize(width: 60, height: 60))
            make.bottom.equalTo(recordLabel.snp.top).offset(-7)

        }
        retryLabel = UILabel.init(frame: .zero)
        retryLabel.text = "重录"
        retryLabel.textAlignment = .center
        retryLabel.font = UIFont.systemFont(ofSize: 13)
        retryLabel.textColor = UIColor(red: 135.0 / 255.0, green: 136.0 / 255.0, blue: 143.0 / 255.0, alpha: 1.0)
        view.addSubview(retryLabel)
        retryLabel.isHidden = true
        retryLabel.snp.makeConstraints { (make) in
            make.right.equalTo(-GTSize_width(66))
            make.bottom.equalTo(-15)
            make.size.equalTo(CGSize(width: 28, height: 14))
        }

        retryRecord = UIButton.init(frame:.zero)
        retryRecord.setImage(UIImage.init(named: "重录"), for: .normal)
        view.addSubview(retryRecord)
        retryRecord.addTarget(self, action: #selector(retryRecordClcik(_:)), for: .touchUpInside)
        retryRecord.isHidden = true
        retryRecord.snp.makeConstraints { (make) in
            make.centerX.equalTo(retryLabel.snp.centerX)
            make.size.equalTo(CGSize(width: 60, height: 60))
            make.bottom.equalTo(retryLabel.snp.top).offset(-7)

        }
        self.link = CADisplayLink(target: TXTimerProxy.init(target: self), selector:#selector(loverUpdate))
        self.link?.add( to: RunLoop.current, forMode:.defaultRunLoopMode)
        self.link?.isPaused = true

    }
    // MARK:- test playb
    @objc func playBClcik(_ sender:UIButton)  {

        loop1.channelIsPlaying = sender.isSelected
        sender.isSelected = !sender.isSelected


    }
    //  更新试听 progress 进度条
    @objc func loverUpdate() {
        testplayView?.progress = GTAudioPlayer.share.progress
    }
    // 停止试听
    func stopTestPlay()  {
        if isTestPlay {
            isTestPlay = false
            testplayView.imageView?.isHidden = false
            testplayView?.progress = 0
            GTAudioPlayer.share.stop()
            link?.isPaused = true
        }
    }
    func stopPlayBackGroundVoice() {
        if selectMusicSwitch != nil {
            selectMusicSwitch.isOn = false
        }
        if loop1 != nil {
            loop1.channelIsPlaying = false
        }
    }
    // MARK:- 停止试听和播放背景音乐, 进入 web 页，需停止试听和播放背景音乐
    func stopTestPlayAndPlayBackGroundVoice()  {
        self.stopTestPlay()
        self.stopPlayBackGroundVoice()
    }


    // MARK:- 试听
    @objc func testplayViewwClick(tap: UITapGestureRecognizer) {


        // 1、停止背景音乐播放
        stopPlayBackGroundVoice()
        // 2 试听时，先停止录音
        if (recorder != nil) {
            self.finishRecord {[weak self] in
                self?.link?.isPaused = false
                if (self?.isTestPlay)! {
                    self?.isTestPlay = false
                    self?.testplayView.imageView?.isHidden = false
                    self?.testplayView?.progress = 0
                    GTAudioPlayer.share.stop()
                    self?.link?.isPaused = true
                }
                else {
                    GTAudioPlayer.share.play(urlStr:self?.lastVedio, playState: {[weak self](state:GTAudioPlayState) in
                        switch state {
                        case .playing:
                            print("开始播放")
                            self?.testplayView.imageView?.isHidden = true

                            self?.isTestPlay = true
                        case .failed:
                            print("播放失败")
                        default :
                            break
                        }
                        }, duration: { (durtion) in
                    }, completed: {[weak self] in
                        self?.isTestPlay = false
                        self?.link?.isPaused = true
                        self?.testplayView.imageView?.isHidden = false
                    })

                }
            }

        }
        else {
            self.link?.isPaused = false
            if isTestPlay {
                self.isTestPlay = false
                self.testplayView.imageView?.isHidden = false
                self.testplayView?.progress = 0
                GTAudioPlayer.share.stop()
                link?.isPaused = true
            }
            else {
                GTAudioPlayer.share.play(urlStr:self.lastVedio, playState: {[weak self](state:GTAudioPlayState) in
                    switch state {
                    case .playing:
                        print("开始播放")
                        self?.testplayView.imageView?.isHidden = true

                        self?.isTestPlay = true
                    case .failed:
                        print("播放失败")
                    default :
                        break
                    }
                    }, duration: { (durtion) in
                }, completed: {[weak self] in
                    self?.isTestPlay = false
                    self?.link?.isPaused = true
                    self?.testplayView.imageView?.isHidden = false
                })

            }
        }
    }
    // MARK:-  停止录音 停止播放背景音乐 试听暂停
    func finishRecord(_ complted:(() -> Void)? = nil)  {


        if (recorder != nil) {
            recordBrn.isSelected = false
            recordLabel.text = "录音已暂停"
            if selectMusicSwitch != nil {
                selectMusicSwitch.isOn = false
            }
            if loop1 != nil {
                loop1.channelIsPlaying = false
            }
            // 切换音频输入源 为扬声器
            //            do {
            //                try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
            //            } catch let error {
            //                print(error)
            //            }
            recorder?.finishRecording()
            if timer != nil {
                timer?.invalidate()
            }
            if vedioPath.count > 0 {
                if lastVedio.count == 0 {
                    lastVedio = vedioPath
                    complted?()

                }
                else {
                    mixTwoM4a({
                        // 完成拼接
                        complted?()

                    })
                }
                audioController?.removeOutputReceiver(recorder)
                audioController?.removeInputReceiver(recorder)
                testplayView.isHidden = false
                testListenLabel.isHidden = false
                retryRecord.isHidden = false
                retryLabel.isHidden = false
                self.recorder  = nil
            }
        }
    }


    // MARK:- 录音
    @objc func recordBrnClcik(_ sender:UIButton) {

        if self.totoalSeconds > 900 {
            // 录制最长时间为15分钟
            //            BaseToast.toast(success: "提示", message: "录音最长时间为15分钟")
            print("录音最长时间为15分钟")
            return
        }
        // 录音时停止 试听的播放
        stopTestPlay()

        if (recorder != nil) {
            self.finishRecord()
            //            recordBrn.isSelected = false
            //            recordLabel.text = "录音已暂停"
            //            //切换扬声器播放
            //            do {//AVAudioSessionCategoryAmbient
            //                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategorySoloAmbient, with: AVAudioSessionCategoryOptions.defaultToSpeaker)
            //            } catch let error {
            //                print(error)
            //            }
            //
            //            recorder?.finishRecording()
            //            if timer != nil {
            //                timer?.invalidate()
            //            }
            //            if vedioPath.count > 0 {
            //                if lastVedio.count == 0 {
            //                    lastVedio = vedioPath
            //                }
            //                else {
            //                    mixTwoM4a()
            //                }
            //                audioController.removeOutputReceiver(recorder)
            //                audioController.removeInputReceiver(recorder)
            //                testplayView.isHidden = false
            //                testListenLabel.isHidden = false
            //                self.recorder  = nil
            //            }
        }
        else {

            guard let audioController = audioController else {
                return
            }

            recordBrn.isSelected = true
            recordLabel.text = "正在录音"


            // 切换录音
            if AVAudioSession.sharedInstance().category != AVAudioSessionCategoryPlayAndRecord {
                do {//AVAudioSessionCategoryAmbient
                    try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord, with: AVAudioSessionCategoryOptions.defaultToSpeaker)
                } catch let error {
                    print(error)
                }
            }

            recorder = AERecorder.init(audioController: audioController)
            var documentsFolders = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)

            timer = Timer.GT_scheduledTimer(with: 1, repeat: true, block: { (timer) in
                self.totoalSeconds += 1
                if self.totoalSeconds > 900 {
                    // 录制最长时间为15分钟
                    print("录音最长时间为15分钟")
                    self.finishRecord({

                    })
                    return
                }
                let seconds = self.totoalSeconds % 60
                let minutes = (self.totoalSeconds/60) % 60
                self.timeLabel.text = String(format: "%02d:%02d", minutes, seconds)
            })

            //            let path = GTFileTool.cachePath() + "/GTRecord/Record/" + GTRecordTool.getCurrentTimeString() + ".m4a"
            let path = "\(GTFileTool.cachePath())/\(GTRecordTool.getCurrentTimeString()).m4a"



            //            let path = "\(documentsFolders[0])/\(GTRecordTool.getCurrentTimeString()).m4a"

            vedioPath = path

            let error: Error? = nil
            if !(((try? recorder!.beginRecordingToFile(atPath: path, fileType: kAudioFileM4AType)) != nil)) {
                UIAlertView(title: "Error", message: "Couldn't start recording: \(error?.localizedDescription)", delegate: nil, cancelButtonTitle: "", otherButtonTitles: "OK").show()
                recorder = nil
                return
            }
            audioController.addOutputReceiver(recorder)
            audioController.addInputReceiver(recorder)
        }



    }
    // MARK:- 合并录制的音频
    func mixTwoM4a(_ complted:(() -> Void)? = nil)  {

        //        let path = GTFileTool.cachePath() + "/GTMix/" + GTRecordTool.getCurrentTimeString() + ".m4a"
        //        let path = "\(documentsFolders[0])/Mix-----\(GTRecordTool.getCurrentTimeString()).m4a"
        let path = "\(GTFileTool.cachePath())/Mix-----\(GTRecordTool.getCurrentTimeString()).m4a"

        //          let hud = pleaseWait()
        GTRecordTool.addAudioFile(URL.init(fileURLWithPath: vedioPath), toAudioFile: URL.init(fileURLWithPath: lastVedio), savePath: path) {
            print("viewController 合并完成")
            GTRecordTool.deleteWithFileURL(fileUrl: URL.init(fileURLWithPath: self.vedioPath))
            GTRecordTool.deleteWithFileURL(fileUrl: URL.init(fileURLWithPath: self.lastVedio))

            self.lastVedio = path
            complted?()
            //            hud.hide()

        }
    }
    // MARK:- 重录
    @objc func retryRecordClcik(_ sender:UIButton) {
        // 停止播放背景音乐 停止试听
        stopTestPlayAndPlayBackGroundVoice()
        // 初始化背景音乐 loop
        setUpBackgroundLoop()

        // 完成录音，停止播放，删除本地录音数据，录音时间置为 0
        //删除本地录制的音频

        if (recorder != nil) {
            finishRecord({[weak self] in
                GTRecordTool.deleteWithFileURL(fileUrl: URL.init(fileURLWithPath: (self?.lastVedio)!))
            })
        }
        else {
            GTRecordTool.deleteWithFileURL(fileUrl: URL.init(fileURLWithPath: self.lastVedio))
        }
        // 停止播放
        stopTestPlay()
        // 录音时间置为 0
        timeLabel.text = "00:00"
        testplayView.isHidden = true
        testListenLabel.isHidden = true
        recordLabel.text = "录音"
        totoalSeconds = 0
    }
    @objc func testListenBtnClcik(_ sender:UIButton) {

        if (player != nil) {
            audioController?.removeChannels([player!])
            player = nil

            testListenBtn.isSelected = false
        }
        else {
            self.player = try? AEAudioFilePlayer.init(url: URL.init(fileURLWithPath: self.lastVedio ))
            player?.removeUponFinish = true
            player?.completionBlock = {[weak self] in
                self?.player = nil
                self?.testListenBtn.isSelected = false
            }
            audioController?.addChannels([player!])
            testListenBtn.isSelected = true
        }
    }
    // MARK:-  选择歌词
    @objc func addWordLabelTapped(_ tap: UITapGestureRecognizer) {
        //1 停止播放试听音乐和背景音乐
        stopTestPlayAndPlayBackGroundVoice()
        //2、如果未录制，直接跳转选择歌曲页面，可配置为 H5页面，如果正在录制，先暂停录音
        let  lastStr:String = "让我掉下眼泪的 不止昨夜的酒\n让我依依不舍的 不止你的温柔\n余路还要走多久 你攥着我的手\n让我感到为难的 是挣扎的自由\n分别总是在九月 回忆是思念的愁\n深秋嫩绿的垂柳 亲吻着我额头\n在那座阴雨的小城里 我从未忘记你\n成都 带不走的 只有你\n和我在成都的街头走一走\n直到所有的灯都熄灭了也不停留\n你会挽着我的衣袖 我会把手揣进裤兜\n走到玉林路的尽头 坐在小酒馆的门口\n分别总是在九月 回忆是思念的愁\n深秋嫩绿的垂柳 亲吻着我额头\n在那座阴雨的小城里 我从未忘记你\n成都 带不走的 只有你\n和我在成都的街头走一走\n直到所有的灯都熄灭了也不停留\n你会挽着我的衣袖 我会把手揣进裤兜\n走到玉林路的尽头 坐在小酒馆的门口\n和我在成都的街头走一走\n直到所有的灯都熄灭了也不停留\n和我在成都的街头走一走\n直到所有的灯都熄灭了也不停留\n你会挽着我的衣袖 我会把手揣进裤兜\n走到玉林路的尽头 坐在(走过)小酒馆的门口"
        let event = SelectWordEvent(id:"SelectWordEvent")
        event.word = lastStr
        // 选择台词和配乐，自动暂停录制
        if (recorder != nil) {
            self.finishRecord {
                DispatchQueue.main.async {
                    EventBus.getDefault().post(event: event)
                }
            }
        }
        else {
            DispatchQueue.main.async {
                EventBus.getDefault().post(event: event)
            }
        }
    }
    // MARK:-  选择配乐
    @objc func addMusicLabelTapped(_ tap: UITapGestureRecognizer) {
        //
        stopTestPlayAndPlayBackGroundVoice()
        guard let path = Bundle.main.path(forResource: "Summer", ofType: "mp3") else {
            return
        }
        let event = SelectMusicEvent(id:"SelectMusicEvent")
        let filePath = path
        event.musicUrl = filePath
        event.musicTitle = "Summer-久石让"

        if (recorder != nil) {
            self.finishRecord {
                DispatchQueue.main.async {
                    EventBus.getDefault().post(event: event)
                }
            }

        }
        else {
            DispatchQueue.main.async {
                EventBus.getDefault().post(event: event)
            }
        }

    }



    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}
class PublishRemakrView: UIView {
    var uploadImageView:UIImageView!
    var uploadLabel:UILabel!
    var remakrLabel:UILabel!
    override init(frame: CGRect) {
        super.init(frame: frame)
        uploadImageView = UIImageView.init(frame: .zero)
        uploadImageView.image = UIImage.init(named: "upload")
        self.addSubview(uploadImageView)
        uploadImageView.snp.makeConstraints { (make) in
            make.top.equalTo(0)
            make.left.equalTo(65)
            make.size.equalTo(CGSize(width: 23, height: 16))
        }
        uploadLabel = UILabel.init(frame: .zero)
        uploadLabel.font = UIFont.systemFont(ofSize: 13)
        uploadLabel.textColor = UIColor(red: 102.0 / 255.0, green: 102.0 / 255.0, blue: 102.0 / 255.0, alpha: 1.0)
        self.addSubview(uploadLabel)
        uploadLabel.text = "电脑上传"
        uploadLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(uploadImageView.snp.centerY)
            make.left.equalTo(uploadImageView.snp.right).offset(5)
            make.size.equalTo(CGSize(width: 60, height: 14))
        }

        let remakrLabel:UILabel = UILabel(frame:.zero)
        remakrLabel.font = UIFont.systemFont(ofSize: 12)
        remakrLabel.textColor = UIColor(red: 153.0 / 255.0, green: 153.0 / 255.0, blue: 153.0 / 255.0, alpha: 1.0)
        remakrLabel.textAlignment = .left
        remakrLabel.numberOfLines = 0
        remakrLabel.text = ""
        addSubview(remakrLabel)
        let attributedString = NSMutableAttributedString(string: "1、打开电脑端浏览器，输入hi.sdo.com\n2、登录您的账号\n3、点击“上传声音”按钮，即可上传本地声音\n4、上传后，手机APP会同步您的声音数据")
        attributedString.addAttributes([
            NSAttributedStringKey.font:UIFont.systemFont(ofSize: 12),
            NSAttributedStringKey.foregroundColor:UIColor(red: 233.0 / 255.0, green: 69.0 / 255.0, blue: 200.0 / 255.0, alpha: 1.0)
            ], range: NSRange(location: 13, length: 10))
        remakrLabel.attributedText = attributedString
        remakrLabel.snp.makeConstraints { (make) in
            make.left.right.equalTo(0)
            make.top.equalTo(uploadLabel.snp.bottom).offset(18)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

