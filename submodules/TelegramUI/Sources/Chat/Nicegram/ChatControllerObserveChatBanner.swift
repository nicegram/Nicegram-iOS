import protocol Combine.Publisher
import FeatChatBanner
import Postbox
import SwiftSignalKit
import TelegramCore

extension ChatControllerImpl {
    func observeChatBanner() {
        guard let peerId = chatLocation.peerId else { return }

        chatKindPublisher(peerId: peerId)
            .removeDuplicates()
            .sink { [weak self] chatKind in
                self?.chatDisplayNode.chatBannerViewModel.update(
                    chatKind: chatKind
                )
            }
            .store(in: &cancellables)
    }
}

private extension ChatControllerImpl {
    func chatKindPublisher(
        peerId: PeerId
    ) -> some Publisher<ChatKind, Never> {
        let signal = combineLatest(
            context.engine.data.subscribe(
                TelegramEngine.EngineData.Item.Peer.Peer(id: peerId)
            ),
            context.contentSettings
        )
        |> distinctUntilChanged(isEqual: ==)
        |> map { peer, contentSettings -> ChatKind in
            guard let peer else { return .ineligible }

            return peer.chatKind(contentSettings: contentSettings)
        }
        |> deliverOnMainQueue

        return signal.toPublisher()
    }
}

private extension EnginePeer {
    /// Restricted takes precedence over public: a public channel that is also
    /// restricted is judged by `showInRestrictedChat`, never by `showInChat`.
    func chatKind(contentSettings: ContentSettings) -> ChatKind {
        let blockingRules = blockingRestrictionRules(
            contentSettings: contentSettings
        )

        if !blockingRules.isEmpty {
            let stillBlocking = blockingRules.filter {
                !contentSettings.ignoreContentRestrictionReasons.contains($0.reason)
            }
            return stillBlocking.isEmpty ? .unlockedRestricted : .ineligible
        }

        // A username is what "public" means: there is no public/private flag, and
        // a basic group has no username field at all — making one public migrates
        // it to a channel, which this case then covers.
        guard case let .channel(channel) = self,
              channel.addressName != nil else {
            return .ineligible
        }

        return .publicChat
    }

    /// Restriction rules that would block the chat screen — the same set
    /// `Peer.restrictionText(platform:contentSettings:)` considers, so the
    /// `sensitive` reason (which never blocks a screen) is excluded.
    func blockingRestrictionRules(
        contentSettings: ContentSettings
    ) -> [RestrictionRule] {
        let applicablePlatforms = Set(
            ["all", "ios"] + contentSettings.addContentRestrictionReasons
        )

        return (restrictionInfo()?.rules ?? [])
            .filter { $0.reason != "sensitive" }
            .filter { applicablePlatforms.contains($0.platform) }
    }
}
