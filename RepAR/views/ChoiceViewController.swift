//
//  TitleView.swift
//  RepAR
//
//  Created by Guillaume Carré on 13/05/2018.
//  Copyright © 2018 ARFive. All rights reserved.
//

import UIKit

class ChoiceViewController: UIViewController {
    
    
    @IBOutlet var stackView: UIStackView!
    
    @IBOutlet var defaultButton: RoundedButton!
    
    @IBAction func onTapButton(_ sender: UIButton) {
        
    }
    
    func createButton(title: String, tag: Int) -> RoundedButton {
        let btn = RoundedButton()
        btn.tag = tag
        btn.round = true
        btn.backgroundColor = #colorLiteral(red: 0.9921568627, green: 1, blue: 0.1333333333, alpha: 1)
        btn.setTitleColor(#colorLiteral(red: 0.2862745098, green: 0.2862745098, blue: 0.2862745098, alpha: 1), for: .normal)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = UIFont(name: "Fredoka One", size: 25)
        btn.clipsToBounds = true
        NSLayoutConstraint(item: btn, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 60).isActive = true
        return btn
    }
    
    func addButtons(_ btns: [RepairButtonChoice]) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (index, btn) in btns.enumerated() {
            let newBtn = createButton(title: btn.title, tag: index)
            stackView.addArrangedSubview(newBtn)
        }
    }
    
}
