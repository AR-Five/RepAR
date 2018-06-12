//
//  SwitchBoard.swift
//  RepAR
//
//  Created by Guillaume Carré on 12/05/2018.
//  Copyright © 2018 ARFive. All rights reserved.
//

import UIKit
import ARKit

enum SwitchType {
    case rowSwitch, singleSwitch
}

enum SwitchState {
    case normal, error, unknown, unfixable
}

enum Gear {
    case lightBulb, socket
}

class Switch {
    var dimension: CGSize
    var position: CGPoint
    var type: SwitchType
    
    var attachedGear = [Gear]()
    
    var state: SwitchState = .unknown
    
    var displayArrow = false
    
    var arrowNode: SCNNode?
    var handNode: SCNNode?
    var statusNode: SCNNode?
    
    init(dimension: CGSize, position: CGPoint, type: SwitchType) {
        self.dimension = dimension
        self.position = position
        self.type = type
    }
    
    func labelPosition(offset: CGFloat) -> SCNVector3 {
        let x = position.x + dimension.width / 2
        let z = position.y + dimension.height + offset
        return SCNVector3(x, 0, z)
    }
    
    func toggleArrow(on: Bool) {
        guard let aNode = arrowNode else {return}
        aNode.isHidden = !on
        if !aNode.isHidden {
            //            arrowNode?.runAction(hoverAction())
            aNode.runAction(SCNAction.group([hoverAction(), rotateAction()]))
        }
    }
    
    func toggleStatus(on: Bool) {
        guard let sNode = statusNode else { return }
        sNode.isHidden = !on
        if !sNode.isHidden {
            updateStatus()
        }
    }
    
    func updateStatus() {
        guard let sNode = statusNode else { return }
        var color = UIColor.green
        switch state {
        case .error:
            color = UIColor.red
            break
        case .unknown:
            color = #colorLiteral(red: 0.2862745098, green: 0.2862745098, blue: 0.2862745098, alpha: 1)
            break
        case .unfixable:
            color = UIColor.orange
            break
        default:
            break
        }
        sNode.geometry?.materials.first?.diffuse.contents = color
    }
    
    func toggleHand(on: Bool) {
        guard let hNode = handNode else { return }
        hNode.isHidden = !on
        if !hNode.isHidden {
            //handNode?.childNode(withName: "Armature", recursively: true)?.addAnimation(animations["arm-down"]!, forKey: "arm-down")
        }
    }
    
    func initAllObjects(node: SCNNode, size: CGSize) {
        createArrow(node: node, size: size)
        createHand(node: node, size: size)
        createStatusBall(node: node, size: size)
    }
    
    
    func createStatusBall(node: SCNNode, size: CGSize) {
        let ball = SCNSphere(radius: 0.005)
        let defaultColor = #colorLiteral(red: 0.9921568627, green: 1, blue: 0.1333333333, alpha: 1)
        ball.materials.first?.diffuse.contents = defaultColor
        ball.materials.first?.specular.contents = UIColor.lightGray
        let ballNode = SCNNode(geometry: ball)
        ballNode.position = ARHelpers.setPosition(labelPosition(offset: -0.005), forSize: size)
        node.addChildNode(ballNode)
        ballNode.isHidden = true
        self.statusNode = ballNode
    }
    
    func createArrow(node: SCNNode, size: CGSize) {
        let pos = labelPosition(offset: 0.02) // offset 2cm
        let arrowNode = ARHelpers.addMmodel(name: "arrow", position: pos, originsize: size, format: "dae")
        node.addChildNode(arrowNode)
        arrowNode.isHidden = true
        self.arrowNode = arrowNode
    }
    
    func createHand(node: SCNNode, size: CGSize) {
        let pos = labelPosition(offset: -0.03)
        let handNode = ARHelpers.addMmodel(name: "arm-down", position: pos, originsize: size)
        node.addChildNode(handNode)
        handNode.isHidden = true
        
//        let armDownAnimation = CAAnimation.animationWithSceneNamed("art.scnassets/arm-anim1.dae")!
//        let armtr = handNode.childNode(withName: "Armature", recursively: true)!
//        armtr.addAnimation(armDownAnimation, forKey: "arm-anim1-1")
        
        //loadAnimation(withKey: "ArmDown", sceneName: "art.scnassets/arm-down", animationIdentifier: "arm-down")

        self.handNode = handNode
    }
    
