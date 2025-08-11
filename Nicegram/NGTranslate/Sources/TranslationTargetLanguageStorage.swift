import Foundation

// Nicegram Translate

private let savedTranslationTargetLanguageKey = "ng:savedTranslationTargetLanguage"

func getSavedTranslationTargetLanguage() -> String? {
    return UserDefaults.standard.string(forKey: savedTranslationTargetLanguageKey)
}

func setSavedTranslationTargetLanguage(code: String) {
    UserDefaults.standard.set(code, forKey: savedTranslationTargetLanguageKey)
}
