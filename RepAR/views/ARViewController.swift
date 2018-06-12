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
    @IBOutlet var mainView: UIView!
    
    private let processQueue = DispatchQueue.global(qos: .userInitiated)
    
    var imageDetected = false
    var imageDetectedAnchor: ARImageAnchor?
    
    var detectionInitiated = false
    
    lazy var mainTitle: TitleViewController = {
        return storyboard?.instantiateViewController(withIdentifier: ViewsIdentifier.titleView) as! TitleViewController
    }()
    
    lazy var mainAR: MainARViewController = {
       return storyboard?.instantiateViewController(withIdentifier: ViewsIdentifier.mainView) as! MainARViewController
    }()
    
    func setupDelegates() {
        mainAR.delegate = self
        mainTitle.delegate = self
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        definesPresentationContext = true
        
        setupDelegates()
        
//        mainView.show(view: mainTitle.view)
        
//        switchTo(vc: mainTitle)
        add(mainTitle)
        
//        present(mainTitle, animated: true, completion: nil)
        
//        let tapgesture = UITapGestureRecognizer(target: self, action: #selector(self.tapGesture))
        
//        view.addGestureRecognizer(tapgesture)
        
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
        sceneView.session.run(configuration, options: [.removeExistingAnchors])
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? TitleViewController {
            vc.delegate = self
        }
    }
}

extension ARViewController: TitleViewDelegate {
    func onTitleBtn() {
        mainTitle.remove()
//        switchTo(vc: mainAR)
        add(mainAR)
//        toggleTorch(on: true)
    }
}

extension ARViewController: MainARDelegate {
    func onDisplayMenu(sender: UIViewController) {
        performSegue(withIdentifier: "popoverMenu", sender: sender)
    }
    
    func onReset() {
        
        initARSessionDefault()
        mainAR.remove()
        add(self.mainTitle)
//        switchTo(vc: mainTitle)
    }
    
    func onStartDetection() {
        detectionInitiated = true
        initARSessionImages()
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
                self.mainAR.handleImageDetected(image: referenceImage, node: node)
            }
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
    
}
