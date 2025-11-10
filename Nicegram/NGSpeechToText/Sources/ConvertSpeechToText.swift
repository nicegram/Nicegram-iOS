import Foundation
import TelegramCore
import ChatControllerInteraction
import Postbox
import FeatPremiumUI
import AccountContext
import TelegramPresentationData
import NGData
import NGUI
import NGStrings

private let getSpeech2TextSettingsUseCase = NicegramSettingsModule.shared.getSpeech2TextSettingsUseCase()

public enum SpeechToTextMessageSource {
    case chat, contextMenu
}

public func convertSpeechToText(
    from source: SpeechToTextMessageSource = .chat,
    languageStyle: RecognitionLanguagesControllerStyle = .normal,
    context: AccountContext,
    mediaFile: TelegramMediaFile,
    message: Message?,
    presentationData: PresentationData,
    controllerInteraction: ChatControllerInteraction,
    completion: (() -> Void)? = nil,
    closeWithoutSelect: (() -> Void)? = nil
) {
    guard let message else {
        completion?()
        return
    }
    
    let accountId = context.account.peerId.id._internalGetInt64Value()
    let authorId = (message.author?.id ?? message.id.peerId).toInt64()

    let useOpenAI = getSpeech2TextSettingsUseCase.useOpenAI(with: accountId)
    
    checkPremium { isPremium in
        if isPremium &&
            useOpenAI {
            startConvertSpeechToTextTask(
                from: source,
                context: context,
                mediaFile: mediaFile,
                source: .openAI,
                message: message,
                presentationData: presentationData,
                controllerInteraction: controllerInteraction,
                completion: completion
            )
        } else {
            let locale = NGSettings.appleSpeechToTextLocale[authorId] ?? Locale.current

            if languageStyle == .normal {
                startConvertSpeechToTextTask(
                    from: source,
                    context: context,
                    mediaFile: mediaFile,
                    source: .apple(locale),
                    message: message,
                    presentationData: presentationData,
                    controllerInteraction: controllerInteraction,
                    completion: completion
                )
            } else {
                let appleSpeechToTextLocale = NGSettings.appleSpeechToTextLocale
                let currentLocale = appleSpeechToTextLocale[authorId]

                showLanguages(
                    with: context,
                    controllerInteraction: controllerInteraction,
                    style: languageStyle,
                    currentLocale: currentLocale
                ) { locale in
                    var appleSpeechToTextLocale = NGSettings.appleSpeechToTextLocale
                    appleSpeechToTextLocale[authorId] = locale
                    NGSettings.appleSpeechToTextLocale = appleSpeechToTextLocale
                    
                    _ = controllerInteraction.navigationController()?.popViewController(animated: true)
                    startConvertSpeechToTextTask(
                        from: source,
                        context: context,
                        mediaFile: mediaFile,
                        source: .apple(locale),
                        message: message,
                        presentationData: presentationData,
                        controllerInteraction: controllerInteraction,
                        completion: completion
                    )
                } selectWhisper: {
                    _ = controllerInteraction.navigationController()?.popViewController(animated: true)
                    
                    if (isPremium) {
                        controllerInteraction.navigationController()?.pushViewController(premiumController(context: context))
                    } else {
                        PremiumUITgHelper.routeToPremium(
                            source: .settings
                        )
                    }
                } closeWithoutSelect: {
                    closeWithoutSelect?()
                }
            }
        }
    }
}

private func showLanguages(
    with context: AccountContext,
    controllerInteraction: ChatControllerInteraction,
    style: RecognitionLanguagesControllerStyle = .normal,
    currentLocale: Locale?,
    selectLocale: @escaping (Locale) -> Void,
    selectWhisper: @escaping () -> Void,
    closeWithoutSelect: @escaping () -> Void
) {
    let controller = recognitionLanguagesController(
        context: context,
        style: style,
        currentLocale: currentLocale,
        selectLocale: selectLocale,
        selectWhisper: selectWhisper,
        closeWithoutSelect: closeWithoutSelect
    )
    controller.navigationPresentation = .modal
    
    controllerInteraction.navigationController()?.pushViewController(controller, animated: true)
}

private func startConvertSpeechToTextTask(
    from messageSource: SpeechToTextMessageSource,
    context: AccountContext,
    mediaFile: TelegramMediaFile,
    source: TgSpeechToTextManager.Source,
    message: Message?,
    presentationData: PresentationData,
    controllerInteraction: ChatControllerInteraction,
    completion: (() -> Void)? = nil
) {
    Task { @MainActor in
        let manager = TgSpeechToTextManager(
            accountContext: context
        )
        
        if messageSource == .contextMenu {
            message?.setSpeechToTextLoading(context: context)
        }
        
        let result = await manager.convertSpeechToText(
            mediaFile: mediaFile,
            source: source
        )
        
        switch result {
        case .success(let text):
            switch messageSource {
            case .chat:
                message?.updateAudioTranscriptionAttribute(text: text, error: nil, context: context)
            case .contextMenu:
                message?.setSpeechToTextTranslation(text, context: context)
            }
        case .needsPremium:
            PremiumUITgHelper.routeToPremium(
                source: .speechToText
            )
        case .error(let error):
            switch error {
            case .recognition(_):
                if messageSource == .contextMenu {
                    message?.removeSpeechToTextMeta(context: context)
                }
                convertSpeechToText(
                    from: messageSource,
                    languageStyle: .whisper,
                    context: context,
                    mediaFile: mediaFile,
                    message: message,
                    presentationData: presentationData,
                    controllerInteraction: controllerInteraction
                )
            case .notAvailable:
                if messageSource == .contextMenu {
                    message?.removeSpeechToTextMeta(context: context)
                }
                let c = getIAPErrorController(
                    context: context,
                    l("NicegramSpeechToText.NotAvailable"),
                    presentationData
                )
                controllerInteraction.presentGlobalOverlayController(c, nil)
            case .authorizationStatus:
                if messageSource == .contextMenu {
                    message?.removeSpeechToTextMeta(context: context)
                }
                let c = getIAPErrorController(
                    context: context,
                    l("NicegramSpeechToText.AuthorisationError"),
                    presentationData
                )
                controllerInteraction.presentGlobalOverlayController(c, nil)
            case let .api(error):
                switch messageSource {
                case .chat:
                    message?.updateAudioTranscriptionAttribute(text: "", error: error, context: context)
                case .contextMenu:
                    message?.removeSpeechToTextMeta(context: context)
                }
                
                let c = getIAPErrorController(
                    context: context,
                    error.localizedDescription,
                    presentationData
                )
                controllerInteraction.presentGlobalOverlayController(c, nil)
            case let .other(error):
                switch messageSource {
                case .chat:
                    message?.updateAudioTranscriptionAttribute(text: "", error: error, context: context)                    
                case .contextMenu:
                    message?.removeSpeechToTextMeta(context: context)
                }
                
                let c = getIAPErrorController(
                    context: context,
                    error.localizedDescription,
                    presentationData
                )
                controllerInteraction.presentGlobalOverlayController(c, nil)
            }
        }
        
        completion?()
    }
}
