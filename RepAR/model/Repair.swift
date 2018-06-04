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
    case askSwitchBroken
    case end
}

enum RepairActionStatus {
    case pending, active, done, failed
}

enum RepairViewType {
    case navigation, choices, none
}

struct RepairButtonChoice {
    let id: String
    let title: String
}

class RepairStep {
    let text: String
    let action: RepairAction
    var viewType: RepairViewType = .none
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


class Repair {
    
    static func run() -> RepairStep {
        let goToPanel = RepairStep(text: "Allez à votre panneau électrique", action: .gotoSwitchBoard)
        
        //let chooseMainSwitch = RepairStep(text: "Touchez le/les disjoncteur(s) dont le levier est abaissé", action: .chooseMainSwitch)
        //goToPanel.then(chooseMainSwitch)
        return goToPanel
    }
    
    static func firstCase(row: SwitchBoardRow) -> RepairStep {
        let liftSelectedSwitch = RepairStep(text: "Levez le disjoncteur selectionné", action: .pullLeverUp, currentSwitch: row.rowSwitch, view: .choices)
        
        liftSelectedSwitch.choicesButtonLabel = [
            RepairButtonChoice(id: "failed", title: "Il est redescendu"),
            RepairButtonChoice(id: "ok", title: "Il reste levé"),
            RepairButtonChoice(id: "unknown", title: "Je ne sais pas"),
        ]
        
        let endFirstCase = RepairStep(text: "Votre tableau électrique est opérationnel", action: .end)
        liftSelectedSwitch.then(endFirstCase)
        liftSelectedSwitch.thenIfFailed(secondCase(row: row))
        
        return liftSelectedSwitch
    }
    
    static func secondCase(row: SwitchBoardRow) -> RepairStep {
        let allDown = RepairStep(text: "Abaisser tout les disjoncteurs sélectionnés", action: .pullAllSimpleSwitchDown, view: .navigation)
        let firstOneDown = RepairStep(text: "Remonter le disjoncteur sélectionné", action: .pullLeverUp, currentSwitch: row.rowSwitch, view: .navigation)
        var currentStep = firstOneDown
        
        for sw in row.switches {
            let tryOne = RepairStep(text: "Remontez le disjoncteur sélectionné", action: .pullLeverUp, currentSwitch: sw, view: .navigation)
            let choiceSwitch = RepairStep(text: "Ce disjoncteur a-t-il sauté ?", action: .askSwitchBroken, currentSwitch: sw, view: .choices)
            choiceSwitch.choicesButtonLabel = [
                RepairButtonChoice(id: "yes", title: "Oui"),
                RepairButtonChoice(id: "no", title: "Non"),
            ]
            
            currentStep.then(tryOne)
            tryOne.then(choiceSwitch)
            
            currentStep = choiceSwitch
        }
        
        allDown.then(firstOneDown)
        return allDown
    }
    
    static func endCaseThree() -> RepairStep {
        return RepairStep(text: "Il s'agissait d'un problème ponctuel qui a mis un peu de temps à se résoudre", action: .end)
    }
    
    static func resetCaseThree() -> RepairStep {
        let resetSingleSw = RepairStep(text: "Abaisser ce disjoncteur", action: .pullLeverDown, view: .navigation)
        let mainSwUp = RepairStep(text: "Remonter ce disjoncteur", action: .pullLeverUp, view: .navigation)
        resetSingleSw.then(mainSwUp)
        return resetSingleSw
    }
}
