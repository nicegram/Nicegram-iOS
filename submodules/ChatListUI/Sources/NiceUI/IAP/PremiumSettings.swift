//
//  PremiumSettings.swift
//  NicegramPremium
//
//  Created by Sergey on 23.10.2019.
//  Copyright © 2019 Nicegram. All rights reserved.
//

//import Foundation
//import AvatarNode
//
//public func setPremiumDefaults() {
//    let UD = UserDefaults(suiteName: "PremiumSettings")
//    UD?.register(defaults: ["syncPins": true])
//}
//
//
//public class PremiumSettings {
//    let UD = UserDefaults(suiteName: "PremiumSettings")
//    
//    public init() {
//        setPremiumDefaults()
//    }
//    
//    public var syncPins: Bool {
//        get {
//            return UD?.bool(forKey: "syncPins") ?? true
//        }
//        set {
//            UD?.set(newValue, forKey: "syncPins")
//        }
//    }
//    
//}
//
//
//
//public func isPremium() -> Bool {
//    return NGAPISETTINGS().PREMIUM
//}
