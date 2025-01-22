import TelegramApi
import TelegramCore
import AccountContext
import SwiftSignalKit
import Network
import MtProtoKit
import Postbox
import FeatPersonality

private let container = PersonalityContainer.shared
private let checkCollectStateUseCase = container.checkCollectStateUseCase()
private let checkPreferencesStateUseCase = container.checkPreferencesStateUseCase()
private let collectInfluencerScoreUseCase = container.collectInfluencerScoreUseCase()

public func collectInfluencerScore(
    with context: AccountContext
) async {
    let id = context.account.peerId.toInt64()
    guard checkPreferencesStateUseCase(with: id, personality: .influencerScore(.empty)) else { return }
    guard checkCollectStateUseCase(with: id, personality: .influencerScore(.empty)) else { return }
    
    let result = await withCheckedContinuation { continuation in
        _ = influencerScore(with: context)
            .start(next: { result in
                continuation.resume(returning: result)
            })
    }
    
    await collectInfluencerScoreUseCase(
        with: context.account.peerId.toInt64(),
        ownerChannelCount: result.0,
        ownerChannelParticipantsCount: result.1,
        ownerGroupCount: result.2,
        ownerGroupParticipantsCount: result.3,
        groupCount: result.4,
        groupParticipantsCount: result.5
    )
}

private func influencerScore(
    with context: AccountContext
) -> Signal<(Int32, Int32, Int32, Int32, Int32, Int32), NoError> {
    dialogs(with: context)
    |> map { dialogs -> [(PeerId.Namespace, Bool, Int32)] in
        switch dialogs {
        case let .dialogs(_, _, chats, _):
            return chats.compactMap { information(from: $0) }
        case let .dialogsSlice(_, _, _, chats, _):
            return chats.compactMap { information(from: $0) }
        default: return []
        }
    }
    |> map { chats -> (Int32, Int32, Int32, Int32, Int32, Int32) in
        var ownerChannelCount: Int32 = 0
        var ownerChannelParticipantsCount: Int32 = 0
        var ownerGroupCount: Int32 = 0
        var ownerGroupParticipantsCount: Int32 = 0

        var groupCount: Int32 = 0
        var groupParticipantsCount: Int32 = 0
        
        chats.forEach { chat in
            if chat.0 == Namespaces.Peer.CloudChannel {
                if chat.1 {
                    ownerChannelCount += 1
                    ownerChannelParticipantsCount += chat.2
                }
            } else if chat.0 == Namespaces.Peer.CloudGroup {
                if chat.1 {
                    ownerGroupCount += 1
                    ownerGroupParticipantsCount += chat.2
                }
                groupCount += 1
                groupParticipantsCount += chat.2
            }
        }

        return (
            ownerChannelCount,
            ownerChannelParticipantsCount,
            ownerGroupCount,
            ownerGroupParticipantsCount,
            groupCount,
            groupParticipantsCount
        )
    }
}

private func dialogs(
    with context: AccountContext
) -> Signal<Api.messages.Dialogs?, NoError> {
    context.account.network.request(Api.functions.messages.getDialogs(
        flags: 0,
        folderId: nil,
        offsetDate: 0,
        offsetId: 0,
        offsetPeer: .inputPeerSelf,
        limit: .max,
        hash: 0
    ))
    |> map(Optional.init)
    |> `catch` { error -> Signal<Api.messages.Dialogs?, NoError> in
        return .single(nil)
    }
}

private func information(from chat: Api.Chat) -> (PeerId.Namespace, Bool, Int32)? {
    switch chat {
    case let .chat(flags, _, _, _, participantsCount, _, _, _, _, _):
        guard participantsCount > 0 else { return nil }

        let isCreator = (flags & (1 << 0)) != 0

        return (Namespaces.Peer.CloudGroup, isCreator, participantsCount)
    case let .channel(flags, _, _, _, _, _, _, _, _, _, _, _, participantsCount, _, _, _, _, _, _, _, _):
        guard let participantsCount,
              participantsCount > 0 else { return nil }

        let isCreator = (flags & (1 << 0)) != 0

        var type = Namespaces.Peer.CloudChannel
        if (flags & Int32(1 << 8)) != 0 {
            type = Namespaces.Peer.CloudGroup
        }
                        
        return (type, isCreator, participantsCount)
    case .chatEmpty, .chatForbidden, .channelForbidden:
        return nil
    }
}
