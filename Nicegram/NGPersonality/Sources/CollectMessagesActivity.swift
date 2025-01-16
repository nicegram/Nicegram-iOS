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
private let collectMessagesActivityUseCase = container.collectMessagesActivityUseCase()

public func collectMessagesActivity(
    with context: AccountContext
) async {
    guard checkPreferencesStateUseCase(
        with: context.account.peerId.toInt64(),
        personality: .messagesActivity(.empty)
    ) else { return }
    guard checkCollectStateUseCase(with: .messagesActivity(.empty)) else { return }
    
    let result = await withCheckedContinuation { continuation in
        _ = combineLatest(
            searchGlobal(with: context),
            search(with: context)
        )
        .start { all, user in
            var allCount: Int32 = 0
            var userCount: Int32 = 0
            
            switch all {
            case let .channelMessages(_, _, count, _, _, _, _, _):
                allCount = count
            case let .messagesSlice(_, count, _, _, _, _, _):
                allCount = count
            default: break
            }
            switch user {
            case let .channelMessages(_, _, count, _, _, _, _, _):
                userCount = count
            case let .messagesSlice(_, count, _, _, _, _, _):
                userCount = count
            default: break
            }
            
            continuation.resume(returning: (allCount, userCount))
        }
    }
    
    await collectMessagesActivityUseCase(
        with: context.account.peerId.toInt64(),
        allMessagesCount: result.0,
        userMessagesCount: result.1
    )
}

// limit = 0, return only count without messages
func search(
    with context: AccountContext,
    peer: Api.InputPeer = .inputPeerEmpty,
    from: Api.InputPeer = .inputPeerSelf,
    limit: Int32 = 0
) -> Signal<Api.messages.Messages?, NoError> {
    context.account.network.request(Api.functions.messages.search(
        flags: 0,
        peer: peer,
        q: "",
        fromId: from,
        savedPeerId: nil,
        savedReaction: nil,
        topMsgId: nil,
        filter: .inputMessagesFilterEmpty,
        minDate: 0,
        maxDate: 0,
        offsetId: 0,
        addOffset: 0,
        limit: limit,
        maxId: 0,
        minId: 0,
        hash: 0
    ))
    |> map(Optional.init)
    |> `catch` { error -> Signal<Api.messages.Messages?, NoError> in
        return .single(nil)
    }
}

private func searchGlobal(
    with context: AccountContext,
    limit: Int32 = 0
) -> Signal<Api.messages.Messages?, NoError> {
    context.account.network.request(Api.functions.messages.searchGlobal(
        flags: 0,
        folderId: nil,
        q: "",
        filter: .inputMessagesFilterEmpty,
        minDate: 0,
        maxDate: 0,
        offsetRate: 0,
        offsetPeer: .inputPeerEmpty,
        offsetId: 0,
        limit: limit
    ))
    |> map(Optional.init)
    |> `catch` { error -> Signal<Api.messages.Messages?, NoError> in
        return .single(nil)
    }
}
