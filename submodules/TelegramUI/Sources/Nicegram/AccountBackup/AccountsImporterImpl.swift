import AccountContext
import FeatAccountBackup
import MemberwiseInit
import NGUtils
import SwiftSignalKit
import TelegramCore

@MemberwiseInit
class AccountsImporterImpl {
    @Init(.internal) private let sharedContextProvider: SharedContextProvider
}

extension AccountsImporterImpl: AccountsImporter {
    func importAccounts(_ records: [AccountBackupRecord]) async throws {
        try await sharedContextProvider.sharedContext().accountManager
            .transaction { transaction in
                let currentMaxSortOrder = transaction.getRecords()
                    .map { $0.attributes.sortOrder }
                    .max() ?? -1
                var sortOrder = currentMaxSortOrder + 1
                for record in records {
                    let telegramData = try? AccountBackupRecord.TelegramData(
                        string: record.telegramData
                    )
                    if let telegramData {
                        let record = telegramData.toRecord(recordId: record.tgAccountId)
                        transaction.updateRecord(record.id) { _ in
                            var attributes = record.attributes
                            attributes.sortOrder = sortOrder
                            attributes.updateNicegramAttribute {
                                $0 = AccountNicegramAttribute(
                                    imported: true
                                )
                            }
                            
                            return record.with(attributes: attributes)
                        }
                        sortOrder += 1
                    }
                }
                
                if transaction.getCurrent() == nil {
                    if let record = transaction.getRecords().first {
                        transaction.setCurrentId(record.id)
                        transaction.removeAuth()
                    }
                }
            }
            .awaitForFirstValue()
        
        Task {
            try await loadPeersInfo(records.map(\.tgAccountId))
        }
    }
}

private extension AccountsImporterImpl {
    func loadPeersInfo(_ recordIds: [AccountRecordId]) async throws {
        let contextsSignal = sharedContextProvider.sharedContextSignal()
        |> mapToSignal { $0.activeAccountContexts }
        |> map { _, activeAccounts, _ in
            recordIds.compactMap { id in
                activeAccounts.first{ $0.0 == id }?.1
            }
        }
        |> filter { contexts in
            contexts.count == recordIds.count
        }
        let contexts = try await contextsSignal.awaitForFirstValue()
        
        await withTaskGroup(of: Void.self) { group in
            for context in contexts {
                group.addTask {
                    let account = context.account
                    
                    account.network.shouldKeepConnection.set(.single(true))
                    _ = try? await context.engine.peers
                        .updatedRemotePeer(
                            peer: .user(
                                id: account.peerId.id._internalGetInt64Value(),
                                accessHash: 0
                            )
                        )
                        .awaitForFirstValue()
                    account.network.shouldKeepConnection.set(account.shouldKeepConnection)
                }
            }
        }
    }
}

