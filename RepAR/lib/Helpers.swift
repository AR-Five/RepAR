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
    
    static func addMmodel(name: String, position: SCNVector3, originsize: CGSize) -> SCNNode {
        let modelScene = SCNScene(named: "art.scnassets/\(name).dae")!
        let node = modelScene.rootNode.childNode(withName: name, recursively: true)!
        node.position = setPosition(position, forSize: originsize)
        return node
    }
}
