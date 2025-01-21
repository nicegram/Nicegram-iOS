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
private let collectGhostScoreUseCase = container.collectGhostScoreUseCase()

public func collectGhostScore(
    with context: AccountContext
) async {
    let id = context.account.peerId.toInt64()
    guard checkPreferencesStateUseCase(with: id, personality: .ghostScore(.empty)) else { return }
    guard checkCollectStateUseCase(with: id, personality: .ghostScore(.empty)) else { return }

    let count = await withCheckedContinuation { continuation in
        _ = context.account.postbox.transaction { transaction -> ChatListTotalUnreadState in
            transaction.getTotalUnreadState(groupId: .root)
        }
        .start { state in
            let count = state.count(for: .filtered, in: .messages, with: .contact)
            
            continuation.resume(returning: count)
        }
    }
    
    await collectGhostScoreUseCase(
        with: context.account.peerId.toInt64(),
        count: count
    )
}
