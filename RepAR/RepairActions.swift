//
//  RepairActions.swift
//  RepAR
//
//  Created by Guillaume Carré on 29/05/2018.
//  Copyright © 2018 ARFive. All rights reserved.
//

import UIKit


func setupRepair() -> Repair {
    
    let rep11 = RepairStep(text: "Allez à votre panneau électrique", action: .gotoSwitchBoard)
    let rep12 = RepairStep(text: "Levez le disjoncteur selectionné", action: .pullLeverUp)
    rep12.choicesButtonLabel = [
        RepairButtonChoice(id: "down", title: "Il est redescendu"),
        RepairButtonChoice(id: "up", title: "Il reste levé")
    ]
    let rep13 = RepairStep(text: "Votre tableau électrique est opérationnel", action: .end)
    
    return Repair()
}
