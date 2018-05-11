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
    
    var currentImage: UIImage?
    var currentRawImage: UIImage?
    
    private let semaphore = DispatchSemaphore(value: 2)
    private let processQueue = DispatchQueue.global(qos: .userInitiated)
    
    private let cv = CVWrapper()
    
    var featurePoints: [CGPoint]?
    var isTracking = false
    
    var timer: Timer?
    
    var frame: ARFrame?
    
    var initialized = false
    
    var resizedToProcess: UIImage?
    
    var imageDetected = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
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
        guard let trackingTimer = timer else {
            setupTimer()
            return
        }
        
        if !isTracking && trackingTimer.isValid {
            trackingTimer.invalidate()
        } else if isTracking && !trackingTimer.isValid {
            setupTimer()
        }
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
    
    func setupTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            DispatchQueue.main.async {
                guard let image = self.convertARFrameToUIImage(frame: self.frame) else  { return }
                self.processQueue.async {
                    //                var cgImage: CGImage?
                    //                guard let frame = self.frame else { return }
                    //                VTCreateCGImageFromCVPixelBuffer(frame.capturedImage, nil, &cgImage)
                    
                    print("detecting image")
                    self.detectElectricDrawer(image: image)
                }
            }
        }
    }
    
    @objc func tapGesture(tap: UITapGestureRecognizer) {
        
        //toggleTorch(on: true)
        
        let point = tap.location(in: sceneView)
        handleHit(to: point)
        //if let image = currentRawImage {
        /*if !isTracking {
         cv.processImage(image, andSave: true)
         }*/
        //isTracking = !isTracking
        //}
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
    
    func convertARFrameToUIImage(frame: ARFrame?) -> UIImage? {
        guard let newFrame = frame else { return nil }
        let orient = UIApplication.shared.statusBarOrientation
        let viewportSize = sceneView.bounds.size
        let transform = newFrame.displayTransform(for: orient, viewportSize: viewportSize).inverted()
        let finalImage = CIImage(cvPixelBuffer: newFrame.capturedImage).transformed(by: transform)
        
        let temporaryContext = CIContext(options: nil)
        guard let temporaryImage = temporaryContext.createCGImage(finalImage, from: finalImage.extent) else { return nil }
        
        /*guard let newFrame = frame else { return nil }
        var cgImage: CGImage?
        
        VTCreateCGImageFromCVPixelBuffer(newFrame.capturedImage, nil, &cgImage)
        guard let image = cgImage else { return nil }*/
        return UIImage(cgImage: temporaryImage)
    }
    
    //    func displayImage(image: UIImage?) {
    //        cameraPreview.image = image
    //    }
    
    
    //    func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage {
    //
    //        let scale = newWidth / image.size.width
    //        let newHeight = image.size.height * scale
    //        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
    //        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
    //        let newImage = UIGraphicsGetImageFromCurrentImageContext()
    //        UIGraphicsEndImageContext()
    //
    //        return newImage!
    //    }
    //
    
    func processImage(image: UIImage, bbox: CGRect) {
        featurePoints = cv.processImage(image, boundingBox: bbox) as? [CGPoint]
        print("image successfully processed: \(featurePoints?.count ?? 0) feature points found")
        /*if isTracking {
            annotations = cv.getBoundingBox(forFrame: image) as? [CGPoint]
        } else {
            annotations = cv.processImage(image, andSave: false) as? [CGPoint]
        }*/
    }
    
    func detectElectricDrawer(image: UIImage) {
        semaphore.wait()
        
        guard let annotations = cv.getBoundingBox(forFrame: image) as? [CGPoint] else {
            semaphore.signal()
            return
        }
        
        print("detected points", annotations)
        for fp in annotations {
            if annotations[0].distance(to: annotations[2]) > 30 {
                let hitResults = frame?.hitTest(fp, types: .featurePoint)
                if let result = hitResults?.first {
                    print("found point")
                    addSphere(at: result.worldTransform.position(), size: 0.02)
                }
            }
        }
        
        
        semaphore.signal()
        
        isTracking = false
        timer?.invalidate()
        updateButtonText()
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if let view = segue.destination as? PreviewViewController {
            view.featurePoints = featurePoints
            view.imageToPreview = resizedToProcess
        }
    }
    
    //    func draw(points: [CGPoint], onImage image: UIImage) -> UIImage? {
    //        UIGraphicsBeginImageContext(image.size)
    //        image.draw(at: CGPoint.zero)
    //
    //        let gContext = UIGraphicsGetCurrentContext()!
    //
    //        gContext.setFillColor(UIColor.red.cgColor)
    //        gContext.setAlpha(0.5)
    //        for p in points {
    //            gContext.addEllipse(in: CGRect(x: p.x, y: p.y, width: 10, height: 10))
    //            gContext.drawPath(using: .fill)
    //        }
    //
    //        let myImage = UIGraphicsGetImageFromCurrentImageContext()
    //        UIGraphicsEndImageContext()
    //
    //        return myImage
    //    }
    //
    //    func draw(box points: [CGPoint], onImage image: UIImage) -> UIImage? {
    //        UIGraphicsBeginImageContext(image.size)
    //        image.draw(at: CGPoint.zero)
    //
    //        let gContext = UIGraphicsGetCurrentContext()!
    //
    //        gContext.setStrokeColor(UIColor.blue.cgColor)
    //        gContext.setLineWidth(2)
    //
    //        if let fp = points.first {
    //            gContext.move(to: CGPoint(x: fp.x, y: fp.y))
    //
    //            for i in 0..<points.count-1 {
    //                gContext.addLine(to: CGPoint(x: points[i+1].x, y: points[i+1].y))
    //                gContext.strokePath()
    //                gContext.move(to: CGPoint(x: points[i+1].x, y: points[i+1].y))
    //            }
    //
    //            gContext.addLine(to: CGPoint(x: fp.x, y: fp.y))
    //            gContext.strokePath()
    //        }
    //
    //        let myImage = UIGraphicsGetImageFromCurrentImageContext()
    //        UIGraphicsEndImageContext()
    //
    //        return myImage
    //    }
    
    
    
    
    
}

