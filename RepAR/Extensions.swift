//
//  Helpers.swift
//  RepAR
//
//  Created by Guillaume Carré on 29/04/2018.
//  Copyright © 2018 ARFive. All rights reserved.
//

import ARKit


struct ViewsIdentifier {
    static let mainView = "mainAR"
    static let titleView = "mainTitle"
    static let navigationView = "navigationView"
    static let choiceView = "choiceView"
    static let blurTitle = "blurTitle"
}

extension matrix_float4x4 {
    func position() -> SCNVector3 {
        return SCNVector3(columns.3.x, columns.3.y, columns.3.z)
    }
}

extension UIView {
    func show(view: UIView) {
        DispatchQueue.main.async {
            self.subviews.forEach { $0.removeFromSuperview() }
            self.addSubview(view)
            view.frame = self.bounds
        }
    }
    
    func hide(view: UIView) {
        DispatchQueue.main.async {
            view.removeFromSuperview()
        }
    }
}

extension UIViewController {
    func switchTo(vc: UIViewController) {
        view.addSubview(vc.view)
        vc.view.frame = view.bounds
        vc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        vc.didMove(toParentViewController: self)
    }
    
    
    func add(_ child: UIViewController) {
        addChildViewController(child)
        view.addSubview(child.view)
        child.didMove(toParentViewController: self)
    }
    
    func remove() {
        guard parent != nil else {
            return
        }
        willMove(toParentViewController: nil)
        removeFromParentViewController()
        view.removeFromSuperview()
    }
}

extension CAAnimation {
//    class func animationWithSceneNamed(_ name: String) -> CAAnimation? {
//        var animation: CAAnimation?
//        if let scene = SCNScene(named: name) {
//            scene.rootNode.enumerateChildNodes({ (child, stop) in
//                if child.animationKeys.count > 0 {
//                    animation = child.animation(forKey: child.animationKeys.first!)
//                    stop.initialize(to: true)
//                }
//            })
//        }
//        return animation
//    }
}

class ARHelpers {
    
    // transform origin to top left
    static func setPosition(_ position: SCNVector3, forSize size: CGSize) -> SCNVector3 {
        let originX = Float(size.width / 2)
        let originZ = Float(size.height / 2)
        var newPosition = SCNVector3()
        newPosition.x = -originX + position.x
        newPosition.y = 0 + position.y
        newPosition.z = -originZ + position.z
        return newPosition
    }
    
    static func addMmodel(name: String, position: SCNVector3, originsize: CGSize, format: String = "scn") -> SCNNode {
        let modelScene = SCNScene(named: "art.scnassets/\(name).\(format)")!
        let node = modelScene.rootNode.childNode(withName: name, recursively: true)!
        node.position = setPosition(position, forSize: originsize)
        return node
    }
}
