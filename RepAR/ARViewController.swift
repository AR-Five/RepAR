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
    //private let frameExtractor = FrameExtractor()
    
    private let semaphore = DispatchSemaphore(value: 2)
    private let processQueue = DispatchQueue.global(qos: .userInitiated)
    
    var isTracking = false
    
    var imageDetected = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIApplication.shared.statusBarStyle = .lightContent
        
        let tapgesture = UITapGestureRecognizer(target: self, action: #selector(self.tapGesture))
        
        view.addGestureRecognizer(tapgesture)
        
        //frameExtractor.delegate = self
        
        
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.autoenablesDefaultLighting = true

        
        // Show statistics such as fps and timing information
        //sceneView.showsStatistics = true
        
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        // Create a new scene
        //        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        // Set the scene to the view
        //        sceneView.scene = scene
        
        //processImage(image: #imageLiteral(resourceName: "tableau-elec-large"))
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "ar-data", bundle: nil) else {
            fatalError("Missing expected asset catalog resources.")
        }
        
        

        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        // Run the view's session
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.detectionImages = referenceImages
        sceneView.session.delegate = self
        sceneView.session.run(configuration)
        
        
        //frameExtractor.start()
    }
    
    @IBAction func toggleTracking(_ sender: UIButton) {
        isTracking = !isTracking
        updateButtonText()
    }
    
    
    func updateButtonText() {
        DispatchQueue.main.async {
            self.detectionBtn.setTitle(self.isTracking ? "Stop detection" : "Start detection", for: .normal)
        }
    }
    
    func toggleTorch(on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        
        if device.hasTorch {
            do {
                try device.lockForConfiguration()
                
                if on == true {
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    @objc func tapGesture(tap: UITapGestureRecognizer) {
        //toggleTorch(on: true)
        let point = tap.location(in: sceneView)
        handleHit(to: point)
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
        node.position = pos
        print("position to \(node.position)")
        sceneView.scene.rootNode.addChildNode(node)
    }
}

// MARK: - ARSCNViewDelegate
extension ARViewController: ARSessionDelegate, ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
     
        guard let imageAnchor = anchor as? ARImageAnchor else { return }
        let referenceImage = imageAnchor.referenceImage
        if !imageDetected {
            processQueue.async {
                // Create a plane to visualize the initial position of the detected image.
                let plane = SCNPlane(width: referenceImage.physicalSize.width,
                                     height: referenceImage.physicalSize.height)
                plane.firstMaterial?.diffuse.contents = UIColor.yellow
                let planeNode = SCNNode(geometry: plane)
                planeNode.opacity = 0.25
                
                /*
                 `SCNPlane` is vertically oriented in its local coordinate space, but
                 `ARImageAnchor` assumes the image is horizontal in its local space, so
                 rotate the plane to match.
                 */
                planeNode.eulerAngles.x = -.pi / 2
                
                let ballNode = self.createBall(position: SCNVector3(0.015, 0, 0.11), originsize: referenceImage.physicalSize, color: UIColor.red)
                node.addChildNode(ballNode)
                
                let ballNode1 = self.createBall(position: SCNVector3(0.035, 0, 0.11), originsize: referenceImage.physicalSize, color: UIColor.green)
                node.addChildNode(ballNode1)
                
                
                // Add the plane visualization to the scene.
                node.addChildNode(planeNode)
                
                print("detected")
                self.imageDetected = true
            }
        }
    }
    
    func createBall(position: SCNVector3, originsize: CGSize, color: UIColor) -> SCNNode {
        let ball = SCNSphere(radius: 0.005)
        let material = SCNMaterial()
        material.diffuse.contents = color
        ball.materials = [material]
        
        let ballNode = SCNNode(geometry: ball)
        ballNode.position = self.setPosition(position: position, originalSize: originsize)
        return ballNode
    }
    
    func setPosition(position: SCNVector3, originalSize: CGSize) -> SCNVector3 {
        let originX = Float(-originalSize.width / 2)
        let originZ = Float(-originalSize.height / 2)
        var newPosition = SCNVector3()
        newPosition.x = originX + position.x
        newPosition.y = 0 + position.y
        newPosition.z = originZ + position.z
        return newPosition
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
