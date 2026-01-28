import AccountContext
import Display
import Postbox
import SwiftSignalKit
import TelegramCore
import TextFormat
import UIKit

struct OpenResolvedUrlParams {
    var resolvedUrl: ResolvedUrl
    let context: AccountContext
    let urlContext: OpenURLContext
    let navigationController: NavigationController?
    let forceExternal: Bool
    let forceUpdate: Bool
    let openPeer: (EnginePeer, ChatControllerInteractionNavigateToPeer) -> Void
    let sendFile: ((FileMediaReference) -> Void)?
    let sendSticker: ((FileMediaReference, UIView, CGRect) -> Bool)?
    let sendEmoji: ((String, ChatTextInputTextCustomEmojiAttribute) -> Void)?
    let requestMessageActionUrlAuth: ((MessageActionUrlSubject) -> Void)?
    let joinVoiceChat: ((PeerId, String?, CachedChannelData.ActiveCall) -> Void)?
    let present: (ViewController, Any?) -> Void
    let dismissInput: () -> Void
    let contentContext: Any?
    let progress: Promise<Bool>?
    let completion: (() -> Void)?
}

@MainActor
func openResolvedUrlImpl(_ params: OpenResolvedUrlParams) {
    openResolvedUrlImpl(params.resolvedUrl, context: params.context, urlContext: params.urlContext, navigationController: params.navigationController, forceExternal: params.forceExternal, forceUpdate: params.forceUpdate, openPeer: params.openPeer, sendFile: params.sendFile, sendSticker: params.sendSticker, sendEmoji: params.sendEmoji, requestMessageActionUrlAuth: params.requestMessageActionUrlAuth, joinVoiceChat: params.joinVoiceChat, present: params.present, dismissInput: params.dismissInput, contentContext: params.contentContext, progress: params.progress, completion: params.completion)
}
