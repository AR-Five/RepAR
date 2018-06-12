//
//  HelpViewController.swift
//  RepAR
//
//  Created by Guillaume Carré on 12/06/2018.
//  Copyright © 2018 ARFive. All rights reserved.
//

import UIKit

class HelpViewController: UIViewController {
    
    var help: RepairHelp?
    
    @IBOutlet var helpView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupHelpView()
    }
    
    func setupHelpView() {
        if let h = help {
            let label = createLabel(text: h.text)
            
            let margin = helpView.layoutMarginsGuide
            
            helpView.addSubview(label)
            
            if let img = h.image {
                let imgViewer = createImageView(image: img)
                helpView.addSubview(imgViewer)
                imgViewer.topAnchor.constraint(equalTo: margin.topAnchor, constant: 10).isActive = true
                imgViewer.leadingAnchor.constraint(equalTo: margin.leadingAnchor, constant: 16).isActive = true
                imgViewer.trailingAnchor.constraint(equalTo: margin.trailingAnchor, constant: -16).isActive = true
                imgViewer.heightAnchor.constraint(equalToConstant: 200).isActive = true

                label.topAnchor.constraint(equalTo: imgViewer.bottomAnchor, constant: 20).isActive = true
            } else {
                label.topAnchor.constraint(equalTo: margin.topAnchor, constant: 10).isActive = true
            }
            label.leadingAnchor.constraint(equalTo: margin.leadingAnchor, constant: 16).isActive = true
            label.trailingAnchor.constraint(equalTo: margin.trailingAnchor, constant: -16).isActive = true
        }
    }
    
    func createImageView(image: UIImage) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = image
        return imageView
    }
    
    func createLabel(text: String) -> UILabel {
        let label = UILabel()
        label.font = UIFont(name: "Fredoka One", size: 20)
        label.textColor = #colorLiteral(red: 0.2862745098, green: 0.2862745098, blue: 0.2862745098, alpha: 1)
        label.textAlignment = .center
        label.text = text
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
}
