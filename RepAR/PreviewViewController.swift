//
//  PreviewViewController.swift
//  RepAR
//
//  Created by Guillaume Carré on 01/05/2018.
//  Copyright © 2018 ARFive. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class PreviewViewController: UIViewController {
    @IBOutlet var imagePreview: UIImageView!
    
    
    public var featurePoints: [CGPoint]?
    public var imageToPreview: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePreview.image = imageToPreview
        
        //detectRectangles()
        
        if let image = imagePreview.image {
            print("width: \(image.size.width * image.scale)")
            print("height: \(image.size.height * image.scale)")
        }
        
        drawFeaturePoints()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
//    func offset(point: CGPoint) -> CGPoint? {
//        var newPoint: CGPoint
//        guard let image = imagePreview.image else { return nil }
//        let size = sizeAspectFit(aspectRatio: image.size, boundingSize: imagePreview.frame.size)
//        let scale = size.width / image.size.width
//
//        let dY = (imagePreview.frame.size.height - size.height) / 2
//        let dX = (imagePreview.frame.size.width - size.width) / 2
//
//        newPoint.x = dX + (point.x / image.scale) * scale
//        newPoint.y = dX + (point.y / image.scale) * scale
//        return newPoint
//    }
    
    func drawFeaturePoints() {
        imagePreview.layer.sublayers?.removeAll()
        if let points = featurePoints {
            guard let image = imagePreview.image else { return }
            let size = sizeAspectFit(aspectRatio: image.size, boundingSize: imagePreview.frame.size)
            let scale = size.width / image.size.width
            let pointSize: CGFloat = 10
            
            let dY = (imagePreview.frame.size.height - size.height) / 2
            let dX = (imagePreview.frame.size.width - size.width) / 2
            
            for p in points {
                let layer = CAShapeLayer()
                let x = dX + (p.x / image.scale) * scale
                let y = dY + (p.y / image.scale) * scale
                let point = UIBezierPath(ovalIn: CGRect(x: x, y: y, width: pointSize, height: pointSize))
                layer.path = point.cgPath
                layer.fillColor = UIColor.red.cgColor
                imagePreview.layer.addSublayer(layer)
            }
            
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
