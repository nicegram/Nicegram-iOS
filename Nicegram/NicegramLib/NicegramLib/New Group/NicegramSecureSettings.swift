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

private var _PCACHE: String = "Lakat Matatag"
public var PCACHE: String {
    get {
        if !["Lakat Matatag", "Normalin Normalin"].contains(_PCACHE) {
            preconditionFailure("Hey hacker")
        }
        return _PCACHE
    }
    
    set {
        if !["Lakat Matatag", "Normalin Normalin"].contains(newValue) {
            preconditionFailure("Hey hacker")
        }
        _PCACHE = newValue
    }
}

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
                PCACHE = "Normalin Normalin"
            } else {
                DAKeychain.shared["isPremium"] = "no"
                PCACHE = "Lakat Matatag"
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