extension ARViewController: FrameExtractorDelegate {
    func captured(image: UIImage) {
        
        //currentRawImage = image
        //tick += 1
        
        //if tick % 2 == 0 {
        /*DispatchQueue.global().async { [unowned self] in
            self.semaphore.wait()
            self.processImage(image: image)
            DispatchQueue.main.async {
                print("image processed")
                self.semaphore.signal()
            }
            //print("Found \(featurePoints?.count) points.")
        }*/
        //}
        
        
        //        if let annot = annotations {
        //            if isTracking {
        //                let annotImage = self.draw(box: annot, onImage: image)
        //                self.displayImage(image: annotImage)
        //
        //            } else {
        //                let annotImage = self.draw(points: annot, onImage: image)
        //                self.displayImage(image: annotImage)
        //            }
        //        } else {
        //            self.displayImage(image: image)
        //        }
        
        //displayImage(image: image)
        
        //            for (index, val) in (featurePoints as! [NSValue]).enumerated() {
        //                let point = val.cgPointValue
        //                print("Point #\(index) x: \(point.x) y: \(point.y)")
        //            }
    }
}

// MARK: - ARSCNViewDelegate
extension ARViewController: ARSessionDelegate, ARSCNViewDelegate {
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        self.frame = frame
        
        if !initialized {
            DispatchQueue.main.async {
                guard let image = self.convertARFrameToUIImage(frame: frame) else { return }
                let imageToScale = #imageLiteral(resourceName: "tableau-elec-large")
                guard let imageToProcess = scaleUIImageToSize(image: imageToScale, size: image.size) else { return }
                    //#imageLiteral(resourceName: "tableau-elec-large").resize(toTargetSize: image.size)
                self.resizedToProcess = imageToProcess
                self.processQueue.async {
                    let bbox = scaleImageToRect(image: imageToScale, size: image.size)
                    self.processImage(image: imageToProcess, bbox: bbox)
                }
            }
        }
        initialized = true
        
        /*
        if isTracking {
            processQueue.async { [unowned self] in
                self.semaphore.wait()
                
                var cgImage: CGImage?
                VTCreateCGImageFromCVPixelBuffer(frame.capturedImage, nil, &cgImage)
                guard let image = cgImage else { return }
                
                self.processImage(image: UIImage(cgImage: image))
                print("image processed")
                self.semaphore.signal()
                //print("Found \(featurePoints?.count) points.")
            }
        }*/
    }
    
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
