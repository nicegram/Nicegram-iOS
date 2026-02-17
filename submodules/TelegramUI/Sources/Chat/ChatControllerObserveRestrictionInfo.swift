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
        
        applicableRestrictionRulesPublisher(peerId: peerId)
            .sink { [weak self] rules in
                self?.chatDisplayNode.restrictedChatSupplementViewModel.update(
                    chatInfo: RestrictedChatInfo(
                        restrictionReasons: rules.map(\.reason),
                        restrictionText: rules.first?.text
                    )
                )
            }
            .store(in: &cancellables)
    }
    
    func reloadChatWhenNeeded() {
        guard let peerId = chatLocation.peerId else { return }
        
        applicableRestrictionRulesPublisher(peerId: peerId)
            .map(\.isEmpty)
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
    
    func applicableRestrictionRulesPublisher(
        peerId: PeerId
    ) -> some Publisher<[RestrictionRule], Never> {
        let signal = combineLatest(
            context.engine.data.subscribe(
                TelegramEngine.EngineData.Item.Peer.Peer(id: peerId)
            ) |> map { $0?.restrictionInfo() },
            context.contentSettings
        )
        |> distinctUntilChanged(isEqual: ==)
        |> map { restrictionInfo, contentSettings -> [RestrictionRule] in
            guard let restrictionInfo else { return [] }
            
            let applicablePlatforms = Set(["all", "ios"] + contentSettings.addContentRestrictionReasons)

            return restrictionInfo.rules
                .filter {
                    applicablePlatforms.contains($0.platform)
                }
                .filter {
                    !contentSettings.ignoreContentRestrictionReasons.contains($0.reason)
                }
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
