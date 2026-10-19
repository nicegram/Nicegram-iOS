import Foundation
import Translation

func translationEngineOrder(
    sourceLanguage: String?,
    targetLanguage: String
) async -> [TranslationEngineKind] {
    // Every `Translation` symbol must stay behind this check: the framework is weakly linked only
    // while all of them are, and a strong link crashes iOS 15–17.3 at launch.
    guard #available(iOS 18.0, *) else {
        return [.google]
    }
    // No detected source means no on-device attempt: given no source, Apple asks the user to pick one.
    // Nor does a code with no on-device form: Chinese other than Simplified.
    guard let sourceLanguage,
          let source = onDeviceLanguageCode(sourceLanguage),
          let target = onDeviceLanguageCode(targetLanguage) else {
        return [.google]
    }

    let status = await LanguageAvailability().status(
        from: Locale.Language(identifier: source),
        to: Locale.Language(identifier: target)
    )
    switch status {
    case .installed:
        return [.onDevice, .google]
    case .supported:
        // Google first: Apple's download sheet may only ever replace an error, never a working translation.
        return [.google, .onDevice]
    case .unsupported:
        return [.google]
    @unknown default:
        return [.google]
    }
}
