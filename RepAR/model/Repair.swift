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
    case pullAllSimpleSwitchDown
    case pullLeverUp, pullLeverDown
    case question
    case end
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
    
    var currentSwitch: Switch?
    
    var choicesButtonLabel = [RepairButtonChoice]()
    
    var nextButtonLabel: String? = "Suivant"
    var prevButtonLabel: String? = "Retour"
    
    // previous task
    var prev: RepairStep?
    
    // next task to do
    private var next: RepairStep?
    
    // next task to do if current failed
    private var nextFailed: RepairStep?
    
    func then(_ step: RepairStep) {
        self.next = step
        self.next?.prev = self
    }
    
    func thenIfFailed(_ step: RepairStep) {
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
    
    convenience init(text: String, action: RepairAction, currentSwitch: Switch) {
        self.init(text: text, action: action)
        self.currentSwitch = currentSwitch
    }
}


class Repair {
    
    func run() -> RepairStep {
        let goToPanel = RepairStep(text: "Allez à votre panneau électrique", action: .gotoSwitchBoard)
        let chooseMainSwitch = RepairStep(text: "Touchez le/les disjoncteur(s) dont le levier est abaissé", action: .chooseMainSwitch)
        goToPanel.then(chooseMainSwitch)
        return goToPanel
    }
    
    func firstCase(row: SwitchBoardRow) -> RepairStep {
        let liftSelectedSwitch = RepairStep(text: "Levez le disjoncteur selectionné", action: .pullLeverUp, currentSwitch: row.rowSwitch)
        liftSelectedSwitch.choicesButtonLabel = [
            RepairButtonChoice(id: "down", title: "Il est redescendu"),
            RepairButtonChoice(id: "up", title: "Il reste levé")
        ]
        
        let endFirstCase = RepairStep(text: "Votre tableau électrique est opérationnel", action: .end)
        liftSelectedSwitch.then(endFirstCase)
        liftSelectedSwitch.thenIfFailed(secondCase(row: row))
        
        return liftSelectedSwitch
    }
    
    func secondCase(row: SwitchBoardRow) -> RepairStep {
        let allDown = RepairStep(text: "Abaisser tout les disjoncteurs sélectionnés", action: .pullAllSimpleSwitchDown)
        let firstOneDown = RepairStep(text: "Remonter le disjoncteur sélectionné", action: .pullLeverUp, currentSwitch: row.rowSwitch)
        var lastStep = firstOneDown
        for sw in row.switches {
            let tryOne = RepairStep(text: "Remontez le disjoncteur sélectionné", action: .pullLeverUp, currentSwitch: sw)
            let choiceSwitch = RepairStep(text: "Ce disjoncteur a-t-il sauté ?", action: .question, currentSwitch: sw)
            choiceSwitch.choicesButtonLabel = [
                RepairButtonChoice(id: "yes", title: "Oui"),
                RepairButtonChoice(id: "no", title: "Non"),
            ]
            lastStep.then(tryOne)
            tryOne.then(choiceSwitch)
            
            lastStep = choiceSwitch
        }
        
        allDown.then(firstOneDown)
        return allDown
    }
}
