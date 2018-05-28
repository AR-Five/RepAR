//
//  ViewController.swift
//  RepAR
//
//  Created by Guillaume Carré on 29/03/2018.
//  Copyright © 2018 ARFive. All rights reserved.
//

import UIKit
import ARKit
import VideoToolbox


class ARViewController: UIViewController {
    
    @IBOutlet var sceneView: ARSCNView!
    
    @IBOutlet var detectionBtn: UIButton!
    
    @IBOutlet var topInfoLabel: UILabel!
    
    @IBOutlet var mainView: UIView!
    
    private let processQueue = DispatchQueue.global(qos: .userInitiated)
    
    var imageDetected = false
    var imageDetectedAnchor: ARImageAnchor?
    
    var detectionInitiated = false
    
    var switchboard: SwitchBoard!
    
    lazy var mainTitle: TitleView = {
        let mainTitle = storyboard?.instantiateViewController(withIdentifier: "mainTitle") as! TitleView
        return mainTitle
    }()
    
    func initTitleView() {
        mainTitle.delegate = self
        view.addSubview(mainTitle.view)
        mainTitle.view.frame = view.bounds
        mainTitle.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mainTitle.didMove(toParentViewController: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initTitleView()
        topInfoLabel.isHidden = true
        topInfoLabel.layer.cornerRadius = 15
        
        setLabel(text: "Dirigez vous vers votre tableau électrique.")
        
        let tapgesture = UITapGestureRecognizer(target: self, action: #selector(self.tapGesture))
        
        view.addGestureRecognizer(tapgesture)
        
        initArView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        initARSessionDefault()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    
    @IBAction func resetScene(_ sender: UIButton) {
        if let imageAnchor = imageDetectedAnchor {
            sceneView.session.remove(anchor: imageAnchor)
        }
        
        sceneView.scene.rootNode.childNodes.forEach { node in
            if node.name == "balls" {
                node.removeFromParentNode()
            }
        }
        
        setLabel(text: "Dirigez vous vers votre tableau électrique.")
    }
    
    func initArView() {
        
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.autoenablesDefaultLighting = true
        
        sceneView.antialiasingMode = .multisampling4X
        
        // Show statistics such as fps and timing information
        //sceneView.showsStatistics = true
        //sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
    }
    
    
    func initARSessionDefault() {
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // Run the view's session
        configuration.planeDetection = [.horizontal, .vertical]
        sceneView.session.delegate = self
        sceneView.session.run(configuration)
    }
    
    func initARSessionImages() {
        guard let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "ar-data", bundle: nil) else {
            fatalError("Missing expected asset catalog resources.")
        }
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        // Run the view's session
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.detectionImages = referenceImages
        sceneView.session.run(configuration)
    }
    
    
    func updateButtonText(imageDetected: Bool) {
        DispatchQueue.main.async {
            self.detectionBtn.setTitle(imageDetected ? "Reset" : "Start detection", for: .normal)
        }
    }
    
    func toggleTorch(on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        
        if device.hasTorch {
            do {
                try device.lockForConfiguration()
                
                if on {
                    device.torchMode = .on
                } else {
                    device.torchMode = .off
                }
                
                device.unlockForConfiguration()
            } catch {
                print("Torch could not be used")
            }
        } else {
            print("Torch is not available")
        }
    }
    
    @objc func tapGesture(tap: UITapGestureRecognizer) {
        //toggleTorch(on: true)
        //let point = tap.location(in: sceneView)
        //handleHit(to: point)
    }
    
    func handleHit(to point: CGPoint) {
        let hitResults = sceneView.hitTest(point, types: .featurePoint)
        let featurePoints = hitResults.filter { $0.type == ARHitTestResult.ResultType.featurePoint }
        if let result = featurePoints.first {
            addSphere(at: result.worldTransform.position(), size: 0.02)
        }
    }
    
    func addSphere(at pos: SCNVector3, size: CGFloat) {
        let sphere = SCNSphere(radius: size)
        sphere.materials.first?.diffuse.contents = UIColor.green
        let node = SCNNode(geometry: sphere)
        node.name = "balls"
        node.position = pos
        print("position to \(node.position)")
        sceneView.scene.rootNode.addChildNode(node)
    }
    
    
    func setLabel(text: String) {
        DispatchQueue.main.async {
            self.transitionLabel()
            self.topInfoLabel.text = text
        }
    }
    
    func transitionLabel() {
        topInfoLabel.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        
        UIView.animate(withDuration: 2, delay: 0, usingSpringWithDamping: 0.2, initialSpringVelocity: 6, options: .allowUserInteraction, animations: {
            self.topInfoLabel.transform = CGAffineTransform.identity
        }, completion: nil)
    }
    
    func initSwitchBoard(node: SCNNode, size: CGSize) {
        switchboard = SwitchBoard(node: node, size: size)
        
        let row = SwitchBoardRow()
        let singleSwitchSize = CGSize(width: 0.01, height: 0.035)
        
        let topOffset: CGFloat = 0.06
        
        let mainSwitch = Switch(dimension: CGSize(width: 0.025, height: 0.035), position: CGPoint(x: 0.002, y: topOffset), type: .rowSwitch)
        row.rowSwitch = mainSwitch
        
        let offsetLeft: CGFloat = 0.027
        let singleSwitches = [
            Switch(dimension: singleSwitchSize, position: CGPoint(x: offsetLeft, y: topOffset), type: .singleSwitch),
            Switch(dimension: singleSwitchSize, position: CGPoint(x: offsetLeft + singleSwitchSize.width, y: topOffset), type: .singleSwitch),
            Switch(dimension: singleSwitchSize, position: CGPoint(x: offsetLeft + singleSwitchSize.width * 2, y: topOffset), type: .singleSwitch),
            Switch(dimension: singleSwitchSize, position: CGPoint(x: offsetLeft + singleSwitchSize.width * 3, y: topOffset), type: .singleSwitch),
            Switch(dimension: singleSwitchSize, position: CGPoint(x: offsetLeft + singleSwitchSize.width * 4, y: topOffset), type: .singleSwitch),
            Switch(dimension: singleSwitchSize, position: CGPoint(x: offsetLeft + singleSwitchSize.width * 5, y: topOffset), type: .singleSwitch),
            Switch(dimension: singleSwitchSize, position: CGPoint(x: offsetLeft + singleSwitchSize.width * 6, y: topOffset), type: .singleSwitch),
            Switch(dimension: singleSwitchSize, position: CGPoint(x: offsetLeft + singleSwitchSize.width * 9, y: topOffset), type: .singleSwitch),
        ]
        row.switches = singleSwitches
        
        switchboard.add(row: row)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? TitleView {
            vc.delegate = self
        }
    }
}

extension ARViewController: TitleViewDelegate {
    func onTitleBtn() {
        topInfoLabel.isHidden = false
        detectionInitiated = true
        initARSessionImages()
        //toggleTorch(on: true)
    }
}

// MARK: - ARSCNViewDelegate
extension ARViewController: ARSessionDelegate, ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
     
        if detectionInitiated {
            guard let imageAnchor = anchor as? ARImageAnchor else { return }
            imageDetectedAnchor = imageAnchor
            let referenceImage = imageAnchor.referenceImage
            processQueue.async {
                self.handleImageDetected(image: referenceImage, node: node)
            }
        }
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
        
        initSwitchBoard(node: node, size: image.physicalSize)
        setLabel(text: "Levez le disjoncteur sélectionné")
        for row in switchboard.rows {
            row.rowSwitch?.toggleArrow(on: true)
            /*
            row.switches.first?.toggleArrow(on: true)
            let sw = row.switches.first!
            print(sw.dimension, sw.position) */
        }
    }
    
    func createBall(position: SCNVector3, originsize: CGSize, color: UIColor) -> SCNNode {
        let ball = SCNSphere(radius: 0.005)
        let material = SCNMaterial()
        material.diffuse.contents = color
        ball.materials = [material]
        
        let ballNode = SCNNode(geometry: ball)
        ballNode.position = ARHelpers.setPosition(position, forSize: originsize)
        return ballNode
        
    }
    
    
    
    /*
     // Override to create and configure nodes for anchors added to the view's session.
     func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
     let node = SCNNode()
     
     return node
     }
     */
    /*
     func session(_ session: ARSession, didFailWithError error: Error) {
     // Present an error message to the user
     
     }
     
     func sessionWasInterrupted(_ session: ARSession) {
     // Inform the user that the session has been interrupted, for example, by presenting an overlay
     
     }
     
     func sessionInterruptionEnded(_ session: ARSession) {
     // Reset tracking and/or remove existing anchors if consistent tracking is required
     
     }*/
}
