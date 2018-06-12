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
            
            askGear.questionId = "case2-ask-gear"
            
            current.then(askGear)
            current = askGear
        }
        return prev.getNext()
    }
    
    static func lightbulbCase(_ step: RepairStep) -> RepairStep {
        let changeLightBulb = RepairStep(text: "Changez l'ampoule", action: .changeLightBulb, view: .navigation)
        let pullUpMain = RepairStep(text: "Remontez ce disjoncteur", action: .pullLeverUp, view: .navigation)
        let isWorking = RepairStep(text: "Le disjoncteur est-il tombé ?", action: .askSwitchBroken, view: .choices)
        isWorking.currentSwitch = step.currentSwitch
        isWorking.questionId = "case2-mainswitch-broken" //"case2-ask-lightbulb"
        let end = RepairStep(text: "Appelez un électricien", action: .endContinue)
        end.currentSwitch = step.currentSwitch
        end.questionId = "case2-lightbulb-issue"
        
        isWorking.choicesButtonLabel = [
            RepairButtonChoice(id: "yes", title: "Oui", step: end),
            RepairButtonChoice(id: "no", title: "Non")
        ]
        
        pullUpMain.currentSwitch = step.currentSwitch
        step.then(changeLightBulb)
        changeLightBulb.then(pullUpMain)
        pullUpMain.then(isWorking)
        return changeLightBulb
    }
    
    static func thirdCase(step: RepairStep, row: SwitchBoardRow) -> RepairStep? {
        let checkGear = RepairStep(text: "Regardez sous ce disjoncteur pour voir l'équipement ou la pièce reliée.", action: .checkGear, view: .navigation)
        checkGear.currentSwitch = step.currentSwitch
        let unplug = RepairStep(text: "Débranchez tout les appareils reliés à ce disjoncteur", action: .unplug, view: .navigation)
        unplug.currentSwitch = step.currentSwitch
        
        let pullUp = RepairStep(text: "Remontez le disjoncteur sélectionné", action: .pullLeverUp, view: .navigation)
        pullUp.currentSwitch = step.currentSwitch
        
        let plug = RepairStep(text: "Branchez un des équipements qui était relié a ce disjoncteur", action: .plugOne, view: .navigation)
        plug.currentSwitch = step.currentSwitch
        
        let ask = RepairStep(text: "Ce disjoncteur a-t-il sauté ?", action: .askSwitchBroken, view: .choices)
        ask.choicesButtonLabel = [
            RepairButtonChoice(id: "yes", title: "Oui", step: thirdCaseBranchOneFailed(sw: step.currentSwitch, next: checkGear, row: row)),
            RepairButtonChoice(id: "no", title: "Non", step: askMoreGearAttached(sw: step.currentSwitch, next: checkGear, row: row))
        ]
        ask.currentSwitch = row.rowSwitch
        
        step.then(checkGear)
        checkGear.then(unplug)
        unplug.then(pullUp)
        pullUp.then(plug)
        plug.then(ask)
        
        return step.getNext()
    }
    
    static func askMoreGearAttached(sw: Switch?, next: RepairStep?, row: SwitchBoardRow) -> RepairStep? {
        let ask = RepairStep(text: "Est-ce que tout les équipements ont été testés ?", action: .askAllGearTested, view: .choices)
        ask.choicesButtonLabel = [
            RepairButtonChoice(id: "yes", title: "Oui", step: allGearTested(sw: sw, row: row)),
            RepairButtonChoice(id: "no", title: "Non", step: next),
        ]
        ask.currentSwitch = sw
        return ask
    }
    
    static func thirdCaseBranchOneFailed(sw: Switch?, next: RepairStep?, row: SwitchBoardRow) -> RepairStep? {
        let first = RepairStep(text: "Débranchez l'équipement que vous venez de brancher à ce disjoncteur, puis branchez en un nouveau", action: .unplug, view: .navigation)
        first.currentSwitch = sw
        let sec = RepairStep(text: "Remontez le disjoncteur sélectionné", action: .pullLeverUp, view: .navigation)
        sec.currentSwitch = row.rowSwitch
        
        let socketIssue = RepairStep(text: "Le problème provient de la prise. Il faut appeler un électricien.", action: .endContinueLoop, view: .full)
        socketIssue.then(askMoreGearAttached(sw: sw, next: next, row: row))
        socketIssue.questionId = "case3-socketissue"
        socketIssue.currentSwitch = sw
        
        let firstGearIssue = RepairStep(text: "Le problème provient du premier équipement testé, il va falloir le changer.", action: .endContinueLoop, view: .full)
        firstGearIssue.then(askMoreGearAttached(sw: sw, next: next, row: row))
        firstGearIssue.questionId = "case3-firstgearissue"
        firstGearIssue.currentSwitch = sw
        
        let ask = RepairStep(text: "Ce disjoncteur a-t-il sauté ?", action: .askSwitchBroken, view: .choices)
        ask.choicesButtonLabel = [
            RepairButtonChoice(id: "yes", title: "Oui", step: socketIssue),
            RepairButtonChoice(id: "no", title: "Non", step: firstGearIssue),
        ]
        ask.currentSwitch = row.rowSwitch
        
        first.then(sec)
        sec.then(ask)
        return first
    }
    
    static func allGearTested(sw: Switch?, row: SwitchBoardRow) -> RepairStep? {
        let plugAll = RepairStep(text: "Rebranchez tout les équipements", action: .plugAll, view: .navigation)
        let ask = RepairStep(text: "Ce disjoncteur a-t-il sauté ?", action: .askSwitchBroken, view: .choices)
        
        let tempIssue = RepairStep(text: "Si ce phénomène se reproduit, il faut appeler un électricien.", action: .endContinue)
        tempIssue.questionId = "case3-end"
        tempIssue.currentSwitch = sw
        
        let tooMuchGear = RepairStep(text: "Il y a trop d'équipements reliés au même endroit. Il faut diminuer le nombre d'équipements.", action: .endContinue)
        tooMuchGear.questionId = "case3-end"
        tooMuchGear.currentSwitch = sw
        
        ask.choicesButtonLabel = [
            RepairButtonChoice(id: "yes", title: "Oui", step: tooMuchGear),
            RepairButtonChoice(id: "no", title: "Non", step: tempIssue),
        ]
        ask.currentSwitch = row.rowSwitch
        plugAll.then(ask)
        return plugAll
    }
}
