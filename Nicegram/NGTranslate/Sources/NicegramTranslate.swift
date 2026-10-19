import NaturalLanguage
import NGCore
import SwiftSignalKit

public func nicegramTranslate(
    _ text: String,
    toLang: String
) -> Signal<String, Error> {
    Signal<String, Error>.awaitThrowingOperation {
        try await translateWithFirstWorkingEngine(
            text,
            to: toLang
        )
    }
}

private func translateWithFirstWorkingEngine(
    _ text: String,
    to targetLanguage: String
) async throws -> String {
    let sourceLanguage = detectedLanguage(of: text)
    let engineKinds = await translationEngineOrder(
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage
    )
    for engineKind in engineKinds {
        let translation = try? await engineKind.toEngine().translate(
            text,
            from: sourceLanguage,
            to: targetLanguage
        )
        if let translation {
            return translation
        }
    }
    throw UnexpectedError()
}

private func detectedLanguage(of text: String) -> String? {
    guard let language = NLLanguageRecognizer.dominantLanguage(for: text),
          language != .undetermined else {
        return nil
    }
    return language.rawValue
}
