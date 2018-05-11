//
//  Helpers.swift
//  RepAR
//
//  Created by Guillaume Carré on 29/04/2018.
//  Copyright © 2018 ARFive. All rights reserved.
//

import ARKit

extension matrix_float4x4 {
    func position() -> SCNVector3 {
        return SCNVector3(columns.3.x, columns.3.y, columns.3.z)
    }
}

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        return sqrt(pow(abs(point.x - self.x), 2) + pow(abs(point.y - self.y), 2))
    }
}

func sizeAspectFit(aspectRatio: CGSize, boundingSize: CGSize) -> CGSize {
    var aspectFitSize = CGSize(width: boundingSize.width, height: boundingSize.height)
    let mW = boundingSize.width / aspectRatio.width
    let mH = boundingSize.height / aspectRatio.height
    if mH < mW {
        aspectFitSize.width = mH * aspectRatio.width
    } else if mW < mH {
        aspectFitSize.height = mW * aspectRatio.height
    }
    return aspectFitSize
}

func scaleImageToRect(image: UIImage, size: CGSize) -> CGRect {
    var scaledImageRect = CGRect.zero;
    
    let aspectRatio: CGFloat = min(size.width / image.size.width, size.height / image.size.height)
    
    scaledImageRect.size.width = image.size.width * aspectRatio
    scaledImageRect.size.height = image.size.height * aspectRatio
    scaledImageRect.origin.x = (size.width - scaledImageRect.size.width) / 2.0
    scaledImageRect.origin.y = (size.height - scaledImageRect.size.height) / 2.0
    return scaledImageRect
}

func scaleUIImageToSize(image: UIImage, size: CGSize) -> UIImage? {
    
    var scaledImageRect = scaleImageToRect(image: image, size: size)
    let hasAlpha = false
    let scale: CGFloat = 0.0 // Automatically use scale factor of main screen
    
    UIGraphicsBeginImageContextWithOptions(size, !hasAlpha, scale)
    image.draw(in: scaledImageRect)
    
    let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return scaledImage
}

extension UIImage {
    
    func resize(toTargetSize targetSize: CGSize) -> UIImage {
        // inspired by Hamptin Catlin
        // https://gist.github.com/licvido/55d12a8eb76a8103c753
        
        let newScale = self.scale // change this if you want the output image to have a different scale
        let originalSize = self.size
        
        let widthRatio = targetSize.width / originalSize.width
        let heightRatio = targetSize.height / originalSize.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        let newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: floor(originalSize.width * heightRatio), height: floor(originalSize.height * heightRatio))
        } else {
            newSize = CGSize(width: floor(originalSize.width * widthRatio), height: floor(originalSize.height * widthRatio))
        }
        var cX: CGFloat = 0
        var cY: CGFloat = 0
        if originalSize.width > originalSize.height {
            // landscape
            cX = (originalSize.width - originalSize.height) / 2.0
            cY = 0.0
        } else if (originalSize.height >= originalSize.width) {
            // portrait
            cX = 0.0
            cY = (originalSize.height - originalSize.width) / 2.0
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(origin: .init(x: cX, y: cY), size: newSize)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        let format = UIGraphicsImageRendererFormat()
        format.scale = newScale
        format.opaque = true
        let newImage = UIGraphicsImageRenderer(bounds: rect, format: format).image() { _ in
            self.draw(in: rect)
        }
        
        return newImage
    }
}
