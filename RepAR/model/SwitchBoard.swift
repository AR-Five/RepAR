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

enum SwitchStatus {
    case fucked
}

class Switch {
    var dimension: CGSize
    var position: CGPoint
    var type: SwitchType
    
    var displayArrow = false
    
    var arrowNode: SCNNode?
    
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
    
    func createArrow(node: SCNNode, size: CGSize) {
        let pos = labelPosition(offset: 0.02) // offset 2cm
        let arrowNode = ARHelpers.addMmodel(name: "arrow", position: pos, originsize: size)
        node.addChildNode(arrowNode)
        arrowNode.isHidden = true
        self.arrowNode = arrowNode
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
}

class SwitchBoardRow {
    var rowSwitch: Switch!
    var switches = [Switch]()
}

class SwitchBoard {
    public var rows = [SwitchBoardRow]()
    
    private var physicalSize: CGSize
    private var node: SCNNode
    
    init(node: SCNNode, size: CGSize) {
        self.node = node
        self.physicalSize = size
        setup()
    }
    
    func setup() {
        let row = SwitchBoardRow()
        
        let singleSwitchSize = CGSize(width: 0.01, height: 0.035)
        let topOffset: CGFloat = 0.06
        let offsetLeft: CGFloat = 0.027
        
        let mainSwitch = Switch(dimension: CGSize(width: 0.025, height: 0.035), position: CGPoint(x: 0.002, y: topOffset), type: .rowSwitch)
        row.rowSwitch = mainSwitch
        
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
        add(row: row)
    }
    
    func add(row: SwitchBoardRow) {
        row.rowSwitch.createArrow(node: node, size: physicalSize)
        row.switches.forEach { $0.createArrow(node: node, size: physicalSize) }
        rows.append(row)
    }
}
