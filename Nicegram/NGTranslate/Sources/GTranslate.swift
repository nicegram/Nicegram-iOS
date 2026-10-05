//
//  GTranslate.swift
//  NicegramLib
//
//  Created by Sergey Akentev on 20.11.2019.
//  Copyright © 2019 Nicegram. All rights reserved.
//

import Foundation
import SwiftSignalKit
import NGLogging
import TelegramPresentationData

fileprivate let LOGTAG = extractNameFromPath(#file)

public var gTranslateSeparator = "🗨 GTranslate"

public func getPreferredTranslationTargetLanguage(_ presentationData: PresentationData) -> String {
    return getSavedTranslationTargetLanguage() ?? presentationData.strings.baseLanguageCode
}

public func setPreferredTranslationTargetLanguage(code: String) {
    setSavedTranslationTargetLanguage(code: code)
}

// Only RFC 3986 unreserved characters survive unescaped. `urlQueryAllowed` keeps `&`, `+` and `=`,
// which the endpoint would then read as query syntax instead of as part of the text.
private let translateQueryAllowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._~"))

private func escapeForQuery(_ value: String) -> String {
    return value.addingPercentEncoding(withAllowedCharacters: translateQueryAllowed) ?? ""
}

public func getTranslateUrl(_ message: String, _ toLang: String) -> String {
    return "https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=\(escapeForQuery(toLang))&dt=t&q=\(escapeForQuery(message))"
}

public func parseTranslateResponse(_ data: Data) -> String {
    // Shape: [[["translated", "source", …], …], …]. Longer input comes back split into one chunk
    // per sentence, so every chunk has to be joined back together.
    guard let root = (try? JSONSerialization.jsonObject(with: data)) as? [Any],
          let chunks = root.first as? [Any] else {
        ngLog("Unexpected translate response format", LOGTAG)
        return ""
    }

    return chunks
        .compactMap { ($0 as? [Any])?.first as? String }
        .joined()
}

public func getGoogleLang(_ userLang: String) -> String {
    var lang = userLang
    let rawSuffix =  "-raw"
    if lang.hasSuffix(rawSuffix) {
        lang = String(lang.dropLast(rawSuffix.count))
    }
    lang = lang.lowercased()
    
    // Google lang for Chineses
    switch (lang) {
        case "zh-hans", "zh":
            return "zh-CN"
        case "zh-hant":
            return "zh-TW"
        default:
            break
    }
    
    
    // Fix for pt-br and other non Chinese langs
    // https://cloud.google.com/translate/docs/languages
    lang = lang.components(separatedBy: "-")[0].components(separatedBy: "_")[0]
    
    return lang
}


public enum TranslateFetchError {
    case network
}


public func requestTranslateUrl(url: URL) -> Signal<Data, TranslateFetchError> {
    return Signal { subscriber in
        let completed = Atomic<Bool>(value: false)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let downloadTask = URLSession.shared.dataTask(with: request, completionHandler: { data, response, _ in
            let _ = completed.swap(true)
            guard let response = response as? HTTPURLResponse,
                  response.statusCode == 200,
                  let data else {
                subscriber.putError(.network)
                return
            }
            subscriber.putNext(data)
            subscriber.putCompletion()
        })
        downloadTask.resume()
        
        return ActionDisposable {
            if !completed.with({ $0 }) {
                downloadTask.cancel()
            }
        }
    }
}


public func gtranslate(_ text: String, _ toLang: String) -> Signal<String, TranslateFetchError> {
    guard let url = URL(string: getTranslateUrl(text, getGoogleLang(toLang))) else {
        return .fail(.network)
    }
    
    return requestTranslateUrl(url: url)
    |> mapToSignal { data -> Signal<String, TranslateFetchError> in
        let result = parseTranslateResponse(data)
        if result.isEmpty {
            return .fail(.network)
        }
        return .single(result)
    }
}
