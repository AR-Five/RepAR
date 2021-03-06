//
//  RoundedButton.swift
//  RepAR
//
//  Created by Guillaume Carré on 13/05/2018.
//  Copyright © 2018 ARFive. All rights reserved.
//

import UIKit

@IBDesignable
class RoundedButton: UIButton {
    
    @IBInspectable var cornerRadiusValue: CGFloat = 0
    @IBInspectable var round: Bool = false
    
    override func draw(_ rect: CGRect) {
        
        if round {
            layer.cornerRadius = rect.height / 2
        } else {
            layer.cornerRadius = cornerRadiusValue
        }
        
//        layer.shadowColor = UIColor.black.cgColor
//        layer.shadowOpacity = 1
//        layer.shadowOffset = CGSize(width: 0, height: 2)
//        layer.shadowPath = UIBezierPath(rect: bounds).cgPath
//        layer.shadowRadius = 0
    }
    
}
