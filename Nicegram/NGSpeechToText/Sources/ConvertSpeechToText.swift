import Foundation
import TelegramCore
import ChatControllerInteraction
import Postbox
import FeatPremiumUI
import AccountContext
import TelegramPresentationData
import NGData
import NGUI

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
    var id: Int64?
    if let peer = message?.peers.toDict().first?.value {
        switch EnginePeer(peer) {
        case let .channel(channel):
            id = channel.id.toInt64()
        case let .legacyGroup(group):
            id = group.id.toInt64()
        case let .user(user):
            id = user.id.toInt64()
        default:
            return
        }
    }
    
    guard let id else {
        completion?()
        return
    }

    checkPremium { isPremium in
        if isPremium &&
           NGSettings.useOpenAI {
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
            let locale = NGSettings.appleSpeechToTextLocale[id] ?? Locale.current

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
                let currentLocale = appleSpeechToTextLocale[id]

                showLanguages(
                    with: context,
                    controllerInteraction: controllerInteraction,
                    style: languageStyle,
                    currentLocale: currentLocale
                ) { locale in
                    var appleSpeechToTextLocale = NGSettings.appleSpeechToTextLocale
                    appleSpeechToTextLocale[id] = locale
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
                    "Speech to text recognizer not available.",
                    presentationData
                )
                controllerInteraction.presentGlobalOverlayController(c, nil)
            case .authorizationStatus:
                if messageSource == .contextMenu {
                    message?.removeSpeechToTextMeta(context: context)
                }
                let c = getIAPErrorController(
                    context: context,
                    "Speech to text recognizer autorization status error.",
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
