//
//  NiceStrings.swift
//  TelegramUI
//
//  Created by Sergey on 10/07/2019.
//  Copyright © 2019 Telegram. All rights reserved.
//

import Foundation
import AppBundle

private func gd(locale: String) -> [String : String] {
    return NSDictionary(contentsOf: URL(fileURLWithPath: getAppBundle().path(forResource: "CNLocalizable", ofType: "strings", inDirectory: nil, forLocalization: locale)!)) as! [String : String]
}

let cnniceLocales: [String : [String : String]] = [
    "en" : gd(locale: "en"),
    // Chinese
    // Simplified
    "zh-hans": gd(locale: "zh-hans"),
    // Traditional
    "zh-hant": gd(locale: "zh-hant"),
]


public func cnl(_ key: String, _ locale: String = "en") -> String {
    var lang = locale
    let rawSuffix = "-raw"
    if lang.hasSuffix(rawSuffix) {
        lang = String(lang.dropLast(rawSuffix.count))
    }
    
    if !cnniceLocales.keys.contains(lang) {
        lang = "en"
    }
    
    var result = "[MISSING STRING]"
    
    if let res = cnniceWebLocales[lang]?[key], !res.isEmpty {
        result = res
    } else if let res = cnniceLocales[lang]?[key], !res.isEmpty {
        result = res
    } else if let res = cnniceLocales[getLangFallback(lang)]?[key], !res.isEmpty {
        result = res
    } else if let res = cnniceLocales["en"]?[key], !res.isEmpty {
        result = res
    } else if !key.isEmpty {
        result = key
    }
    
    return result
}


public func cngetStringsUrl(_ lang: String) -> String {
    return "https://raw.githubusercontent.com/nicegram/Telegram-iOS/china/Telegram-iOS/" + lang + ".lproj/CNLocalizable.strings"
}


var cnniceWebLocales: [String: [String: String]] = [:]

func cngetWebDict(_ lang: String) -> [String : String]? {
    return NSDictionary(contentsOf: URL(string: cngetStringsUrl(lang))!) as? [String : String]
}

public func cndownloadLocale(_ locale: String) -> Void {
    do {
        var lang = locale
        let rawSuffix = "-raw"
        if lang.hasSuffix(rawSuffix) {
            lang = String(lang.dropLast(rawSuffix.count))
        }
        if let localeDict = try cngetWebDict(lang) {
            cnniceWebLocales[lang] = localeDict
            print("DOWNLOADED CN LOCALE \(lang)")
        }
    } catch {
        return
    }
}
