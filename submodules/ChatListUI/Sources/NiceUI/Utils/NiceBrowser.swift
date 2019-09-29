//
//  NiceBrowser.swift
//  ChatListUI
//
//  Created by Sergey on 30/09/2019.
//  Copyright © 2019 Nicegram. All rights reserved.
//

import Foundation

public enum Browser:Int32 {
    case Safari
    case Chrome
    case Yandex
    case DuckDuckGo
    case Firefox
    case FirefoxFocus
    case OperaTouch
    case OperaMini
    case Edge
}

public func getBrowserUrl(_ url: String, browser: Int32) -> String{
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

