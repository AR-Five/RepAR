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
    }
    
    func createArrow(node: SCNNode, size: CGSize) {
        let pos = labelPosition(offset: 0.02) // offset 2cm
        let arrowNode = ARHelpers.addMmodel(name: "arrow", position: pos, originsize: size)
        node.addChildNode(arrowNode)
        arrowNode.isHidden = true
        self.arrowNode = arrowNode
    }
}

class SwitchBoardRow {
    var rowSwitch: Switch?
    var switches = [Switch]()
}

class SwitchBoard {
    var rows = [SwitchBoardRow]()
    
    var physicalSize: CGSize
    var node: SCNNode
    
    init(node: SCNNode, size: CGSize) {
        self.node = node
        self.physicalSize = size
    }
    
    func add(row: SwitchBoardRow) {
        row.rowSwitch?.createArrow(node: node, size: physicalSize)
        row.switches.forEach { $0.createArrow(node: node, size: physicalSize) }
        rows.append(row)
    }
}
