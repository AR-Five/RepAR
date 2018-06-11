//
//  RepairAction.swift
//  RepAR
//
//  Created by Guillaume Carré on 08/06/2018.
//  Copyright © 2018 ARFive. All rights reserved.
//

import UIKit

class Repair {
    
    static func run() -> RepairStep {
        let info = RepairStep(text: "Dirigez-vous vers votre tableau électrique", action: .gotoSwitchBoard, view: .full)
        let goToPanel = RepairStep(text: "Visez votre tableau électrique", action: .gotoSwitchBoard)
        //let chooseMainSwitch = RepairStep(text: "Touchez le/les disjoncteur(s) dont le levier est abaissé", action: .chooseMainSwitch)
        //goToPanel.then(chooseMainSwitch)
        info.then(goToPanel)
        return info
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
        let allDown = RepairStep(text: "Abaissez tout les disjoncteurs sélectionnés", action: .pullAllSimpleSwitchDown, view: .navigation)
        let firstOneDown = RepairStep(text: "Remontez le disjoncteur sélectionné", action: .pullLeverUp, currentSwitch: row.rowSwitch, view: .navigation)
        
        var currentStep = firstOneDown
        for sw in row.switches {
            let tryOne = RepairStep(text: "Remontez le disjoncteur sélectionné", action: .pullLeverUp, currentSwitch: sw, view: .navigation)
            let choiceSwitch = RepairStep(text: "Ce disjoncteur a-t-il sauté ?", action: .askSwitchBroken, currentSwitch: sw, view: .choices)
            choiceSwitch.choicesButtonLabel = [
                RepairButtonChoice(id: "yes", title: "Oui"),
                RepairButtonChoice(id: "no", title: "Non"),
            ]
            choiceSwitch.questionId = "case2-mainswitch-broken"
            
            currentStep.then(tryOne)
            tryOne.then(choiceSwitch)
            
            currentStep = choiceSwitch
        }
        
        var cStep: RepairStep? = firstOneDown
        while cStep != nil {
            if cStep!.action == .askSwitchBroken {
                cStep!.thenIfFailed(failedCaseTwo(prev: cStep!.currentSwitch, c: cStep!.getNext(), row: row))
            }
            cStep = cStep!.getNext()
        }
        
        
        allDown.then(firstOneDown)
        return allDown
    }
    
    static func endCaseTwo() -> RepairStep {
        return RepairStep(text: "Il s'agissait d'un problème ponctuel qui a mis un peu de temps à se résoudre", action: .end)
    }
    
    static func failedCaseTwo(prev: Switch?, c: RepairStep?, row: SwitchBoardRow) -> RepairStep {
        let resetSingleSw = RepairStep(text: "Abaissez ce disjoncteur", action: .pullLeverDown, view: .navigation)
        resetSingleSw.currentSwitch = prev
        let mainSwUp = RepairStep(text: "Remontez ce disjoncteur", action: .pullLeverUp, view: .navigation)
        mainSwUp.currentSwitch = row.rowSwitch
        
        resetSingleSw.then(mainSwUp)
        if let step = c {
            mainSwUp.then(step)
        }
        return resetSingleSw
    }
    
    static func askEquipment(prev: RepairStep, row: SwitchBoardRow) -> RepairStep? {
        var current = prev
        for sw in row.switches.filter({ $0.state == SwitchState.error }) {
            let askGear = RepairStep(text: "A quel(s) appareil ce disjoncteur est-il relié ?", action: .askGearConnected, view: .choices)
            askGear.currentSwitch = sw
            askGear.choicesButtonLabel = [
                RepairButtonChoice(id: "lightbulb", title: "Ampoule", step: lightbulbCase(askGear)),
                RepairButtonChoice(id: "socket", title: "Prise"),
            ]
            
            current.then(askGear)
            current = askGear
        }
        return prev.getNext()
    }
    
    static func lightbulbCase(_ step: RepairStep) -> RepairStep {
        let changeLightBulb = RepairStep(text: "Changez l'ampoule", action: .changeLightBulb, view: .navigation)
        let pullUpMain = RepairStep(text: "Remontez ce disjoncteur", action: .pullLeverUp, view: .navigation)
        let end = RepairStep(text: "Appelez un électricien", action: .endContinue, view: .none)
        pullUpMain.currentSwitch = step.currentSwitch
        step.then(changeLightBulb)
        changeLightBulb.then(pullUpMain)
        pullUpMain.questionId = "end-change-equip"
        pullUpMain.then(end)
        return changeLightBulb
    }
    
    static func thirdCase(prev: RepairStep, row: SwitchBoardRow) -> RepairStep {
        var current = prev
        for sw in row.switches.filter({ $0.attachedGear.contains(.socket) }) {
            let unplug = RepairStep(text: "Débranchez tout les appareils reliés à ce disjoncteur", action: .unplug, view: .navigation)
            unplug.currentSwitch = sw
            let pullUp = RepairStep(text: "Remontez le disjoncteur sélectionné", action: .pullLeverUp, view: .navigation)
            pullUp.currentSwitch = sw
            
            let ask = RepairStep(text: "Ce disjoncteur a-t-il sauté ?", action: .askSwitchBroken, view: .choices)
            ask.choicesButtonLabel = [
                RepairButtonChoice(id: "yes", title: "Oui"),
                RepairButtonChoice(id: "no", title: "Non")
            ]
            ask.currentSwitch = sw
            
            unplug.then(pullUp)
            pullUp.then(ask)
            current = ask
        }
        return current
    }
    
    static func thirdCaseBranchOneFailed(sw: Switch, next: RepairStep, row: SwitchBoardRow) -> RepairStep {
        let first = RepairStep(text: "Débranchez l'équipement que vous venez de brancher a ce disjoncteur, puis branchez en un nouveau", action: .unplug, view: .navigation)
        first.currentSwitch = sw
        let sec = RepairStep(text: "Remontez le disjoncteur sélectionné", action: .pullLeverUp, view: .navigation)
        sec.currentSwitch = row.rowSwitch
        
        first.then(sec)
        sec.then(next)
        return first
    }
}
