import NGCore
import SwiftSignalKit
import TelegramCore

struct OnDeviceTranslationEngine: TranslationEngine {}

extension OnDeviceTranslationEngine {
    func translate(
        _ text: String,
        from sourceLanguage: String?,
        to targetLanguage: String
    ) async throws -> String {
        let service = try engineExperimentalInternalTranslationService.unwrap()
        let detectedSource = try sourceLanguage.unwrap()
        let source = try onDeviceLanguageCode(detectedSource).unwrap()
        let target = try onDeviceLanguageCode(targetLanguage).unwrap()
        let key = AnyHashable(0)
        let translations = try await service.translate(
            texts: [key: text],
            fromLang: source,
            toLang: target
        ).awaitForFirstValue()
        let translation = try translations.unwrap()[key].unwrap()
        guard !translation.isEmpty else {
            throw UnexpectedError()
        }
        return translation
    }
}
