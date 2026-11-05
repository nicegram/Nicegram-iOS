import AccountContext
import TelegramCore

protocol ChatStateObserver {
    func update(hasTelegramHeaderAd: Bool)
    func update(isScreenVisible: Bool)
    func update(peerView: EngineRawPeerView?)
}

public final class ChatNicegramContext {
    let ads: ChatNicegramAdsContext
    
    private let stateObservers: [ChatStateObserver]
    
    init(accountContext: AccountContext) {
        self.ads = ChatNicegramAdsContext(accountContext: accountContext)
        self.stateObservers = [ ads ]
    }
}

extension ChatNicegramContext: ChatStateObserver {
    func update(hasTelegramHeaderAd: Bool) {
        stateObservers.forEach {
            $0.update(hasTelegramHeaderAd: hasTelegramHeaderAd)
        }
    }
    
    func update(isScreenVisible: Bool) {
        stateObservers.forEach {
            $0.update(isScreenVisible: isScreenVisible)
        }
    }
    
    func update(peerView: EngineRawPeerView?) {
        stateObservers.forEach {
            $0.update(peerView: peerView)
        }
    }
}
