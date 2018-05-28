//
//  Repair.swift
//  RepAR
//
//  Created by Guillaume Carré on 27/05/2018.
//  Copyright © 2018 ARFive. All rights reserved.
//

import UIKit

enum RepairAction {
    case pullLeverUp, pullLeverDown
}

enum RepairActionStatus {
    case pending, active, done, failed
}

struct RepairButtonChoice {
    let id: String
    let title: String
}

class RepairStep {
    let text: String
    let action: RepairAction
    var status: RepairActionStatus = .pending
    
    var choicesButtonLabel = [RepairButtonChoice]()
    
    var nextButtonLabel: String?
    var prevButtonLabel: String?
    
    // previous task
    var prev: RepairStep?
    
    // next task to do
    private var next: RepairStep?
    
    // next task to do if current failed
    private var nextFailed: RepairStep?
    
    func nextStep(_ step: RepairStep) {
        self.next = step
        self.next?.prev = self
    }
    
    func nextStepFailed(_ step: RepairStep) {
        self.nextFailed = step
        self.nextFailed?.prev = self
    }
    
    func getNext() -> RepairStep? {
        return self.next
    }
    
    init(text: String, action: RepairAction) {
        self.text = text
        self.action = action
    }
}


class Repair {
    var id: String
    var firstTask: RepairStep
    init(id: String, firstTask: RepairStep) {
        self.id = id
        self.firstTask = firstTask
    }
}
