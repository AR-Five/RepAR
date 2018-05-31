//
//  MainARViewController.swift
//  RepAR
//
//  Created by Guillaume Carré on 31/05/2018.
//  Copyright © 2018 ARFive. All rights reserved.
//

import UIKit
import ARKit

protocol MainARDelegate {
    func onReset()
}

class MainARViewController: UIViewController {
    
    var delegate: MainARDelegate?
    
    var switchboard: SwitchBoard?
    var currentStep: RepairStep!
    
    var nbSteps = 12 {
        didSet { updateProgress() }
    }
    var stepsDone = 0 {
        didSet { updateProgress() }
    }
    
    lazy var nextPrevView: NextPrevViewController = {
       return storyboard?.instantiateViewController(withIdentifier: ViewsIdentifier.nextPrevView) as! NextPrevViewController
    }()
    
    @IBOutlet var infoLabel: UILabel!
    @IBOutlet var containerView: UIView!
    @IBOutlet var progressLabel: UILabel!
    @IBOutlet var progressBar: UIProgressView!
    
    
    @IBAction func onReset(_ sender: UIButton) {
        delegate?.onReset()
        handleSteps(step: currentStep)
    }
    
    @IBAction func onToggleMenu(_ sender: UIButton) {
        // TODO: to implement
    }
    
    @IBAction func onToggleInfo(_ sender: UIButton) {
        // TODO: to implement
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        infoLabel.layer.cornerRadius = 15
        
        let repair = Repair()
        
        currentStep = repair.run()
        handleSteps(step: currentStep)
    }
    
    func handleImageDetected(image: ARReferenceImage, node: SCNNode) {
        /*
         // Create a plane to visualize the initial position of the detected image.
         let plane = SCNPlane(width: image.physicalSize.width,
         height: image.physicalSize.height)
         plane.firstMaterial?.diffuse.contents = UIColor.yellow
         let planeNode = SCNNode(geometry: plane)
         planeNode.opacity = 0.1
         
         /*
         `SCNPlane` is vertically oriented in its local coordinate space, but
         `ARImageAnchor` assumes the image is horizontal in its local space, so
         rotate the plane to match.
         */
         planeNode.eulerAngles.x = -.pi / 2
         
         // Add the plane visualization to the scene.
         node.addChildNode(planeNode)
         */
        
        switchboard = SwitchBoard(node: node, size: image.physicalSize)
        handleSteps(step: currentStep.getNext())
//
//        for row in swb.rows {
//            row.rowSwitch?.toggleArrow(on: true)
//            /*
//             row.switches.first?.toggleArrow(on: true)
//             let sw = row.switches.first!
//             print(sw.dimension, sw.position) */
//        }
    }
    
    
    func handleSteps(step: RepairStep?) {
        guard let s = step else { return }
        
        setLabel(text: s.text)
        view.addSubview(nextPrevView.view)
        
        switch s.action {
        case .gotoSwitchBoard:
            return
        default:
            return
        }
    }
    
    func setLabel(text: String) {
        DispatchQueue.main.async {
            self.transitionLabel()
            self.infoLabel.text = text
        }
    }
    
    
    func transitionLabel() {
        infoLabel.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        UIView.animate(withDuration: 2, delay: 0, usingSpringWithDamping: 0.2, initialSpringVelocity: 6, options: .allowUserInteraction, animations: {
            self.infoLabel.transform = CGAffineTransform.identity
        }, completion: nil)
    }
    
    private func updateProgress() {
        progressLabel.text = "\(stepsDone)/\(nbSteps)"
        progressBar.setProgress(Float(nbSteps / stepsDone), animated: true)
    }
}
