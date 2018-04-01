AudioMixDemo
==
仿喜马拉雅音频录制，支持录音时合成添加的背景音乐（外放、带着耳机） 
=====
#### 原理 利用了 TheAmazingAudioEngine 对 AudioUnit 的封装，实现了录音，回声消除，录音实时合成背景音乐的需求
#### 基本功能
* 录音
* 合成录音添加的背景音乐，无论外放背景音乐，还是带着耳机
* 支持实时改变背景音乐音量大小
* m4a 转 caf， caf 转 m3

#### 需要导入的库
* [TheAmazingAudioEngine](https://github.com/TheAmazingAudioEngine/TheAmazingAudioEngine)
* Lame（一个强大的转 Mp3 的 SDK ,项目里已有编译好的framework，支持64位）

#### Version
* 1.0

####  Requirements
* iOS 9.0 or higher







![](https://raw.githubusercontent.com/wubianxiaoxian/AudioMixDemo/master/AudioMixDemo/mixGif.gif)
