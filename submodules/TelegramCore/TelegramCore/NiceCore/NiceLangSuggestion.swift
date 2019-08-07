//
//  NiceLangSuggestion.swift
//  TelegramCore
//
//  Created by Sergey on 07/08/2019.
//  Copyright © 2019 Nicegram. All rights reserved.
//

import Foundation

public let niceLocalizations: [LocalizationInfo] = [
    LocalizationInfo(languageCode: "zhcncc", baseLanguageCode: "zh-hans-raw", customPluralizationCode: "zh", title: "Chinese (Simplified) @congcong", localizedTitle: "简体中文 (聪聪)", isOfficial: false, totalStringCount: 3178, translatedStringCount: 3173, platformUrl: "https://translations.telegram.org/zhcncc/"),
    LocalizationInfo(languageCode: "taiwan", baseLanguageCode: "zh-hant-raw", customPluralizationCode: "zh", title: "Chinese (zh-Hant-TW)", localizedTitle: "正體中文", isOfficial: false, totalStringCount: 3178, translatedStringCount: 3173, platformUrl: "https://translations.telegram.org/taiwan/")
]

public func trySuggestLang() -> String {
    if let _ = Locale.current.languageCode {
        if let scriptCode = Locale.current.scriptCode {
            switch (scriptCode.lowercased()) {
            case "hans":
                return "zhcncc"
            case "hant":
                return "taiwan"
            default:
                return "en"
            }
        }
    }
    if let regionCode = Locale.current.regionCode {
        switch(regionCode.lowercased()) {
        case "cn":
            return "zhcncc"
        case "hk", "tw":
            return "taiwan"
        default:
            return "en"
        }
    }
    return "en"
}