    func hoverAction() -> SCNAction {
        let hover = SCNAction.sequence([
            SCNAction.moveBy(x: 0, y: 0, z: 0.002, duration: 1),
            SCNAction.moveBy(x: 0, y: 0, z: -0.002, duration: 1),
            SCNAction.moveBy(x: 0, y: 0, z: -0.002, duration: 1),
            SCNAction.moveBy(x: 0, y: 0, z: 0.002, duration: 1),
            ])
        return SCNAction.repeatForever(hover)
    }
    
    func rotateAction() -> SCNAction {
        return SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 0, z: 2 * .pi, duration: 10))
    }
    /*
    func loadAnimation(withKey: String, sceneName: String, animationIdentifier:String) {
        let sceneURL = Bundle.main.url(forResource: sceneName, withExtension: "scn")
        let sceneSource = SCNSceneSource(url: sceneURL!, options: nil)
        
        if let animationObject = sceneSource?.entryWithIdentifier(animationIdentifier, withClass: CAAnimation.self) {
            // The animation will only play once
            animationObject.repeatCount = 1
            // To create smooth transitions between animations
            animationObject.fadeInDuration = CGFloat(1)
            animationObject.fadeOutDuration = CGFloat(0.5)
            
            // Store the animation for later use
            animations[withKey] = animationObject
        }
    }*/
}

class SwitchBoardRow {
    var rowSwitch: Switch!
    var switches = [Switch]()
}

class SwitchBoard {
    public var rows = [SwitchBoardRow]()
    
    private var physicalSize: CGSize
    private var node: SCNNode
    
    public var singleSwitchSize: CGSize!
    public var mainSwitchSize: CGSize!
    public var topOffset: CGFloat!
    
    init(node: SCNNode, size: CGSize) {
        self.node = node
        self.physicalSize = size
        setup()
    }
    
    func setup() {
        topOffset = 0.06
        mainSwitchSize = CGSize(width: 0.025, height: 0.035)
        singleSwitchSize = CGSize(width: 0.013, height: 0.035)
        
        var row = SwitchBoardRow()
        addSwitch(type: .rowSwitch, to: &row)
        addSwitch(type: .singleSwitch, to: &row, position: 0)
        addSwitch(type: .singleSwitch, to: &row, position: 1)
        addSwitch(type: .singleSwitch, to: &row, position: 2)
        addSwitch(type: .singleSwitch, to: &row, position: 3)
        addSwitch(type: .singleSwitch, to: &row, position: 4)
        addSwitch(type: .singleSwitch, to: &row, position: 5)
        addSwitch(type: .singleSwitch, to: &row, position: 6)
        addSwitch(type: .singleSwitch, to: &row, position: 10)
        
        add(row: row)
    }
    
    func add(row: SwitchBoardRow) {
        row.rowSwitch.initAllObjects(node: node, size: physicalSize)
        row.switches.forEach { $0.initAllObjects(node: node, size: physicalSize) }
        rows.append(row)
    }
    
    func hideAllHints() {
        for row in rows {
            row.rowSwitch.toggleArrow(on: false)
            row.rowSwitch.toggleHand(on: false)
            row.switches.forEach {
                $0.toggleArrow(on: false)
                $0.toggleHand(on: false)
            }
        }
    }
    
    func addSwitch(type: SwitchType, to row: inout SwitchBoardRow, position: CGFloat = 0) {
        if type == .singleSwitch {
            let origin = CGPoint(x: 0.002 + mainSwitchSize.width + singleSwitchSize.width * position, y: topOffset)
            row.switches.append(Switch(dimension: singleSwitchSize, position: origin, type: .singleSwitch))
        }
        if type == .rowSwitch {
            let origin = CGPoint(x: 0.002, y: topOffset)
            row.rowSwitch = Switch(dimension: singleSwitchSize, position: origin, type: .rowSwitch)
        }
    }
}
