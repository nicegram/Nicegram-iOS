// MARK: Nicegram
import NGTranslate
import NGUI
//
import Foundation
import UIKit
import AsyncDisplayKit
import ContextUI
import Display
import SwiftSignalKit
import Postbox
import TelegramCore
import TelegramNotices
import ChatSendMessageActionUI
import AccountContext

func chatMessageDisplaySendMessageOptions(selfController: ChatControllerImpl, node: ASDisplayNode, gesture: ContextGesture) {
    guard let peerId = selfController.chatLocation.peerId, let textInputView = selfController.chatDisplayNode.textInputView(), let layout = selfController.validLayout else {
        return
    }
    let previousSupportedOrientations = selfController.supportedOrientations
    if layout.size.width > layout.size.height {
        selfController.supportedOrientations = ViewControllerSupportedOrientations(regularSize: .all, compactSize: .landscape)
    } else {
        selfController.supportedOrientations = ViewControllerSupportedOrientations(regularSize: .all, compactSize: .portrait)
    }
    
    let _ = ApplicationSpecificNotice.incrementChatMessageOptionsTip(accountManager: selfController.context.sharedContext.accountManager, count: 4).startStandalone()
    
    var hasEntityKeyboard = false
    if case .media = selfController.presentationInterfaceState.inputMode {
        hasEntityKeyboard = true
    }
    
    let _ = (selfController.context.account.viewTracker.peerView(peerId)
    |> take(1)
    |> deliverOnMainQueue).startStandalone(next: { [weak selfController] peerView in
        guard let selfController, let peer = peerViewMainPeer(peerView) else {
            return
        }
        var sendWhenOnlineAvailable = false
        if let presence = peerView.peerPresences[peer.id] as? TelegramUserPresence, case let .present(until) = presence.status {
            let currentTime = Int32(CFAbsoluteTimeGetCurrent() + kCFAbsoluteTimeIntervalSince1970)
            if currentTime > until {
                sendWhenOnlineAvailable = true
            }
        }
        if peer.id.namespace == Namespaces.Peer.CloudUser && peer.id.id._internalGetInt64Value() == 777000 {
            sendWhenOnlineAvailable = false
        }
        
        if sendWhenOnlineAvailable {
            let _ = ApplicationSpecificNotice.incrementSendWhenOnlineTip(accountManager: selfController.context.sharedContext.accountManager, count: 4).startStandalone()
        }
        
        let controller = ChatSendMessageActionSheetController(context: selfController.context, updatedPresentationData: selfController.updatedPresentationData, peerId: selfController.presentationInterfaceState.chatLocation.peerId, forwardMessageIds: selfController.presentationInterfaceState.interfaceState.forwardMessageIds, hasEntityKeyboard: hasEntityKeyboard, gesture: gesture, sourceSendButton: node, textInputView: textInputView, canSendWhenOnline: sendWhenOnlineAvailable, completion: { [weak selfController] in
            guard let selfController else {
                return
            }
            selfController.supportedOrientations = previousSupportedOrientations
        }, sendMessage: { [weak selfController] mode in
            guard let selfController else {
                return
            }
            switch mode {
            case .generic:
                selfController.controllerInteraction?.sendCurrentMessage(false)
            case .silently:
                selfController.controllerInteraction?.sendCurrentMessage(true)
            case .whenOnline:
                selfController.chatDisplayNode.sendCurrentMessage(scheduleTime: scheduleWhenOnlineTimestamp) { [weak selfController] in
                    guard let selfController else {
                        return
                    }
                    selfController.updateChatPresentationInterfaceState(animated: true, interactive: false, saveInterfaceState: selfController.presentationInterfaceState.subject != .scheduledMessages, {
                        $0.updatedInterfaceState { $0.withUpdatedReplyMessageSubject(nil).withUpdatedForwardMessageIds(nil).withUpdatedForwardOptionsState(nil).withUpdatedComposeInputState(ChatTextInputState(inputText: NSAttributedString(string: ""))) }
                    })
                    selfController.openScheduledMessages()
                }
            }
        }, /* MARK: Nicegram TranslateEnteredMessage (translate + chooseLanguage) */ translate: { [weak selfController] in
            guard let selfController else { return }
            let chatId = selfController.chatLocation.peerId
            let textToTranslate = selfController.presentationInterfaceState.interfaceState.effectiveInputState.inputText.string
            let _ = (translateEnteredText(text: textToTranslate, chatId: chatId, context: selfController.context)
            |> deliverOnMainQueue).start(
                next: { translated in
                    selfController.updateChatPresentationInterfaceState(interactive: true, { state in
                    let newTextInputState = ChatTextInputState(inputText: NSAttributedString(string: translated))
                    return state.updatedInterfaceState { interfaceState in
                        return interfaceState.withUpdatedEffectiveInputState(newTextInputState)
                    }
                })
            }, error: { error in
                let errorDescription: String
                switch error {
                case .toLanguageNotFound:
                    errorDescription = "Messages.TranslateError.ToLanguageNotFound"
                case .translate:
                    errorDescription = "Messages.TranslateError"
                }
                let c = getIAPErrorController(context: selfController.context, errorDescription, selfController.presentationData)
                selfController.controllerInteraction?.presentGlobalOverlayController(c, nil)
            })
        }, chooseLanguage: { [weak selfController] in
            guard let selfController else { return }
            let chatId = selfController.chatLocation.peerId
            let _ = (getLanguageCode(forChatWith: chatId, context: selfController.context)
            |> deliverOnMainQueue).start(next: { code in
                let c = languageListController(context: selfController.context, selectedLanguageCode: code, selectLanguage: { code in
                    setLanguageCode(code, forChatWith: chatId)
                })
                c.navigationPresentation = .modal
                selfController.push(c)
            })
        }, schedule: { [weak selfController] in
            guard let selfController else {
                return
            }
            selfController.controllerInteraction?.scheduleCurrentMessage()
        })
        controller.emojiViewProvider = selfController.chatDisplayNode.textInputPanelNode?.emojiViewProvider
        selfController.sendMessageActionsController = controller
        if layout.isNonExclusive {
            selfController.present(controller, in: .window(.root))
        } else {
            selfController.presentInGlobalOverlay(controller, with: nil)
        }
    })
}
