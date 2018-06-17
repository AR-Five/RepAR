//
//  MenuPopoverViewController.swift
//  RepAR
//
//  Created by Guillaume Carré on 12/06/2018.
//  Copyright © 2018 ARFive. All rights reserved.
//

import UIKit

protocol MenuDelegate {
    func onTapHome()
}

class MenuPopoverViewController: UIViewController {

    var delegate: MenuDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateLabelTorch()
    }
    
    func updateLabelTorch() {
        if isTorchEnabled() {
            torchButton.setTitle("Eteindre torche", for: .normal)
        } else {
            torchButton.setTitle("Allumer torche", for: .normal)
        }
    }
    
    @IBOutlet var torchButton: RoundedButton!
    
    @IBAction func onTapHome(_ sender: UIButton) {
        dismiss(animated: false) {
            self.delegate?.onTapHome()
        }
    }
    
    @IBAction func onToggleTorch(_ sender: UIButton) {
        toggleTorch(on: !isTorchEnabled())
        updateLabelTorch()
    }
    
}
