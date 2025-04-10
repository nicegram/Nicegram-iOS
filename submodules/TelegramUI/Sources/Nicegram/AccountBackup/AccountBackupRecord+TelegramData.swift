import FeatAccountBackup
import Foundation
import TelegramCore

extension AccountBackupRecord {
    struct TelegramData: Codable {
        let backupData: AccountBackupData
        let environment: Environment
        
        enum Environment: String, Codable {
            case production
            case test
        }
    }
}

// String serialization

extension AccountBackupRecord.TelegramData {
    init(string: String) throws {
        let data = try Data(base64Encoded: string).unwrap()
        self = try JSONDecoder().decode(Self.self, from: data)
    }
    
    func toString() throws -> String {
        try JSONEncoder().encode(self).base64EncodedString()
    }
}

// Telegram mapping

extension AccountBackupRecord {
    var tgAccountId: AccountRecordId {
        AccountRecordId(rawValue: accountId)
    }
}

extension AccountBackupRecord.TelegramData {
    init(record: AccountRecord<TelegramAccountManagerTypes.Attribute>) throws {
        let attributes = record.attributes
        let backupData = attributes.backupData()?.data
        let environment = attributes.environment()?.environment
        try self.init(
            backupData: backupData.unwrap(),
            environment: environment.flatMap { .init($0) } ?? .production
        )
    }
    
    func toRecord(recordId: AccountRecordId) -> AccountRecord<TelegramAccountManagerTypes.Attribute> {
        let backupDataAttribute = AccountBackupDataAttribute(
            data: self.backupData
        )
        let environmentAttribute = AccountEnvironmentAttribute(
            environment: .init(self.environment)
        )
        
        return AccountRecord(
            id: recordId,
            attributes: [
                .backupData(backupDataAttribute),
                .environment(environmentAttribute)
            ],
            temporarySessionId: nil
        )
    }
}

extension AccountBackupRecord.TelegramData.Environment {
    init(_ environment: AccountEnvironment) {
        switch environment {
        case .production: self = .production
        case .test: self = .test
        }
    }
}

extension AccountEnvironment {
    init(_ environment: AccountBackupRecord.TelegramData.Environment) {
        switch environment {
        case .production: self = .production
        case .test: self = .test
        }
    }
}

private extension [TelegramAccountManagerTypes.Attribute] {
    func backupData() -> AccountBackupDataAttribute? {
        for attribute in self {
            if case let .backupData(backupData) = attribute {
                return backupData
            }
        }
        return nil
    }
    
    func environment() -> AccountEnvironmentAttribute? {
        for attribute in self {
            if case let .environment(environment) = attribute {
                return environment
            }
        }
        return nil
    }
}
