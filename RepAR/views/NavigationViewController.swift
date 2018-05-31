//
//  NextPrevViewController.swift
//  RepAR
//
//  Created by Guillaume Carré on 30/05/2018.
//  Copyright © 2018 ARFive. All rights reserved.
//

import UIKit

protocol NavigationDelegate {
    func onNext()
    func onBack()
}

class NavigationViewController: UIViewController {
    
    var delegate: NavigationDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func onNext(_ sender: UIButton) {
        delegate?.onNext()
    }
    
    @IBAction func onBack(_ sender: UIButton) {
        delegate?.onBack()
    }
    
    
}
