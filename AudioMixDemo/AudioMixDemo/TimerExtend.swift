//
//  TimerExtend.swift
//  testLink
//
//  Created by 五月 on 2018/3/6.
//  Copyright © 2018年 孙凯峰. All rights reserved.
//

import UIKit
import Foundation


extension Timer {
    static func GT_scheduledTimer(with interval: TimeInterval, repeat IsRepeat: Bool, block: @escaping (_: Timer) -> Void) -> Timer {
        return self.scheduledTimer(timeInterval: interval, target: self, selector: #selector(start), userInfo: block, repeats: IsRepeat)

    }

    @objc static func start(_ timer: Timer) {
        let block: ((_ timer: Timer) -> Void)? = timer.userInfo as? ((Timer) -> Void)
        if block != nil {
            block!(timer)
        }
    }

}

