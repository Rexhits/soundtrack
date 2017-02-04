//
//  STButton.swift
//  Soundtrack_final
//
//  Created by WangRex on 1/18/17.
//  Copyright © 2017 WangRex. All rights reserved.
//

import UIKit

class STToolbarButton: UIButton {
    
    override func layerWillDraw(_ layer: CALayer) {
        layer.bounds = CGRect(x: 0, y: 0, width: 30, height: 30)
        layer.backgroundColor = UIColor.clear.cgColor
    }
    
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
//        self.layer.borderColor = UIColor.orange.cgColor
//        self.layer.borderWidth = 1.0
        self.layer.cornerRadius = 5
        self.clipsToBounds = true
        self.layer.masksToBounds = true
        self.imageEdgeInsets = UIEdgeInsetsMake(2, 2, 2, 2)
        if isOn {
            self.tintColor = UIColor.black
        } else {
            self.tintColor = UIColor.white
        }
    }
    
    var isOn: Bool = false {
        didSet {
            if isOn {
                self.backgroundColor = UIColor.white
                self.tintColor = UIColor.black
            } else {
                self.backgroundColor = UIColor.clear
                self.tintColor = UIColor.white
            }
        }
    }
}
