//
//  TitleView.swift
//  RepAR
//
//  Created by Guillaume Carré on 13/05/2018.
//  Copyright © 2018 ARFive. All rights reserved.
//

import UIKit

protocol TitleViewDelegate {
    func onTitleBtn()
}

class TitleViewController: UIViewController {
    
    var delegate: TitleViewDelegate?
    
    @IBOutlet var titleLabel: UILabel!
    
    
    @IBAction func titleButton(_ sender: UIButton) {
        view.isHidden = true
        self.didMove(toParentViewController: nil)
        self.view.removeFromSuperview()
        self.removeFromParentViewController()
        
        delegate?.onTitleBtn()
    }
    
}
