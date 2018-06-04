//
//  BlurTitleViewController.swift
//  RepAR
//
//  Created by Guillaume Carré on 03/06/2018.
//  Copyright © 2018 ARFive. All rights reserved.
//

import UIKit

protocol BlurTitleDelegate {
    func onOk()
}

class BlurTitleViewController: UIViewController {
    
    var delegate: BlurTitleDelegate?
    @IBOutlet var mainTitle: UILabel!
    
    @IBAction func onOk(_ sender: RoundedButton) {
        delegate?.onOk()
    }
}
