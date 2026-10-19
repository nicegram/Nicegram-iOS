protocol TranslationEngine {
    func translate(
        _ text: String,
        from sourceLanguage: String?,
        to targetLanguage: String
    ) async throws -> String
}

enum TranslationEngineKind {
    case google
    case onDevice
}

extension TranslationEngineKind {
    func toEngine() -> any TranslationEngine {
        switch self {
        case .google:
            GoogleTranslationEngine()
        case .onDevice:
            OnDeviceTranslationEngine()
        }
    }
}
