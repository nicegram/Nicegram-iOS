import AccountContext
import Combine
import FeatAccountBackup
import MemberwiseInit
import NGUtils
import SwiftSignalKit
import TelegramCore

@MemberwiseInit
class ActiveAccountsProviderImpl {
    @Init(.internal) private let sharedContextProvider: SharedContextProvider
}

extension ActiveAccountsProviderImpl: ActiveAccountsProvider {
    func get() async -> [ActiveAccount] {
        (try? await publisher().awaitForFirstValue()) ?? []
    }
    
    func publisher() -> AnyPublisher<[ActiveAccount], Never> {
        let signal = sharedContextProvider.sharedContextSignal()
        |> mapToSignal { sharedContext in
            combineLatest(
                sharedContext.accountManager.accountRecords(),
                sharedContext.activeAccountContexts
            )
            |> map { view, activeAccountContexts in
                let (_, activeAccounts, _) = activeAccountContexts
                return view.records
                    .sorted { $0.attributes.sortOrder < $1.attributes.sortOrder }
                    .compactMap { record -> (AccountRecord<TelegramAccountManagerTypes.Attribute>, AccountContext)? in
                        let context = activeAccounts.first{ $0.0 == record.id }?.1
                        guard let context else { return nil }
                        return (record, context)
                    }
            }
        }
        |> mapToSignal { [self] recordsWithContext in
            combineLatest(
                recordsWithContext.map { record, context in
                    activeAccount(record: record, context: context)
                }
            )
            |> map { records in
                records.compactMap { $0 }
            }
        }
        
        return signal
            .toPublisher()
            .eraseToAnyPublisher()
    }
    
    func set(accountIds: [Int64], isExported: Bool) async {
        try? await sharedContextProvider.sharedContext().accountManager
            .transaction { transaction in
                for accountId in accountIds {
                    let accountId = AccountRecordId(rawValue: accountId)
                    transaction.updateRecord(accountId) { record in
                        guard let record else { return nil }
                        
                        var attributes = record.attributes
                        attributes.updateNicegramAttribute {
                            $0.exported = isExported
                        }
                        
                        return record.with(attributes: attributes)
                    }
                }
            }
            .awaitForFirstValue()
    }
}

private extension ActiveAccountsProviderImpl {
    func activeAccount(
        record: AccountRecord<TelegramAccountManagerTypes.Attribute>,
        context: AccountContext
    ) -> Signal<ActiveAccount?, NoError> {
        let telegramData = try? AccountBackupRecord.TelegramData(record: record).toString()
        guard let telegramData else {
            return .single(nil)
        }
        
        let peerId = context.account.peerId
        let nicegramAttribute = record.attributes.nicegramAttribute()
        
        return context.account.postbox.peerView(id: peerId)
        |> map { view -> ActiveAccount? in
            guard let peer = view.peers[view.peerId] else { return nil }
            
            return ActiveAccount(
                accountId: record.id.int64,
                fullName: peer.debugDisplayTitle,
                isExported: nicegramAttribute.exported,
                isImported: nicegramAttribute.imported,
                peerId: peerId.ng_toInt64(),
                telegramData: telegramData,
                username: peer.usernameWithAtSign
            )
        }
    }
}
