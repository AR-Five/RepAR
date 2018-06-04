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
    case normal, error, unknown
}

enum SwitchStatus {
    case fucked
}

class Switch {
    var dimension: CGSize
    var position: CGPoint
    var type: SwitchType
    
    var state: SwitchState = .unknown
    
    var displayArrow = false
    
    var arrowNode: SCNNode?
    var handNode: SCNNode?
    
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
        arrowNode?.isHidden = !on
        if !arrowNode!.isHidden {
            //            arrowNode?.runAction(hoverAction())
            arrowNode?.runAction(SCNAction.group([hoverAction(), rotateAction()]))
        }
    }
    
    func toggleHand(on: Bool) {
        handNode?.isHidden = !on
        if !handNode!.isHidden {
            //handNode?.childNode(withName: "Armature", recursively: true)?.addAnimation(animations["arm-down"]!, forKey: "arm-down")
        }
    }
    
    func initAllObjects(node: SCNNode, size: CGSize) {
        createArrow(node: node, size: size)
        createHand(node: node, size: size)
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
        return SCNAction.repeat(hover, count: 300)
    }
    
    func rotateAction() -> SCNAction {
        return SCNAction.repeat(
            SCNAction.rotateBy(x: 0, y: 0, z: 2 * .pi, duration: 10),
            count: 300
        )
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
