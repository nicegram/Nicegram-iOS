import Postbox

protocol ChatStateObserver {
    func update(hasTelegramHeaderAd: Bool)
    func update(hasTelegramMessageAd: Bool)
    func update(isScreenVisible: Bool)
    func update(peerView: PeerView?)
}

public final class ChatNicegramContext {
    let ads = ChatNicegramAdsContext()
    
    private var stateObservers: [ChatStateObserver] {
        [ads]
    }
}

extension ChatNicegramContext: ChatStateObserver {
    func update(hasTelegramHeaderAd: Bool) {
        stateObservers.forEach {
            $0.update(hasTelegramHeaderAd: hasTelegramHeaderAd)
        }
    }
    
    func update(hasTelegramMessageAd: Bool) {
        stateObservers.forEach {
            $0.update(hasTelegramMessageAd: hasTelegramMessageAd)
        }
    }
    
    func update(isScreenVisible: Bool) {
        stateObservers.forEach {
            $0.update(isScreenVisible: isScreenVisible)
        }
    }
    
    func update(peerView: PeerView?) {
        stateObservers.forEach {
            $0.update(peerView: peerView)
        }
    }
}
