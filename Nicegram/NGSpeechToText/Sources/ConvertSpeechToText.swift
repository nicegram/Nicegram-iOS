import AccountContext
import Display
import FeatPremiumUI
import Foundation
import NGCore
import NGData
import Postbox
import TelegramCore

//  MARK: - Public

public func ngConvertSpeechToText(
    context: AccountContext,
    navigationController: NavigationController?,
    message: Message
) async throws {
    let manager = TgSpeechToTextManager(accountContext: context)
    
    let locale = getSavedLocale(message: message) ?? .current
    let mediaFile = try message.media
        .compactMap { $0 as? TelegramMediaFile }
        .first { $0.isVoice }
        .unwrap()
    
    let result = await manager.convertSpeechToText(
        mediaFile: mediaFile,
        source: .apple(locale)
    )
    
    switch result {
    case let .success(success):
        if let confidence = success.confidence, confidence < 0.5 {
            try await selectLocaleAndRetry(context: context, navigationController: navigationController, message: message)
        } else {
            message.updateAudioTranscriptionAttribute(text: success.text, error: nil, context: context)
        }
    case .needsPremium:
        PremiumUITgHelper.routeToPremium(source: .speechToText)
    case .error:
        try await selectLocaleAndRetry(context: context, navigationController: navigationController, message: message)
    }
}

@MainActor
public func ngShowSpeechToTextLocaleSelection(
    context: AccountContext,
    navigationController: NavigationController?,
    message: Message
) async -> Locale? {
    guard let navigationController else { return nil }
    
    let authorId = getAuthorId(message: message)
    
    return await withCheckedContinuation { continuation in
        let controller = recognitionLanguagesController(
            context: context,
            currentLocale: getSavedLocale(message: message),
            onSelect: { locale in
                _ = navigationController.popViewController(animated: true)
                NGSettings.appleSpeechToTextLocale[authorId] = locale
                continuation.resume(returning: locale)
            },
            onCloseWithoutSelect: {
                continuation.resume(returning: nil)
            }
        )
        navigationController.pushViewController(controller, animated: true)
    }
}

//  MARK: - Private

private func getAuthorId(message: Message) -> Int64 {
    (message.author?.id ?? message.id.peerId).toInt64()
}

private func getSavedLocale(message: Message) -> Locale? {
    let authorId = getAuthorId(message: message)
    return NGSettings.appleSpeechToTextLocale[authorId]
}

private func selectLocaleAndRetry(
    context: AccountContext,
    navigationController: NavigationController?,
    message: Message
) async throws {
    let selectedLocale = await ngShowSpeechToTextLocaleSelection(
        context: context,
        navigationController: navigationController,
        message: message
    )
    
    if selectedLocale != nil {
        try await ngConvertSpeechToText(
            context: context,
            navigationController: navigationController,
            message: message
        )
    } else {
        message.updateAudioTranscriptionAttribute(text: "", error: UnexpectedError(), context: context)
    }
}
