//
//  NicegramSecureSettings.swift
//  NicegramLib
//
//  Created by Sergey on 27.10.2019.
//  Copyright © 2019 Nicegram. All rights reserved.
//

import Foundation


func setSecureDefaults() {
    if DAKeychain.shared["isPremium"] == nil {
        DAKeychain.shared["isPremium"] = "no"
    }
    if DAKeychain.shared["isBetaPremium"] == nil {
        DAKeychain.shared["isBetaPremium"] = "no"
    }
}

public var PCACHE: String = "no"

public class SecureNiceSettings {
    
    public init() {
        // setSecureDefaults()
    }
    
    public var isPremium: Bool {
        get {
            return DAKeychain.shared["isPremium"] == "yes"
        }
        set {
            if newValue {
                DAKeychain.shared["isPremium"] = "yes"
                PCACHE = "yes"
            } else {
                DAKeychain.shared["isPremium"] = "no"
                PCACHE = "no"
            }
        }
    }
    
    public var isBetaPremium: Bool {
        get {
            return DAKeychain.shared["isBetaPremium"] == "yes"
        }
        set {
            if newValue {
                DAKeychain.shared["isBetaPremium"] = "yes"
            } else {
                DAKeychain.shared["isBetaPremium"] = "no"
            }
        }
    }
    
}
