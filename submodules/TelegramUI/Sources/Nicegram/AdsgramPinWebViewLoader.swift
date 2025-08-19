import AccountContext
import Factory
import FeatAdsgram
import FeatChatListWidget
import MemberwiseInit
import NGAnalytics
import NGUtils
import Postbox
import SwiftSignalKit
import TelegramCore
import WebUI

@MemberwiseInit
class AdsgramPinWebViewLoader {
    @Init(.internal) private let contextProvider: ContextProvider
    
    @Injected(\AnalyticsContainer.analyticsManager)
    private var analyticsManager
    
    @Injected(\ChatListWidgetModule.chatListWidgetViewModel)
    private var chatListWidgetViewModel
    
    @Injected(\AdsgramModule.getConfigUseCase)
    private var getConfigUseCase
    
    @Injected(\AdsgramModule.getSettingsUseCase)
    private var getSettingsUseCase
}

extension AdsgramPinWebViewLoader {
    func initialize() {
        Task {
            let stream = contextProvider
                .contextPublisher()
                .compactMap { $0 }
                .removeDuplicates { $0.account.id == $1.account.id }
                .asyncStream(.bufferingNewest(1))
            for await context in stream {
                do {
                    try await loadAdsgramWebview(context: context)
                    analyticsManager.trackEvent(AdsgramEvents.loadSuccess)
                } catch {
                    analyticsManager.trackEvent(AdsgramEvents.loadError)
                }
            }
        }
    }
}

private extension AdsgramPinWebViewLoader {
    func loadAdsgramWebview(context: AccountContext) async throws {
        let settings = await getSettingsUseCase()
        guard settings.showPin else { return }
        
        let config = try await getConfigUseCase().unwrap()
        
        let botId = PeerId(
            namespace: Namespaces.Peer.CloudUser,
            id: ._internalFromInt64Value(config.miniApp.botId)
        )
        
        // 'requestAppWebView' method expects that the peer is already loaded
        try await loadPeerIfNeeded(
            context: context,
            username: config.miniApp.botUsername
        )
        
        let presentationData = context.sharedContext.currentPresentationData.with { $0 }
        
        let result = try await context.engine.messages
            .requestAppWebView(
                peerId: botId,
                appReference: .shortName(
                    peerId: botId,
                    shortName: config.miniApp.shortName
                ),
                payload: nil,
                themeParams: generateWebAppThemeParams(presentationData.theme),
                compact: false,
                fullscreen: false,
                allowWrite: false
            )
            .awaitForFirstValue()
        
        await chatListWidgetViewModel.adsgramPinViewModel.load(url: result.url)
    }
    
    func loadPeerIfNeeded(
        context: AccountContext,
        username: String
    ) async throws {
        let signal = context.engine.peers.resolvePeerByName(
            name: username,
            referrer: nil,
            ageLimit: Int32(30 * .day)
        )
        |> mapToSignal { result -> Signal<EnginePeer?, NoError> in
            guard case let .result(result) = result else {
                return .complete()
            }
            return .single(result)
        }
        
        _ = try await signal.awaitForFirstValue()
    }
}
