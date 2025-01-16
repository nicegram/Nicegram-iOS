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
    guard checkPreferencesStateUseCase(
        with: context.account.peerId.toInt64(),
        personality: .influencerScore(.empty)
    ) else { return }
    guard checkCollectStateUseCase(with: .influencerScore(.empty)) else { return }
    
    let result = await withCheckedContinuation { continuation in
        _ = influencerScore(with: context)
            .start(next: { result in
                continuation.resume(returning: result)
            })
    }
    
    await collectInfluencerScoreUseCase(
        with: context.account.peerId.toInt64(),
        ownerCount: result.0,
        ownerParticipantsCount: result.1,
        allGroupsCount: result.2,
        allGroupsParticipantsCount: result.3,
        allChannelsCount: result.4,
        allChatParticipantsCount: result.5
    )
}

private func influencerScore(
    with context: AccountContext
) -> Signal<(Int32, Int32, Int32, Int32, Int32, Int32), NoError> {
    dialogs(with: context)
    |> mapToSignal { dialogs -> Signal<[Api.messages.ChatFull?], NoError> in
        switch dialogs {
        case let .dialogs(_, _, chats, _):
            return fullChannels(with: context, chats: chats)
        case let .dialogsSlice(_, _, _, chats, _):
            return fullChannels(with: context, chats: chats)
        default: return .single([])
        }
    }
    |> map { fullChannels -> (Int32, Int32, Int32, Int32, Int32, Int32) in
        var ownerParticipantsCount: Int32 = 0
        var ownerCount: Int32 = 0
        var allGroupsParticipantsCount: Int32 = 0
        var allGroupsCount: Int32 = 0
        var allChannelsCount: Int32 = 0
        var allChatParticipantsCount: Int32 = 0
        
        fullChannels.forEach { chatFull in
            switch chatFull {
            case let .chatFull(fullChat, _, _):
                switch fullChat {
                case let .channelFull(flags, _, _, _, participantsCount, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _):
                    let channelFlags = TelegramChannelFlags(rawValue: flags)
                    if channelFlags.contains(.isCreator) {
                        ownerCount += 1
                        ownerParticipantsCount += (participantsCount ?? 0)
                    }
                    allGroupsParticipantsCount += (participantsCount ?? 0)
                    allGroupsCount += 1
                case let .chatFull(_, _, _, participants, _, _, _, _, _, _, _, _, _, _, _, _, _, _):
                    switch participants {
                    case let .chatParticipants(_, participants, _):
                        allChatParticipantsCount += Int32(participants.count)
                    default: break
                    }
                    allChannelsCount += 1
                }
            default: break
            }
        }

        return (ownerCount, ownerParticipantsCount, allGroupsCount, allGroupsParticipantsCount, allChannelsCount, allChatParticipantsCount)
    }
}

private func fullChannels(
    with context: AccountContext,
    chats: [Api.Chat]
) -> Signal<[Api.messages.ChatFull?], NoError> {
    combineLatest(
        chats.compactMap { chat in
            switch chat {
            case let .channel(_, _, id, accessHash, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _):
                return fullChannel(with: context, channelId: id, accessHash: accessHash ?? 0)
            default: return nil
            }
        }
    )
}

private func fullChannel(
    with context: AccountContext,
    channelId: Int64,
    accessHash: Int64
) -> Signal<Api.messages.ChatFull?, NoError> {
    context.account.network.request(Api.functions.channels.getFullChannel(
        channel: .inputChannel(channelId: channelId, accessHash: accessHash)
    ))
    |> map(Optional.init)
    |> `catch` { error -> Signal<Api.messages.ChatFull?, NoError> in
        return .single(nil)
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
