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
    with context: AccountContext,
    completion: @escaping () -> Void = {}
) {
    guard checkCollectStateUseCase(with: .ghostScore(.empty)) else { return }
    guard checkPreferencesStateUseCase(with: .ghostScore(.empty)) else { return }
    

    _ = context.account.postbox.transaction { transaction -> ChatListTotalUnreadState in
        transaction.getTotalUnreadState(groupId: .root)
    }
    .start { state in
        let count = state.count(for: .filtered, in: .messages, with: .contact)
        
        collectGhostScoreUseCase(
            with: context.account.peerId.toInt64(),
            count: count
        )
        completion()
    }
}
