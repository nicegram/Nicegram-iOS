import protocol Combine.Publisher
import FeatSensitiveContentAccess
import Postbox
import SwiftSignalKit
import TelegramCore

extension ChatControllerImpl {
    func observeRestrictionInfo() {
        updateSupplementViewModelWhenNeeded()
        reloadChatWhenNeeded()
    }
}

private extension ChatControllerImpl {
    func updateSupplementViewModelWhenNeeded() {
        guard let peerId = chatLocation.peerId else { return }
        
        restrictedChatInfoPublisher(peerId: peerId)
            .sink { [weak self] chatInfo in
                self?.chatDisplayNode.restrictedChatSupplementViewModel.update(
                    chatInfo: chatInfo
                )
            }
            .store(in: &cancellables)
    }
    
    func reloadChatWhenNeeded() {
        guard let peerId = chatLocation.peerId else { return }
        
        restrictedChatInfoPublisher(peerId: peerId)
            .map { $0?.restrictionReasons.isEmpty ?? true }
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] _ in
                guard let self else { return }
                
                // HACK: Workaround to force ChatControllerNode to refresh.
                // Changing `hasBots` triggers UI re-render, otherwise ChatControllerNode
                // doesn't react to restriction rules updates on its own.
                updateChatPresentationInterfaceState(
                    animated: false,
                    interactive: false,
                    { $0.updatedHasBots(!$0.hasBots) }
                )
                
                updateChatLocationToOther(chatLocation: chatLocation)
            }
            .store(in: &cancellables)
    }
    
    func restrictedChatInfoPublisher(
        peerId: PeerId
    ) -> some Publisher<RestrictedChatInfo?, Never> {
        let signal = combineLatest(
            context.engine.data.subscribe(
                TelegramEngine.EngineData.Item.Peer.Peer(id: peerId)
            ),
            context.contentSettings
        )
        |> distinctUntilChanged(isEqual: ==)
        |> map { peer, contentSettings -> RestrictedChatInfo? in
            guard let peer else { return nil }
            
            let applicablePlatforms = Set(["all", "ios"] + contentSettings.addContentRestrictionReasons)
            let applicableRules = (peer.restrictionInfo()?.rules ?? [])
                .filter {
                    applicablePlatforms.contains($0.platform)
                }
                .filter {
                    !contentSettings.ignoreContentRestrictionReasons.contains($0.reason)
                }
            
            return RestrictedChatInfo(
                restrictionReasons: applicableRules.map(\.reason),
                restrictionText: applicableRules.first?.text,
                title: peer.debugDisplayTitle
            )
        }
        |> deliverOnMainQueue
        
        return signal.toPublisher()
    }
}

private extension EnginePeer {
    func restrictionInfo() -> PeerAccessRestrictionInfo? {
        switch self {
        case let .user(user):
            user.restrictionInfo
        case let .channel(channel):
            channel.restrictionInfo
        default:
            nil
        }
    }
}
