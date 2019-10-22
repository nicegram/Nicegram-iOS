//
//  PremiumSettings.swift
//  NicegramPremium
//
//  Created by Sergey on 23.10.2019.
//  Copyright © 2019 Nicegram. All rights reserved.
//

import Foundation

public func setPremiumDefaults() {
    let UD = UserDefaults(suiteName: "PremiumSettings")
}


public class PremiumSettings {
    let UD = UserDefaults(suiteName: "PremiumSettings")
    
    public init() {
        setPremiumDefaults()
    }
    
}
