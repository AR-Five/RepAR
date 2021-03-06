//
//  Repair.swift
//  RepAR
//
//  Created by Guillaume Carré on 27/05/2018.
//  Copyright © 2018 ARFive. All rights reserved.
//

import UIKit

enum RepairAction {
    case gotoSwitchBoard
    case chooseMainSwitch
    case pullAllSimpleSwitchDown, pullLeverUp, pullLeverDown
    case askSwitchBroken, askGearConnected, askAllGearTested, checkGear
    case changeLightBulb
    case unplug, plugAll, plugOne
    case end, endContinue, endContinueLoop
}

enum RepairActionStatus {
    case pending, active, done, failed
}

enum RepairViewType {
    case navigation, choices, full, none
}

struct RepairHelp {
    let text: String
    let image: UIImage?
    init(text: String) {
        self.text = text
        self.image = nil
    }
    
    init(text: String, image: UIImage) {
        self.text = text
        self.image = image
    }
}

struct RepairButtonChoice {
    let id: String
    let title: String
    var step: RepairStep?
    init(id: String, title: String) {
        self.id = id
        self.title = title
    }
    init(id: String, title: String, step: RepairStep?) {
        self.init(id: id, title: title)
        self.step = step
    }
}

class RepairStep {
    let text: String
    
    var help: RepairHelp = RepairHelp(text: "Pas d'aide disponible")
    
    let action: RepairAction
    var viewType: RepairViewType = .none
    var status: RepairActionStatus = .pending
    
    var showSwitchIndicator = true
    
    var currentSwitch: Switch?
    
    var choicesButtonLabel = [RepairButtonChoice]()
    var questionId = ""
    
    var nextButtonLabel = "Suivant"
    var prevButtonLabel = "Retour"
    
    // previous task
    var prev: RepairStep?
    
    // next task to do
    private var next: RepairStep?
    
    // next task to do if current failed
    private var nextFailed: RepairStep?
    
    func then(_ step: RepairStep?) {
        self.next = step
        self.next?.prev = self
    }
    
    func thenIfFailed(_ step: RepairStep?) {
        self.nextFailed = step
        self.nextFailed?.prev = self
    }
    
    func getNext() -> RepairStep? {
        return self.next
    }
    
    func getNextFailed() -> RepairStep? {
        return self.nextFailed
    }
    
    init(text: String, action: RepairAction, view: RepairViewType = .none) {
        self.text = text
        self.action = action
        self.viewType = view
    }
    
    convenience init(text: String, action: RepairAction, currentSwitch: Switch, view: RepairViewType = .none) {
        self.init(text: text, action: action, view: view)
        self.currentSwitch = currentSwitch
    }
}
