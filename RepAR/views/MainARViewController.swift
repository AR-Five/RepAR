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
    var currentStep: RepairStep? {
        didSet { handleCurrentStep() }
    }
    
    var nbSteps = 12 {
        didSet { updateProgress() }
    }
    var stepsDone = 0 {
        didSet { updateProgress() }
    }
    
    lazy var navigationView: NavigationViewController = {
       return storyboard?.instantiateViewController(withIdentifier: ViewsIdentifier.navigationView) as! NavigationViewController
    }()
    
    lazy var choiceView: ChoiceViewController = {
        return storyboard?.instantiateViewController(withIdentifier: ViewsIdentifier.choiceView) as! ChoiceViewController
    }()
    
    lazy var endView: BlurTitleViewController = {
        return storyboard?.instantiateViewController(withIdentifier: ViewsIdentifier.blurTitle) as! BlurTitleViewController
    }()
    
    @IBOutlet var infoLabel: UILabel!
    @IBOutlet var containerView: UIView!
    @IBOutlet var progressLabel: UILabel!
    @IBOutlet var progressBar: UIProgressView!
    
    
    @IBAction func onReset(_ sender: UIButton) {
        delegate?.onReset()
        stepsDone = 0
        currentStep = Repair.run()
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
        
        navigationView.delegate = self
        choiceView.delegate = self
        endView.delegate = self
        
        updateProgress()
        
        currentStep = Repair.run()
    }
    
    func reset() {
        delegate?.onReset()
        stepsDone = 0
        currentStep = Repair.run()
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
        if let row = switchboard?.rows.first {
            currentStep = Repair.firstCase(row: row)
        }
//
//        for row in swb.rows {
//            row.rowSwitch?.toggleArrow(on: true)
//            /*
//             row.switches.first?.toggleArrow(on: true)
//             let sw = row.switches.first!
//             print(sw.dimension, sw.position) */
//        }
    }
    
    
    func handleCurrentStep() {
        // reset all hints on the switches
        switchboard?.hideAllHints()
        
        guard let step = currentStep else { return }
        handleShowToolsView(type: step.viewType)
        
        setLabel(text: step.text)
        stepsDone += 1
        
        
        if step.action == .pullLeverUp {
//            step.currentSwitch?.toggleHand(on: true)
            step.currentSwitch?.toggleArrow(on: true)
        }
        
        if step.action == .askSwitchBroken {
            step.currentSwitch?.toggleArrow(on: true)
        }
        
        if step.action == .pullAllSimpleSwitchDown {
            if let rows = switchboard?.rows {
                for row in rows {
                    row.switches.forEach { $0.toggleArrow(on: true) }
                }
            }
        }
        
        if step.action == .end {
            DispatchQueue.main.async {
                self.switchTo(vc: self.endView)
                self.endView.mainTitle.text = step.text
            }
            return
        }
        
        // if the view type is choice we build the buttons
        if step.viewType == .choices {
            DispatchQueue.main.async {
                self.choiceView.addButtons(step.choicesButtonLabel)
            }
        }
    }
    
    func handleShowToolsView(type: RepairViewType) {
        if type == .navigation {
            containerView.show(view: navigationView.view)
        } else {
            containerView.hide(view: navigationView.view)
        }
        
        if type == .choices {
            containerView.show(view: choiceView.view)
        } else {
            containerView.hide(view: choiceView.view)
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
        DispatchQueue.main.async {
            self.progressLabel.text = "\(self.stepsDone)/\(self.nbSteps)"
            self.progressBar.setProgress(Float(self.stepsDone) / Float(self.nbSteps), animated: true)
        }
    }
    
    func allSwitchWorking() -> Bool {
        if let swb = switchboard {
            if let row = swb.rows.first {
                let okSwitches = row.switches
                    .filter { $0.state == SwitchState.normal }
                    .count
                return okSwitches == row.switches.count
            }
        }
        return false
    }
}

extension MainARViewController: NavigationDelegate {
    func onNext() {
        if let next = currentStep?.getNext() {
            currentStep = next
        }
    }
    
    func onBack() {
        if let prev = currentStep?.prev {
            currentStep = prev
        }
    }
}


extension MainARViewController: ChoiceViewDelegate {
    func onTap(id: Int) {
        if let step = currentStep, step.viewType == .choices {
            if id < step.choicesButtonLabel.count {
                let choice = step.choicesButtonLabel[id]
                switch choice.id {
                case "failed":
                    step.currentSwitch?.state = .error
                    currentStep = step.getNextFailed()
                    break
                case "ok", "unknown":
                    step.currentSwitch?.state = .normal
                    currentStep = step.getNext()
                    break
                case "yes":
                    if step.action == .askSwitchBroken {
                        currentStep = Repair.resetCaseThree()
                    }
                    break
                case "no":
                    if step.action == .askSwitchBroken {
                        if allSwitchWorking() {
                            currentStep = Repair.endCaseThree()
                        } else {
                            currentStep = step.getNext()
                        }
                    }
                    break
                default:
                    break
                }
            }
        }
    }
}

extension MainARViewController: BlurTitleDelegate {
    func onOk() {
        // todo
    }
}
