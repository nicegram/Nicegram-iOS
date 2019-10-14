//
//  NiceBrowser.swift
//  ChatListUI
//
//  Created by Sergey on 30/09/2019.
//  Copyright © 2019 Nicegram. All rights reserved.
//

import Foundation

public enum Browser:String {
    case Safari = "safari"
    case Chrome = "chrome"
    case Yandex = "yandex"
    case DuckDuckGo = "duckduckgo"
    case Brave = "brave"
    case OpenerOptions = "openeroptions"
    case OpenerAuto = "openerauto"
    case Alook = "alook"
    case Firefox = "firefox"
    case FirefoxFocus = "firefoxfocus"
    case OperaTouch = "operatouch"
    case OperaMini = "operamini"
    case Edge = "edge"
}

public func getBrowserUrl(_ url: String, browser: String) -> String {
    let browserCls = Browser(rawValue: browser) ?? Browser.Safari
    switch browserCls {
        case .Safari:
            return url
        case .Chrome:
            return url.replacingOccurrences(of: "http://", with: "googlechrome://").replacingOccurrences(of: "https://", with: "googlechrome://")
        case .Yandex:
            return "yandexbrowser-open-url://" + url.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        case .DuckDuckGo:
            return "ddgQuickLink://" + url
        case .Brave:
            return "brave://open-url?url=" + url
        case .OpenerOptions:
            return "opener://x-callback-url/show-options?url=" + url.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        case .OpenerAuto:
            return "opener://x-callback-url/show-options?allow-auto-open=false&url=" + url.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        case .Alook:
            return "Alook://" + url
        case .Firefox:
            return "firefox://open-url?url=" + url.addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed)!
        case .FirefoxFocus:
            return "firefox-focus://open-url?url=" + url.addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed)!
        case .OperaTouch:
            return "touch-" + url
        case .OperaMini:
            return "opera-" + url
        case .Edge:
            return "microsoft-edge-" + url
        default:
            return url
    }
}

