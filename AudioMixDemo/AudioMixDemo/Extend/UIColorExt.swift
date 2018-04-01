//
//  UIColorExt.swift
//  GenialTone
//
//  Created by SNDA on 2017/6/21.
//  Copyright © 2017年 SNDA. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    class var grey2: UIColor {
        return UIColor(rgb: 0xa1a1a1)
    }
    class var pink1: UIColor {
        //        return UIColor(rgb: 0xff6f9b)//TODO: 修改主色
        return UIColor(rgb: 0xde49aa)
    }
    class var grey4: UIColor {
        return UIColor(rgb: 0xf3f3f3)
    }
    convenience init(rgb: UInt, alpha: CGFloat = 1) {
        self.init(red: CGFloat((rgb & 0xFF0000) >> 16) / 255.0, green: CGFloat((rgb & 0x00FF00) >> 8) / 255.0, blue: CGFloat(rgb & 0x0000FF) / 255.0, alpha: alpha)
    }
}
