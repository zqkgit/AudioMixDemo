//
//  CircleProgressView.swift
//  StudyCirclePlay
//
//  Created by 五月 on 2017/9/14.
//  Copyright © 2017年 孙凯峰. All rights reserved.
//

import UIKit

class CircleProgressView: UIView {
    var centerLabel: UILabel?
    var progressView: BaseCircleView?
    var imageView: UIImageView?
    var playStopImageview: UIImageView?

    //linewidth
    var lineWidth: CGFloat = 2.0 {
        didSet {
            updateLineWidth()
        }
    }
    //progress
    var progress: CGFloat = 0.0 {
        didSet {
//            if progress > 0 {
//                self.playStopImageview?.isHidden = false
//            } else if progress == 1.0 {
//                self.playStopImageview?.isHidden = true
//            }
            updateProgress()

        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
        initViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - init
    func initViews() {
        self.playStopImageview =  UIImageView(frame: bounds)
        self.playStopImageview?.image = UIImage(named:"btn_stop")
        self.addSubview(self.playStopImageview!)
        self.playStopImageview?.snp.makeConstraints({ (make) in
            make.size.equalTo(self.frame.size)//38,38
            make.center.equalToSuperview()
        })
//        playStopImageview?.isHidden = true
        self.progressView = BaseCircleView.init(frame: self.frame)
        self.addSubview(progressView!)

        self.imageView = UIImageView(frame: bounds)
        self.addSubview(self.imageView!)
        self.imageView?.snp.makeConstraints({ (make) in
            make.size.equalTo(self.frame.size)
            make.center.equalToSuperview()
        })

    }

    func updateProgress() {
        self.progressView?.progress = progress;

    }

    func updateLineWidth() {
        self.progressView?.lineWidth = lineWidth
    }

    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
     // Drawing code
     }
     */
}

class BaseCircleView: UIView {

    private var outLayer: CAShapeLayer?
    private var progressLayer: CAShapeLayer?
    //linewidth
    var lineWidth: CGFloat = 2.0 {
        didSet {
            updateLineWidth()
        }
    }
    //progress
    var progress: CGFloat = 0.0 {
        didSet {
            guard (self.progressLayer != nil) else {
                return
            }
            updateProgress()
            if progress==1.0 {
                progressLayer?.isHidden = true
            } else {
                progressLayer?.isHidden = false
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        addViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - add views
    func addViews() {

        self.outLayer = CAShapeLayer.init()
        outLayer?.strokeColor = UIColor.grey2.cgColor //UI修改:lightGray-> DDDDDD
        outLayer?.lineWidth = 0.5//lineWidth/2.5
        outLayer?.fillColor =  UIColor.clear.cgColor
        outLayer?.lineCap = kCALineCapRound
        self.layer.addSublayer(outLayer!)

        self.progressLayer = CAShapeLayer.init()
        progressLayer?.fillColor = UIColor.clear.cgColor
        progressLayer?.strokeColor = UIColor.pink1.cgColor
        progressLayer?.lineWidth = lineWidth
        progressLayer?.lineCap = kCALineCapRound
        self.layer.addSublayer(progressLayer!)

        outLayer?.strokeEnd = 1.0
        progressLayer?.strokeEnd = 0.0

    }
    override func layoutSubviews() {
        super.layoutSubviews()
        outLayer?.path = layoutBezierPath().cgPath
        progressLayer?.path = layoutBezierPath().cgPath
    }

    func layoutBezierPath() -> UIBezierPath {
        //        let rect = CGRect(x: lineWidth/2.0, y: lineWidth/2.0, width: self.frame.size.width-lineWidth, height: self.frame.size.height-lineWidth)
        //        let path = UIBezierPath.init(ovalIn: rect)
        let TWO_M_PI: Double  = 2.0 * Double.pi
        let startAngle: Double = 0.75 * TWO_M_PI
        let endAngle: Double = startAngle + TWO_M_PI

        let width: CGFloat = self.frame.size.width-2*lineWidth

        let path = UIBezierPath.init(arcCenter: CGPoint(x: (self.frame.size.width)/2.0, y: self.frame.size.width/2.0), radius: width/2.0, startAngle: CGFloat(startAngle), endAngle: CGFloat(endAngle), clockwise: true)

        return path
    }

    func updateProgress() {
        CATransaction.begin()
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction.init(name: kCAMediaTimingFunctionEaseIn))
        CATransaction.setAnimationDuration(CFTimeInterval.init(0.016))
        self.progressLayer?.strokeEnd = progress
        CATransaction.commit()

    }

    func updateLineWidth() {
        self.outLayer?.lineWidth = 0.5//lineWidth
        self.progressLayer?.lineWidth = lineWidth
    }

    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
     // Drawing code
     }
     */

}
