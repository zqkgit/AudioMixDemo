//
//  Constants.swift
//  AudioMixDemo
//
//  Created by 五月 on 2018/4/1.
//  Copyright © 2018年 Kent. All rights reserved.
//

import UIKit

// 耳机插拔
let  EarphonePullOut  = "EarphonePullOut" // 耳机拔出
let  EarphoneInsertion  = "EarphoneInsertion" // 耳机插入
// 适配
var KScreenHeight: CGFloat {
    return UIScreen.appHeight()
}
var KScreenWidth: CGFloat {
    return UIScreen.appWidth()
}
var isIPhone6: Bool {
    return KScreenHeight == 667
}
var isIPhone6Plus: Bool {
    return KScreenHeight == 736
}
var isIPhoneX: Bool {
    return KScreenHeight == 812
}
var isIPhone4: Bool {
    return KScreenHeight == 480
}
var isIPhone5: Bool {
    return KScreenHeight == 568
}

// 传进来 6s的尺寸
func GTSize_width(_ width: CGFloat) -> CGFloat {

    switch KScreenWidth {
    case 375:
        return width
    case 414:
        return width * 1.104
    case 320:
        return width * 0.85
    default:
        return width
    }
}
func GTSize_height(_ height: CGFloat) -> CGFloat {

    switch KScreenHeight {
    case 667: //6s 6
        return height
    case 736://plus
        return height * 1.10
    case 568: // 5
        return height * 0.85
    case 480://4
        return height * 0.71
    case 812: // X
        return height * 1.21
    default:
        return height
    }
}
