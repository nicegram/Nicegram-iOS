import Foundation
import NGCore
import NGLogging

private let logTag = extractNameFromPath(#file)

// Only RFC 3986 unreserved characters survive unescaped. `urlQueryAllowed` keeps `&`, `+` and `=`,
// which the endpoint would then read as query syntax instead of as part of the text.
private let unreservedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._~"))

struct GoogleTranslationEngine: TranslationEngine {}

extension GoogleTranslationEngine {
    // `sourceLanguage` goes unused on purpose: Google detects the source itself (`sl=auto`).
    func translate(
        _ text: String,
        from sourceLanguage: String?,
        to targetLanguage: String
    ) async throws -> String {
        let url = try makeUrl(
            text: text,
            targetLanguage: googleLanguageCode(targetLanguage)
        )
        let (data, response) = try await URLSession.shared.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw UnexpectedError()
        }
        let translation = try parseTranslation(from: data)
        guard !translation.isEmpty else {
            throw UnexpectedError()
        }
        return translation
    }
}

private extension GoogleTranslationEngine {
    func googleLanguageCode(_ code: String) -> String {
        switch normalizedLanguageCode(code) {
        case "zh", "zh-hans":
            return "zh-CN"
        case "zh-hant":
            return "zh-TW"
        default:
            // Google takes base codes for everything but Chinese: https://cloud.google.com/translate/docs/languages
            return baseLanguageCode(code)
        }
    }

    func makeUrl(
        text: String,
        targetLanguage: String
    ) throws -> URL {
        let query = try [
            "client=gtx",
            "sl=auto",
            "tl=\(percentEncoded(targetLanguage))",
            "dt=t",
            "q=\(percentEncoded(text))",
        ].joined(separator: "&")
        return try URL(string: "https://translate.googleapis.com/translate_a/single?\(query)").unwrap()
    }

    // Shape: [[["translated", "source", …], …], …]. Longer input comes back split into one chunk
    // per sentence, so every chunk has to be joined back together.
    func parseTranslation(from data: Data) throws -> String {
        guard let root = (try? JSONSerialization.jsonObject(with: data)) as? [Any],
              let chunks = root.first as? [Any] else {
            ngLog("Unexpected translate response format", logTag)
            throw UnexpectedError()
        }
        return chunks
            .compactMap { ($0 as? [Any])?.first as? String }
            .joined()
    }

    func percentEncoded(_ value: String) throws -> String {
        try value.addingPercentEncoding(withAllowedCharacters: unreservedCharacters).unwrap()
    }
}
