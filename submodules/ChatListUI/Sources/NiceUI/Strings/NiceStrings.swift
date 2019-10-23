//
//  NiceStrings.swift
//  TelegramUI
//
//  Created by Sergey on 10/07/2019.
//  Copyright © 2019 Telegram. All rights reserved.
//

import Foundation

private func gd(locale: String) -> [String : String] {
    return NSDictionary(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "NiceLocalizable", ofType: "strings", inDirectory: nil, forLocalization: locale)!)) as! [String : String]
}

let niceLocales: [String : [String : String]] = [
    "en" : gd(locale: "en"),
    "ru": gd(locale: "ru"),
    "ar": gd(locale: "ar"),
    "de": gd(locale: "de"),
    "it": gd(locale: "it"),
    "es": gd(locale: "es"),
    "uk": gd(locale: "uk"),
    
    // Chinese
    // Simplified
    "zh-hans": gd(locale: "zh-hans"),
    // Traditional
    "zh-hant": gd(locale: "zh-hant"),
    
    "fa": gd(locale: "fa"),
    "pl": gd(locale: "pl"),
    "sk": gd(locale: "sk"),
    "tr": gd(locale: "tr")
]

public func getLangFallback(_ lang: String) -> String {
    switch (lang) {
        case "zh-hant":
            return "zh-hans"
        case "uk":
            return "ru"
        default:
            return "en"
    }
}

public func l(_ key: String, _ locale: String = "en") -> String {
    var lang = locale
    let rawSuffix = "-raw"
    if lang.hasSuffix(rawSuffix) {
        lang = String(lang.dropLast(rawSuffix.count))
    }
    
    if !niceLocales.keys.contains(lang) {
        lang = "en"
    }
    
    var result = "[MISSING STRING]"
    
    if let res = niceLocales[lang]?[key], !res.isEmpty {
        result = res
    } else if let res = niceLocales[getLangFallback(lang)]?[key], !res.isEmpty {
        result = res
    } else if let res = niceLocales["en"]?[key], !res.isEmpty {
        result = res
    } else if !key.isEmpty {
        result = key
    }
    
    return result
}
