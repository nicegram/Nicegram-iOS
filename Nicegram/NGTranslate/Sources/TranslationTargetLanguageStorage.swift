import Foundation
import TelegramPresentationData

private let savedTranslationTargetLanguageKey = "ng:savedTranslationTargetLanguage"

public func getPreferredTranslationTargetLanguage(_ presentationData: PresentationData) -> String {
    UserDefaults.standard.string(forKey: savedTranslationTargetLanguageKey) ?? presentationData.strings.baseLanguageCode
}

public func setPreferredTranslationTargetLanguage(code: String) {
    UserDefaults.standard.set(
        code,
        forKey: savedTranslationTargetLanguageKey
    )
}
