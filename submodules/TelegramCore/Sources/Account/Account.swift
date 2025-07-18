import Foundation
import Postbox
import SwiftSignalKit
import MtProtoKit
import TelegramApi
import CryptoUtils
import EncryptionProvider

private let accountRecordToActiveKeychainId = Atomic<[AccountRecordId: Int]>(value: [:])

private func makeExclusiveKeychain(id: AccountRecordId, postbox: Postbox) -> Keychain {
    var keychainId = 0
    let _ = accountRecordToActiveKeychainId.modify { dict in
        var dict = dict
        if let value = dict[id] {
            dict[id] = value + 1
            keychainId = value + 1
        } else {
            keychainId = 0
            dict[id] = 0
        }
        return dict
    }
    return Keychain(get: { [weak postbox] key in
        let enabled = accountRecordToActiveKeychainId.with { dict -> Bool in
            return dict[id] == keychainId
        }
        if enabled, let postbox = postbox {
            return postbox.keychainEntryForKey(key)
        } else {
            Logger.shared.log("Keychain", "couldn't get \(key) — not current")
            return nil
        }
    }, set: { [weak postbox] key, data in
        let enabled = accountRecordToActiveKeychainId.with { dict -> Bool in
            return dict[id] == keychainId
        }
        if enabled, let postbox = postbox {
            postbox.setKeychainEntryForKey(key, value: data)
        } else {
            Logger.shared.log("Keychain", "couldn't set \(key) — not current")
        }
    }, remove: { [weak postbox] key in
        let enabled = accountRecordToActiveKeychainId.with { dict -> Bool in
            return dict[id] == keychainId
        }
        if enabled, let postbox = postbox {
            postbox.removeKeychainEntryForKey(key)
        } else {
            Logger.shared.log("Keychain", "couldn't remove \(key) — not current")
        }
    })
}

func _internal_test(_ network: Network) -> Signal<Bool, String> {
    return network.request(Api.functions.help.test()) |> map { result in
        switch result {
        case .boolFalse:
            return false
        case .boolTrue:
            return true
        }
    } |> mapError { error in
        return error.description
    }
}

public class UnauthorizedAccount {
    public let networkArguments: NetworkInitializationArguments
    public let id: AccountRecordId
    public let rootPath: String
    public let basePath: String
    public let testingEnvironment: Bool
    public let postbox: Postbox
    public let network: Network
    let stateManager: UnauthorizedAccountStateManager
    
    private let updateLoginTokenPipe = ValuePipe<Void>()
    public var updateLoginTokenEvents: Signal<Void, NoError> {
        return self.updateLoginTokenPipe.signal()
    }
    
    private let serviceNotificationPipe = ValuePipe<String>()
    public var serviceNotificationEvents: Signal<String, NoError> {
        return self.serviceNotificationPipe.signal()
    }
    
    public var masterDatacenterId: Int32 {
        return Int32(self.network.mtProto.datacenterId)
    }
    
    public let shouldBeServiceTaskMaster = Promise<AccountServiceTaskMasterMode>()
    
    init(accountManager: AccountManager<TelegramAccountManagerTypes>, networkArguments: NetworkInitializationArguments, id: AccountRecordId, rootPath: String, basePath: String, testingEnvironment: Bool, postbox: Postbox, network: Network, shouldKeepAutoConnection: Bool = true) {
        self.networkArguments = networkArguments
        self.id = id
        self.rootPath = rootPath
        self.basePath = basePath
        self.testingEnvironment = testingEnvironment
        self.postbox = postbox
        self.network = network
        let updateLoginTokenPipe = self.updateLoginTokenPipe
        let serviceNotificationPipe = self.serviceNotificationPipe
        let masterDatacenterId = Int32(network.mtProto.datacenterId)
        
        var updateSentCodeImpl: ((Api.auth.SentCode) -> Void)?
        self.stateManager = UnauthorizedAccountStateManager(
            network: network,
            updateLoginToken: {
                updateLoginTokenPipe.putNext(Void())
            },
            updateSentCode: { sentCode in
                updateSentCodeImpl?(sentCode)
            },
            displayServiceNotification: { text in
                serviceNotificationPipe.putNext(text)
            }
        )
        
        updateSentCodeImpl = { [weak self] sentCode in
            switch sentCode {
            case .sentCodePaymentRequired:
                break
            case let .sentCode(_, type, phoneCodeHash, nextType, codeTimeout):
                let _ = postbox.transaction({ transaction in
                    var parsedNextType: AuthorizationCodeNextType?
                    if let nextType = nextType {
                        parsedNextType = AuthorizationCodeNextType(apiType: nextType)
                    }
                    if let state = transaction.getState() as? UnauthorizedAccountState, case let .payment(phoneNumber, _, _, syncContacts) = state.contents {
                        transaction.setState(UnauthorizedAccountState(isTestingEnvironment: testingEnvironment, masterDatacenterId: masterDatacenterId, contents: .confirmationCodeEntry(number: phoneNumber, type: SentAuthorizationCodeType(apiType: type), hash: phoneCodeHash, timeout: codeTimeout, nextType: parsedNextType, syncContacts: syncContacts, previousCodeEntry: nil, usePrevious: false)))
                    }
                }).start()
            case let .sentCodeSuccess(authorization):
                switch authorization {
                case let .authorization(_, _, _, futureAuthToken, user):
                    let _ = postbox.transaction({ [weak self] transaction in
                        var syncContacts = true
                        if let state = transaction.getState() as? UnauthorizedAccountState, case let .payment(_, _, _, syncContactsValue) = state.contents {
                            syncContacts = syncContactsValue
                        }
                        
                        if let futureAuthToken = futureAuthToken {
                            storeFutureLoginToken(accountManager: accountManager, token: futureAuthToken.makeData())
                        }
                        
                        let user = TelegramUser(user: user)
                        var isSupportUser = false
                        if let phone = user.phone, phone.hasPrefix("42"), phone.count <= 5 {
                            isSupportUser = true
                        }
                        let state = AuthorizedAccountState(isTestingEnvironment: testingEnvironment, masterDatacenterId: masterDatacenterId, peerId: user.id, state: nil, invalidatedChannels: [])
                        initializedAppSettingsAfterLogin(transaction: transaction, appVersion: networkArguments.appVersion, syncContacts: syncContacts)
                        transaction.setState(state)
                        return accountManager.transaction { [weak self] transaction -> SendAuthorizationCodeResult in
                            if let self {
                                switchToAuthorizedAccount(transaction: transaction, account: self, isSupportUser: isSupportUser)
                            }
                            return .loggedIn
                        }
                    }).start()
                case let .authorizationSignUpRequired(_, termsOfService):
                    let _ = postbox.transaction({ [weak self] transaction in
                        if let self {
                            if let state = transaction.getState() as? UnauthorizedAccountState, case let .payment(number, codeHash, _, syncContacts) = state.contents {
                                let _ = beginSignUp(
                                    account: self,
                                    data: AuthorizationSignUpData(
                                        number: number,
                                        codeHash: codeHash,
                                        code: .phoneCode(""),
                                        termsOfService: termsOfService.flatMap(UnauthorizedAccountTermsOfService.init(apiTermsOfService:)),
                                        syncContacts: syncContacts
                                    )
                                ).start()
                            }
                        }
                    }).start()
                }
            }
        }
        
        network.shouldKeepConnection.set(self.shouldBeServiceTaskMaster.get()
        |> map { mode -> Bool in
            switch mode {
                case .now, .always:
                    return true
                case .never:
                    return false
            }
        })
        
        network.context.performBatchUpdates({
            var datacenterIds: [Int] = [1, 2]
            if testingEnvironment {
                datacenterIds = [3]
            } else {
                datacenterIds.append(contentsOf: [4])
            }
            for id in datacenterIds {
                if network.context.authInfoForDatacenter(withId: id, selector: .persistent) == nil {
                    network.context.authInfoForDatacenter(withIdRequired: id, isCdn: false, selector: .ephemeralMain, allowUnboundEphemeralKeys: false)
                }
            }
            network.context.beginExplicitBackupAddressDiscovery()
        })
        
        self.stateManager.reset()
    }
    
    public func changedMasterDatacenterId(accountManager: AccountManager<TelegramAccountManagerTypes>, masterDatacenterId: Int32) -> Signal<UnauthorizedAccount, NoError> {
        if masterDatacenterId == Int32(self.network.mtProto.datacenterId) {
            return .single(self)
        } else {
            let keychain = makeExclusiveKeychain(id: self.id, postbox: self.postbox)
            
            return accountManager.transaction { transaction -> (LocalizationSettings?, ProxySettings?) in
                return (transaction.getSharedData(SharedDataKeys.localizationSettings)?.get(LocalizationSettings.self), transaction.getSharedData(SharedDataKeys.proxySettings)?.get(ProxySettings.self))
            }
            |> mapToSignal { localizationSettings, proxySettings -> Signal<(LocalizationSettings?, ProxySettings?, NetworkSettings?, AppConfiguration), NoError> in
                return self.postbox.transaction { transaction -> (LocalizationSettings?, ProxySettings?, NetworkSettings?, AppConfiguration) in
                    return (localizationSettings, proxySettings, transaction.getPreferencesEntry(key: PreferencesKeys.networkSettings)?.get(NetworkSettings.self), transaction.getPreferencesEntry(key: PreferencesKeys.appConfiguration)?.get(AppConfiguration.self) ?? .defaultValue)
                }
            }
            |> mapToSignal { localizationSettings, proxySettings, networkSettings, appConfiguration -> Signal<UnauthorizedAccount, NoError> in
                return initializedNetwork(accountId: self.id, arguments: self.networkArguments, supplementary: false, datacenterId: Int(masterDatacenterId), keychain: keychain, basePath: self.basePath, testingEnvironment: self.testingEnvironment, languageCode: localizationSettings?.primaryComponent.languageCode, proxySettings: proxySettings, networkSettings: networkSettings, phoneNumber: nil, useRequestTimeoutTimers: false, appConfiguration: appConfiguration)
                |> map { network in
                    let updated = UnauthorizedAccount(accountManager: accountManager, networkArguments: self.networkArguments, id: self.id, rootPath: self.rootPath, basePath: self.basePath, testingEnvironment: self.testingEnvironment, postbox: self.postbox, network: network)
                    updated.shouldBeServiceTaskMaster.set(self.shouldBeServiceTaskMaster.get())
                    return updated
                }
            }
        }
    }
}

func accountNetworkUsageInfoPath(basePath: String) -> String {
    return basePath + "/network-usage"
}

public func accountRecordIdPathName(_ id: AccountRecordId) -> String {
    return "account-\(UInt64(bitPattern: id.int64))"
}

public enum AccountResult {
    case upgrading(Float)
    case unauthorized(UnauthorizedAccount)
    case authorized(Account)
}

public func accountWithId(accountManager: AccountManager<TelegramAccountManagerTypes>, networkArguments: NetworkInitializationArguments, id: AccountRecordId, encryptionParameters: ValueBoxEncryptionParameters, supplementary: Bool, isSupportUser: Bool, rootPath: String, beginWithTestingEnvironment: Bool, backupData: AccountBackupData?, auxiliaryMethods: AccountAuxiliaryMethods, shouldKeepAutoConnection: Bool = true) -> Signal<AccountResult, NoError> {
    let path = "\(rootPath)/\(accountRecordIdPathName(id))"
    
    let postbox = openPostbox(
        basePath: path + "/postbox",
        seedConfiguration: telegramPostboxSeedConfiguration,
        encryptionParameters: encryptionParameters,
        timestampForAbsoluteTimeBasedOperations: Int32(CFAbsoluteTimeGetCurrent() + NSTimeIntervalSince1970),
        isMainProcess: !supplementary,
        isTemporary: false,
        isReadOnly: false,
        useCopy: false,
        useCaches: !supplementary,
        removeDatabaseOnError: !supplementary
    )
    
    return postbox
    |> mapToSignal { result -> Signal<AccountResult, NoError> in
        switch result {
            case let .upgrading(progress):
                return .single(.upgrading(progress))
            case .error:
                return .single(.upgrading(0.0))
            case let .postbox(postbox):
            // MARK: Nicegram DB Changes, isHidden added
                return accountManager.transaction { transaction -> (LocalizationSettings?, ProxySettings?, Bool) in
                    var localizationSettings: LocalizationSettings?
                    if !supplementary {
                        localizationSettings = transaction.getSharedData(SharedDataKeys.localizationSettings)?.get(LocalizationSettings.self)
                    }
                    // MARK: Nicegram DB Changes
                    return (localizationSettings, transaction.getSharedData(SharedDataKeys.proxySettings)?.get(ProxySettings.self), transaction.getRecords().first(where: { $0.id == id })?.attributes.contains(where: { $0.isHiddenAccountAttribute }) ?? false)
                }
                // MARK: Nicegram DB Changes, isHidden added
                |> mapToSignal { localizationSettings, proxySettings, isHidden -> Signal<AccountResult, NoError> in
                    return postbox.transaction { transaction -> (PostboxCoding?, LocalizationSettings?, ProxySettings?, NetworkSettings?, AppConfiguration, Bool) in
                        var state = transaction.getState()
                        if state == nil, let backupData = backupData {
                            let backupState = AuthorizedAccountState(isTestingEnvironment: beginWithTestingEnvironment, masterDatacenterId: backupData.masterDatacenterId, peerId: PeerId(backupData.peerId), state: nil, invalidatedChannels: [])
                            state = backupState
                            let dict = NSMutableDictionary()
                            dict.setObject(MTDatacenterAuthInfo(authKey: backupData.masterDatacenterKey, authKeyId: backupData.masterDatacenterKeyId, validUntilTimestamp: Int32.max, saltSet: [], authKeyAttributes: [:])!, forKey: backupData.masterDatacenterId as NSNumber)
                            
                            for (id, datacenterKey) in backupData.additionalDatacenterKeys {
                                dict.setObject(MTDatacenterAuthInfo(
                                    authKey: datacenterKey.key,
                                    authKeyId: datacenterKey.keyId,
                                    validUntilTimestamp: Int32.max,
                                    saltSet: [],
                                    authKeyAttributes: [:]
                                )!, forKey: id as NSNumber)
                            }
                            
                            transaction.setState(backupState)
                            if let data = try? NSKeyedArchiver.archivedData(withRootObject: dict, requiringSecureCoding: false) {
                                transaction.setKeychainEntry(data, forKey: "persistent:datacenterAuthInfoById")
                            }
                        }
                        let appConfig = transaction.getPreferencesEntry(key: PreferencesKeys.appConfiguration)?.get(AppConfiguration.self) ?? .defaultValue
                        
                        // MARK: Nicegram DB Changes, isHidden added
                        return (state, localizationSettings, proxySettings, transaction.getPreferencesEntry(key: PreferencesKeys.networkSettings)?.get(NetworkSettings.self), appConfig, isHidden)
                    }
                    |> mapToSignal { (accountState, localizationSettings, proxySettings, networkSettings, appConfig, isHidden) -> Signal<AccountResult, NoError> in
                        let keychain = makeExclusiveKeychain(id: id, postbox: postbox)
                        
                        var useRequestTimeoutTimers: Bool = true
                        if let data = appConfig.data {
                            if let _ = data["ios_killswitch_disable_request_timeout"] {
                                useRequestTimeoutTimers = false
                            }
                        }
                        
                        if let accountState = accountState {
                            switch accountState {
                                case let unauthorizedState as UnauthorizedAccountState:
                                    return initializedNetwork(accountId: id, arguments: networkArguments, supplementary: supplementary, datacenterId: Int(unauthorizedState.masterDatacenterId), keychain: keychain, basePath: path, testingEnvironment: unauthorizedState.isTestingEnvironment, languageCode: localizationSettings?.primaryComponent.languageCode, proxySettings: proxySettings, networkSettings: networkSettings, phoneNumber: nil, useRequestTimeoutTimers: useRequestTimeoutTimers, appConfiguration: appConfig)
                                        |> map { network -> AccountResult in
                                            return .unauthorized(UnauthorizedAccount(accountManager: accountManager, networkArguments: networkArguments, id: id, rootPath: rootPath, basePath: path, testingEnvironment: unauthorizedState.isTestingEnvironment, postbox: postbox, network: network, shouldKeepAutoConnection: shouldKeepAutoConnection))
                                        }
                                case let authorizedState as AuthorizedAccountState:
                                    return postbox.transaction { transaction -> String? in
                                        return (transaction.getPeer(authorizedState.peerId) as? TelegramUser)?.phone
                                    }
                                    |> mapToSignal { phoneNumber in
                                        return initializedNetwork(accountId: id, arguments: networkArguments, supplementary: supplementary, datacenterId: Int(authorizedState.masterDatacenterId), keychain: keychain, basePath: path, testingEnvironment: authorizedState.isTestingEnvironment, languageCode: localizationSettings?.primaryComponent.languageCode, proxySettings: proxySettings, networkSettings: networkSettings, phoneNumber: phoneNumber, useRequestTimeoutTimers: useRequestTimeoutTimers, appConfiguration: appConfig)
                                        |> map { network -> AccountResult in
                                            // MARK: Nicegram DB Changes, isHidden
                                            return .authorized(Account(accountManager: accountManager, id: id, basePath: path, testingEnvironment: authorizedState.isTestingEnvironment, postbox: postbox, network: network, networkArguments: networkArguments, peerId: authorizedState.peerId, auxiliaryMethods: auxiliaryMethods, supplementary: supplementary, isSupportUser: isSupportUser, isHidden: isHidden))
                                        }
                                    }
                                case _:
                                    assertionFailure("Unexpected accountState \(accountState)")
                            }
                        }
                        
                        return initializedNetwork(accountId: id, arguments: networkArguments, supplementary: supplementary, datacenterId: 2, keychain: keychain, basePath: path, testingEnvironment: beginWithTestingEnvironment, languageCode: localizationSettings?.primaryComponent.languageCode, proxySettings: proxySettings, networkSettings: networkSettings, phoneNumber: nil, useRequestTimeoutTimers: useRequestTimeoutTimers, appConfiguration: appConfig)
                        |> map { network -> AccountResult in
                            return .unauthorized(UnauthorizedAccount(accountManager: accountManager, networkArguments: networkArguments, id: id, rootPath: rootPath, basePath: path, testingEnvironment: beginWithTestingEnvironment, postbox: postbox, network: network, shouldKeepAutoConnection: shouldKeepAutoConnection))
                        }
                    }
                }
        }
    }
}

// MARK: Nicegram DB Changes
public func setAccountRecordAccessChallengeData(transaction: AccountManagerModifier<TelegramAccountManagerTypes>, id: AccountRecordId, accessChallengeData: PostboxAccessChallengeData) {
    transaction.updateRecord(id) { record in
        guard let record = record else { return nil }
        
        var attributes = record.attributes
        let isHidden = accessChallengeData != .none
        let wasHidden = attributes.contains { $0.isHiddenAccountAttribute }
        if wasHidden, !isHidden {
            attributes.removeAll { $0.isHiddenAccountAttribute }
        } else if !wasHidden, isHidden {
            attributes.append(.hiddenDoubleBottom(HiddenAccountAttribute(accessChallengeData: accessChallengeData)))
        }
        return AccountRecord(id: id, attributes: attributes, temporarySessionId: record.temporarySessionId)
    }
}

public func disableDoubleBottom(transaction: AccountManagerModifier<TelegramAccountManagerTypes>, id: AccountRecordId) {
    transaction.updateRecord(id) { record in
        guard let record = record else { return nil }
        var attributes = record.attributes
        attributes.removeAll { $0.isHiddenAccountAttribute }
        return AccountRecord(id: id, attributes: attributes, temporarySessionId: record.temporarySessionId)
    }
}

public enum TwoStepPasswordDerivation {
    case unknown
    case sha256_sha256_PBKDF2_HMAC_sha512_sha256_srp(salt1: Data, salt2: Data, iterations: Int32, g: Int32, p: Data)
    
    fileprivate init(_ apiAlgo: Api.PasswordKdfAlgo) {
        switch apiAlgo {
            case .passwordKdfAlgoUnknown:
                self = .unknown
            case let .passwordKdfAlgoSHA256SHA256PBKDF2HMACSHA512iter100000SHA256ModPow(salt1, salt2, g, p):
                self = .sha256_sha256_PBKDF2_HMAC_sha512_sha256_srp(salt1: salt1.makeData(), salt2: salt2.makeData(), iterations: 100000, g: g, p: p.makeData())
        }
    }
    
    var apiAlgo: Api.PasswordKdfAlgo {
        switch self {
            case .unknown:
                return .passwordKdfAlgoUnknown
            case let .sha256_sha256_PBKDF2_HMAC_sha512_sha256_srp(salt1, salt2, iterations, g, p):
                precondition(iterations == 100000)
                return .passwordKdfAlgoSHA256SHA256PBKDF2HMACSHA512iter100000SHA256ModPow(salt1: Buffer(data: salt1), salt2: Buffer(data: salt2), g: g, p: Buffer(data: p))
        }
    }
}

public enum TwoStepSecurePasswordDerivation {
    case unknown
    case sha512(salt: Data)
    case PBKDF2_HMAC_sha512(salt: Data, iterations: Int32)
    
    init(_ apiAlgo: Api.SecurePasswordKdfAlgo) {
        switch apiAlgo {
            case .securePasswordKdfAlgoUnknown:
                self = .unknown
            case let .securePasswordKdfAlgoPBKDF2HMACSHA512iter100000(salt):
                self = .PBKDF2_HMAC_sha512(salt: salt.makeData(), iterations: 100000)
            case let .securePasswordKdfAlgoSHA512(salt):
                self = .sha512(salt: salt.makeData())
        }
    }
    
    var apiAlgo: Api.SecurePasswordKdfAlgo {
        switch self {
            case .unknown:
                return .securePasswordKdfAlgoUnknown
            case let .PBKDF2_HMAC_sha512(salt, iterations):
                precondition(iterations == 100000)
                return .securePasswordKdfAlgoPBKDF2HMACSHA512iter100000(salt: Buffer(data: salt))
            case let .sha512(salt):
                return .securePasswordKdfAlgoSHA512(salt: Buffer(data: salt))
        }
    }
}

public struct TwoStepSRPSessionData {
    public let id: Int64
    public let B: Data
}

public struct TwoStepAuthData {
    public let nextPasswordDerivation: TwoStepPasswordDerivation
    public let currentPasswordDerivation: TwoStepPasswordDerivation?
    public let srpSessionData: TwoStepSRPSessionData?
    public let hasRecovery: Bool
    public let hasSecretValues: Bool
    public let currentHint: String?
    public let unconfirmedEmailPattern: String?
    public let secretRandom: Data
    public let nextSecurePasswordDerivation: TwoStepSecurePasswordDerivation
    public let pendingResetTimestamp: Int32?
    public let loginEmailPattern: String?
}

func _internal_twoStepAuthData(_ network: Network) -> Signal<TwoStepAuthData, MTRpcError> {
    return network.request(Api.functions.account.getPassword())
    |> map { config -> TwoStepAuthData in
        switch config {
            case let .password(flags, currentAlgo, srpB, srpId, hint, emailUnconfirmedPattern, newAlgo, newSecureAlgo, secureRandom, pendingResetDate, loginEmailPattern):
                let hasRecovery = (flags & (1 << 0)) != 0
                let hasSecureValues = (flags & (1 << 1)) != 0
                
                let currentDerivation = currentAlgo.flatMap(TwoStepPasswordDerivation.init)
                let nextDerivation = TwoStepPasswordDerivation(newAlgo)
                let nextSecureDerivation = TwoStepSecurePasswordDerivation(newSecureAlgo)
                
                switch nextSecureDerivation {
                    case .unknown:
                        break
                    case .PBKDF2_HMAC_sha512:
                        break
                    case .sha512:
                        preconditionFailure()
                }
                
                var srpSessionData: TwoStepSRPSessionData?
                if let srpB = srpB, let srpId = srpId {
                    srpSessionData = TwoStepSRPSessionData(id: srpId, B: srpB.makeData())
                }
                
                return TwoStepAuthData(nextPasswordDerivation: nextDerivation, currentPasswordDerivation: currentDerivation, srpSessionData: srpSessionData, hasRecovery: hasRecovery, hasSecretValues: hasSecureValues, currentHint: hint, unconfirmedEmailPattern: emailUnconfirmedPattern, secretRandom: secureRandom.makeData(), nextSecurePasswordDerivation: nextSecureDerivation, pendingResetTimestamp: pendingResetDate, loginEmailPattern: loginEmailPattern)
        }
    }
}

public func hexString(_ data: Data) -> String {
    let hexString = NSMutableString()
    data.withUnsafeBytes { rawBytes -> Void in
        let bytes = rawBytes.baseAddress!.assumingMemoryBound(to: UInt8.self)
        for i in 0 ..< data.count {
            hexString.appendFormat("%02x", UInt(bytes.advanced(by: i).pointee))
        }
    }
    
    return hexString as String
}

public func dataWithHexString(_ string: String) -> Data {
    var hex = string
    if hex.count % 2 != 0 {
        return Data()
    }
    var data = Data()
    while hex.count > 0 {
        let subIndex = hex.index(hex.startIndex, offsetBy: 2)
        let c = String(hex[..<subIndex])
        hex = String(hex[subIndex...])
        
        guard let byte = UInt8(c, radix: 16) else {
            return Data()
        }
        data.append(byte)
    }
    return data
}

func sha1Digest(_ data : Data) -> Data {
    return data.withUnsafeBytes { rawBytes -> Data in
        let bytes = rawBytes.baseAddress!
        return CryptoSHA1(bytes, Int32(data.count))
    }
}

func sha256Digest(_ data : Data) -> Data {
    return data.withUnsafeBytes { rawBytes -> Data in
        let bytes = rawBytes.baseAddress!
        return CryptoSHA256(bytes, Int32(data.count))
    }
}

func sha512Digest(_ data : Data) -> Data {
    return data.withUnsafeBytes { rawBytes -> Data in
        let bytes = rawBytes.baseAddress!
        return CryptoSHA512(bytes, Int32(data.count))
    }
}

func passwordUpdateKDF(encryptionProvider: EncryptionProvider, password: String, derivation: TwoStepPasswordDerivation) -> (Data, TwoStepPasswordDerivation)? {
    guard let passwordData = password.data(using: .utf8, allowLossyConversion: true) else {
        return nil
    }
    
    switch derivation {
        case .unknown:
            return nil
        case let .sha256_sha256_PBKDF2_HMAC_sha512_sha256_srp(salt1, salt2, iterations, gValue, p):
            var nextSalt1 = salt1
            var randomSalt1 = Data()
            randomSalt1.count = 32
            randomSalt1.withUnsafeMutableBytes { rawBytes -> Void in
                let bytes = rawBytes.baseAddress!.assumingMemoryBound(to: Int8.self)
                arc4random_buf(bytes, 32)
            }
            nextSalt1.append(randomSalt1)
            
            let nextSalt2 = salt2
            
            var g = Data(count: 4)
            g.withUnsafeMutableBytes { rawBytes -> Void in
                let bytes = rawBytes.baseAddress!.assumingMemoryBound(to: Int8.self)
                var gValue = gValue
                withUnsafeBytes(of: &gValue, { (sourceBuffer: UnsafeRawBufferPointer) -> Void in
                    let sourceBytes = sourceBuffer.bindMemory(to: Int8.self).baseAddress!
                    for i in 0 ..< 4 {
                        bytes.advanced(by: i).pointee = sourceBytes.advanced(by: 4 - i - 1).pointee
                    }
                })
            }
            
            let pbkdfInnerData = sha256Digest(nextSalt2 + sha256Digest(nextSalt1 + passwordData + nextSalt1) + nextSalt2)
            
            guard let pbkdfResult = MTPBKDF2(pbkdfInnerData, nextSalt1, iterations) else {
                return nil
            }
            
            let x = sha256Digest(nextSalt2 + pbkdfResult + nextSalt2)
            
            let gx = MTExp(encryptionProvider, g, x, p)!
            
            return (gx, .sha256_sha256_PBKDF2_HMAC_sha512_sha256_srp(salt1: nextSalt1, salt2: nextSalt2, iterations: iterations, g: gValue, p: p))
    }
}

struct PasswordKDFResult {
    let id: Int64
    let A: Data
    let M1: Data
}

private func paddedToLength(what: Data, to: Data) -> Data {
    if what.count < to.count {
        var what = what
        for _ in 0 ..< to.count - what.count {
            what.insert(0, at: 0)
        }
        return what
    } else {
        return what
    }
}

private func paddedXor(_ a: Data, _ b: Data) -> Data {
    let count = max(a.count, b.count)
    var a = a
    var b = b
    while a.count < count {
        a.insert(0, at: 0)
    }
    while b.count < count {
        b.insert(0, at: 0)
    }
    a.withUnsafeMutableBytes { rawABytes -> Void in
        let aBytes = rawABytes.baseAddress!.assumingMemoryBound(to: UInt8.self)
        b.withUnsafeBytes { rawBBytes -> Void in
            let bBytes = rawBBytes.baseAddress!.assumingMemoryBound(to: UInt8.self)
            for i in 0 ..< count {
                aBytes.advanced(by: i).pointee = aBytes.advanced(by: i).pointee ^ bBytes.advanced(by: i).pointee
            }
        }
    }
    return a
}

func passwordKDF(encryptionProvider: EncryptionProvider, password: String, derivation: TwoStepPasswordDerivation, srpSessionData: TwoStepSRPSessionData) -> PasswordKDFResult? {
    guard let passwordData = password.data(using: .utf8, allowLossyConversion: true) else {
        return nil
    }
    
    switch derivation {
        case .unknown:
            return nil
        case let .sha256_sha256_PBKDF2_HMAC_sha512_sha256_srp(salt1, salt2, iterations, gValue, p):
            var a = Data(count: p.count)
            let aLength = a.count
            a.withUnsafeMutableBytes { rawBytes -> Void in
                let bytes = rawBytes.baseAddress!.assumingMemoryBound(to: UInt8.self)
                let _ = SecRandomCopyBytes(nil, aLength, bytes)
            }
            
            var g = Data(count: 4)
            g.withUnsafeMutableBytes { rawBytes -> Void in
                let bytes = rawBytes.baseAddress!.assumingMemoryBound(to: Int8.self)
                var gValue = gValue
                withUnsafeBytes(of: &gValue, { (sourceBuffer: UnsafeRawBufferPointer) -> Void in
                    let sourceBytes = sourceBuffer.bindMemory(to: Int8.self).baseAddress!
                    for i in 0 ..< 4 {
                        bytes.advanced(by: i).pointee = sourceBytes.advanced(by: 4 - i - 1).pointee
                    }
                })
            }
            
            if !MTCheckIsSafeB(encryptionProvider, srpSessionData.B, p) {
                return nil
            }
            
            let B = paddedToLength(what: srpSessionData.B, to: p)
            let A = paddedToLength(what: MTExp(encryptionProvider, g, a, p)!, to: p)
            let u = sha256Digest(A + B)
            
            if MTIsZero(encryptionProvider, u) {
                return nil
            }
            
            let pbkdfInnerData = sha256Digest(salt2 + sha256Digest(salt1 + passwordData + salt1) + salt2)
            
            guard let pbkdfResult = MTPBKDF2(pbkdfInnerData, salt1, iterations) else {
                return nil
            }
            
            let x = sha256Digest(salt2 + pbkdfResult + salt2)
            
            let gx = MTExp(encryptionProvider, g, x, p)!
            
            let k = sha256Digest(p + paddedToLength(what: g, to: p))
            
            let s1 = MTModSub(encryptionProvider, B, MTModMul(encryptionProvider, k, gx, p)!, p)!
            
            if !MTCheckIsSafeGAOrB(encryptionProvider, s1, p) {
                return nil
            }
            
            let s2 = MTAdd(encryptionProvider, a, MTMul(encryptionProvider, u, x)!)!
            let S = MTExp(encryptionProvider, s1, s2, p)!
            let K = sha256Digest(paddedToLength(what: S, to: p))
            let m1 = paddedXor(sha256Digest(p), sha256Digest(paddedToLength(what: g, to: p)))
            let m2 = sha256Digest(salt1)
            let m3 = sha256Digest(salt2)
            let M = sha256Digest(m1 + m2 + m3 + A + B + K)
            
            return PasswordKDFResult(id: srpSessionData.id, A: A, M1: M)
    }
}

func securePasswordUpdateKDF(password: String, derivation: TwoStepSecurePasswordDerivation) -> (Data, TwoStepSecurePasswordDerivation)? {
    guard let passwordData = password.data(using: .utf8, allowLossyConversion: true) else {
        return nil
    }
    
    switch derivation {
        case .unknown:
            return nil
        case let .sha512(salt):
            var nextSalt = salt
            var randomSalt = Data()
            randomSalt.count = 32
            randomSalt.withUnsafeMutableBytes { rawBytes -> Void in
                let bytes = rawBytes.baseAddress!.assumingMemoryBound(to: Int8.self)
                arc4random_buf(bytes, 32)
            }
            nextSalt.append(randomSalt)
        
            var data = Data()
            data.append(nextSalt)
            data.append(passwordData)
            data.append(nextSalt)
            return (sha512Digest(data), .sha512(salt: nextSalt))
        case let .PBKDF2_HMAC_sha512(salt, iterations):
            var nextSalt = salt
            var randomSalt = Data()
            randomSalt.count = 32
            randomSalt.withUnsafeMutableBytes { rawBytes -> Void in
                let bytes = rawBytes.baseAddress!.assumingMemoryBound(to: Int8.self)
                arc4random_buf(bytes, 32)
            }
            nextSalt.append(randomSalt)
            
            guard let passwordHash = MTPBKDF2(passwordData, nextSalt, iterations) else {
                return nil
            }
            return (passwordHash, .PBKDF2_HMAC_sha512(salt: nextSalt, iterations: iterations))
    }
}

func securePasswordKDF(password: String, derivation: TwoStepSecurePasswordDerivation) -> Data? {
    guard let passwordData = password.data(using: .utf8, allowLossyConversion: true) else {
        return nil
    }
    
    switch derivation {
        case .unknown:
            return nil
        case let .sha512(salt):
            var data = Data()
            data.append(salt)
            data.append(passwordData)
            data.append(salt)
            return sha512Digest(data)
        case let .PBKDF2_HMAC_sha512(salt, iterations):
            guard let passwordHash = MTPBKDF2(passwordData, salt, iterations) else {
                return nil
            }
            return passwordHash
    }
}

func verifyPassword(_ account: UnauthorizedAccount, password: String) -> Signal<Api.auth.Authorization, MTRpcError> {
    return _internal_twoStepAuthData(account.network)
    |> mapToSignal { authData -> Signal<Api.auth.Authorization, MTRpcError> in
        guard let currentPasswordDerivation = authData.currentPasswordDerivation, let srpSessionData = authData.srpSessionData else {
            return .fail(MTRpcError(errorCode: 400, errorDescription: "INTERNAL_NO_PASSWORD"))
        }
        
        let kdfResult = passwordKDF(encryptionProvider: account.network.encryptionProvider, password: password, derivation: currentPasswordDerivation, srpSessionData: srpSessionData)
        
        if let kdfResult = kdfResult {
            return account.network.request(Api.functions.auth.checkPassword(password: .inputCheckPasswordSRP(srpId: kdfResult.id, A: Buffer(data: kdfResult.A), M1: Buffer(data: kdfResult.M1))), automaticFloodWait: false)
        } else {
            return .fail(MTRpcError(errorCode: 400, errorDescription: "KDF_ERROR"))
        }
    }
}

public enum AccountServiceTaskMasterMode {
    case now
    case always
    case never
}

public struct AccountNetworkProxyState: Equatable {
    public let address: String
    public let hasConnectionIssues: Bool
}

public enum AccountNetworkState: Equatable {
    case waitingForNetwork
    case connecting(proxy: AccountNetworkProxyState?)
    case updating(proxy: AccountNetworkProxyState?)
    case online(proxy: AccountNetworkProxyState?)
}

public final class AccountAuxiliaryMethods {
    public let fetchResource: (Postbox, MediaResource, Signal<[(Range<Int64>, MediaBoxFetchPriority)], NoError>, MediaResourceFetchParameters?) -> Signal<MediaResourceDataFetchResult, MediaResourceDataFetchError>?
    public let fetchResourceMediaReferenceHash: (MediaResource) -> Signal<Data?, NoError>
    public let prepareSecretThumbnailData: (MediaResourceData) -> (PixelDimensions, Data)?
    public let backgroundUpload: (Postbox, Network, MediaResource) -> Signal<String?, NoError>
    
    public init(fetchResource: @escaping (Postbox, MediaResource, Signal<[(Range<Int64>, MediaBoxFetchPriority)], NoError>, MediaResourceFetchParameters?) -> Signal<MediaResourceDataFetchResult, MediaResourceDataFetchError>?, fetchResourceMediaReferenceHash: @escaping (MediaResource) -> Signal<Data?, NoError>, prepareSecretThumbnailData: @escaping (MediaResourceData) -> (PixelDimensions, Data)?, backgroundUpload: @escaping (Postbox, Network, MediaResource) -> Signal<String?, NoError>) {
        self.fetchResource = fetchResource
        self.fetchResourceMediaReferenceHash = fetchResourceMediaReferenceHash
        self.prepareSecretThumbnailData = prepareSecretThumbnailData
        self.backgroundUpload = backgroundUpload
    }
}

public struct AccountRunningImportantTasks: OptionSet {
    public var rawValue: Int32
    
    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }
    
    public static let other = AccountRunningImportantTasks(rawValue: 1 << 0)
    public static let pendingMessages = AccountRunningImportantTasks(rawValue: 1 << 1)
}

public struct MasterNotificationKey: Codable {
    public let id: Data
    public let data: Data

    public init(id: Data, data: Data) {
        self.id = id
        self.data = data
    }
}

public func masterNotificationsKey(account: Account, ignoreDisabled: Bool) -> Signal<MasterNotificationKey, NoError> {
    return masterNotificationsKey(masterNotificationKeyValue: account.masterNotificationKey, postbox: account.postbox, ignoreDisabled: ignoreDisabled, createIfNotExists: true)
    |> map { value -> MasterNotificationKey in
        return value!
    }
}

public func existingMasterNotificationsKey(postbox: Postbox) -> Signal<MasterNotificationKey?, NoError> {
    let value = Atomic<MasterNotificationKey?>(value: nil)
    return masterNotificationsKey(masterNotificationKeyValue: value, postbox: postbox, ignoreDisabled: true, createIfNotExists: false)
}

private func masterNotificationsKey(masterNotificationKeyValue: Atomic<MasterNotificationKey?>, postbox: Postbox, ignoreDisabled: Bool, createIfNotExists: Bool) -> Signal<MasterNotificationKey?, NoError> {
    if let key = masterNotificationKeyValue.with({ $0 }) {
        return .single(key)
    }

    return postbox.transaction(ignoreDisabled: ignoreDisabled, { transaction -> MasterNotificationKey? in
        let result = masterNotificationsKey(transaction: transaction, createIfNotExists: createIfNotExists)
        let _ = masterNotificationKeyValue.swap(result)
        return result
    })
}

func masterNotificationsKey(transaction: Transaction, createIfNotExists: Bool) -> MasterNotificationKey? {
    if let value = transaction.keychainEntryForKey("master-notification-secret"), !value.isEmpty {
        let authKeyHash = sha1Digest(value)
        let authKeyId = authKeyHash.subdata(in: authKeyHash.count - 8 ..< authKeyHash.count)
        let keyData = MasterNotificationKey(id: authKeyId, data: value)
        return keyData
    } else if createIfNotExists {
        var secretData = Data(count: 256)
        let secretDataCount = secretData.count
        if !secretData.withUnsafeMutableBytes({ rawBytes -> Bool in
            let bytes = rawBytes.baseAddress!.assumingMemoryBound(to: Int8.self)
            let copyResult = SecRandomCopyBytes(nil, secretDataCount, bytes)
            return copyResult == errSecSuccess
        }) {
            assertionFailure()
        }

        transaction.setKeychainEntry(secretData, forKey: "master-notification-secret")
        let authKeyHash = sha1Digest(secretData)
        let authKeyId = authKeyHash.subdata(in: authKeyHash.count - 8 ..< authKeyHash.count)
        let keyData = MasterNotificationKey(id: authKeyId, data: secretData)
        return keyData
    } else {
        return nil
    }
}

public func notificationPayloadKeyId(data: Data) -> Data? {
    if data.count < 8 {
        return nil
    }

    return data.subdata(in: 0 ..< 8)
}

public func decryptedNotificationPayload(key: MasterNotificationKey, data: Data) -> Data? {
    if data.count < 8 {
        return nil
    }
    
    if data.subdata(in: 0 ..< 8) != key.id {
        return nil
    }
    
    let x = 8
    let msgKey = data.subdata(in: 8 ..< (8 + 16))
    let rawData = data.subdata(in: (8 + 16) ..< data.count)
    let sha256_a = sha256Digest(msgKey + key.data.subdata(in: x ..< (x + 36)))
    let sha256_b = sha256Digest(key.data.subdata(in: (40 + x) ..< (40 + x + 36)) + msgKey)
    let aesKey = sha256_a.subdata(in: 0 ..< 8) + sha256_b.subdata(in: 8 ..< (8 + 16)) + sha256_a.subdata(in: 24 ..< (24 + 8))
    let aesIv = sha256_b.subdata(in: 0 ..< 8) + sha256_a.subdata(in: 8 ..< (8 + 16)) + sha256_b.subdata(in: 24 ..< (24 + 8))
    
    guard let data = MTAesDecrypt(rawData, aesKey, aesIv), data.count > 4 else {
        return nil
    }
    
    var dataLength: Int32 = 0
    data.withUnsafeBytes { rawBytes -> Void in
        let bytes = rawBytes.baseAddress!.assumingMemoryBound(to: Int8.self)
        memcpy(&dataLength, bytes, 4)
    }
    
    if dataLength < 0 || dataLength > data.count - 4 {
        return nil
    }
    
    let checkMsgKeyLarge = sha256Digest(key.data.subdata(in: (88 + x) ..< (88 + x + 32)) + data)
    let checkMsgKey = checkMsgKeyLarge.subdata(in: 8 ..< (8 + 16))
    
    if checkMsgKey != msgKey {
        return nil
    }
    
    return data.subdata(in: 4 ..< (4 + Int(dataLength)))
}

public func decryptedNotificationPayload(account: Account, data: Data) -> Signal<Data?, NoError> {
    return masterNotificationsKey(masterNotificationKeyValue: account.masterNotificationKey, postbox: account.postbox, ignoreDisabled: true, createIfNotExists: false)
    |> map { secret -> Data? in
        guard let secret = secret else {
            return nil
        }
        return decryptedNotificationPayload(key: secret, data: data)
    }
}

public func accountBackupData(postbox: Postbox) -> Signal<AccountBackupData?, NoError> {
    return postbox.transaction { transaction -> AccountBackupData? in
        guard let state = transaction.getState() as? AuthorizedAccountState else {
            return nil
        }
        guard let authInfoData = transaction.keychainEntryForKey("persistent:datacenterAuthInfoById") else {
            return nil
        }
        guard let authInfo = MTDeprecated.unarchiveDeprecated(with: authInfoData) as? NSDictionary else {
            return nil
        }
        guard let datacenterAuthInfo = authInfo.object(forKey: state.masterDatacenterId as NSNumber) as? MTDatacenterAuthInfo else {
            return nil
        }
        
        var additionalDatacenterKeys: [Int32: AccountBackupData.DatacenterKey] = [:]
        for item in authInfo {
            guard let idNumber = item.key as? NSNumber else {
                continue
            }
            guard let id = idNumber as? Int32 else {
                continue
            }
            if id <= 0 || id > 10 {
                continue
            }
            if id == state.masterDatacenterId {
                continue
            }
            guard let otherDatacenterAuthInfo = authInfo.object(forKey: idNumber) as? MTDatacenterAuthInfo else {
                continue
            }
            guard let otherAuthKey = otherDatacenterAuthInfo.authKey else {
                continue
            }
            additionalDatacenterKeys[id] = AccountBackupData.DatacenterKey(
                id: id,
                keyId: otherDatacenterAuthInfo.authKeyId,
                key: otherAuthKey
            )
        }
        
        guard let authKey = datacenterAuthInfo.authKey else {
            return nil
        }
        let notificationsKey = masterNotificationsKey(transaction: transaction, createIfNotExists: true)
        return AccountBackupData(
            masterDatacenterId: state.masterDatacenterId,
            peerId: state.peerId.toInt64(),
            masterDatacenterKey: authKey,
            masterDatacenterKeyId: datacenterAuthInfo.authKeyId,
            notificationEncryptionKeyId: notificationsKey?.id,
            notificationEncryptionKey: notificationsKey?.data,
            additionalDatacenterKeys: additionalDatacenterKeys
        )
    }
}

public enum NetworkSpeedLimitedEvent {
    public enum DownloadSubject {
        case message(MessageId)
    }
    
    case upload
    case download(DownloadSubject)
}

public class Account {
    static let sharedQueue = Queue(name: "Account-Shared")
    
    public let id: AccountRecordId
    public let basePath: String
    public let testingEnvironment: Bool
    public let supplementary: Bool
    public let isSupportUser: Bool
    public let postbox: Postbox
    public let network: Network
    public let networkArguments: NetworkInitializationArguments
    public let peerId: PeerId
    
    public let auxiliaryMethods: AccountAuxiliaryMethods
    
    private let serviceQueue = Queue()
    
    private let accountManager: AccountManager<TelegramAccountManagerTypes>
    public private(set) var stateManager: AccountStateManager!
    private(set) var contactSyncManager: ContactSyncManager!
    public private(set) var callSessionManager: CallSessionManager!
    
    public private(set) var viewTracker: AccountViewTracker!
    private var resetPeerHoleManagement: ((PeerId) -> Void)?
    
    public private(set) var pendingMessageManager: PendingMessageManager!
    private(set) var pendingStoryManager: PendingStoryManager?
    public private(set) var pendingUpdateMessageManager: PendingUpdateMessageManager!
    private(set) var messageMediaPreuploadManager: MessageMediaPreuploadManager!
    private(set) var mediaReferenceRevalidationContext: MediaReferenceRevalidationContext!
    public private(set) var pendingPeerMediaUploadManager: PendingPeerMediaUploadManager!
    private var peerInputActivityManager: PeerInputActivityManager!
    private var localInputActivityManager: PeerInputActivityManager!
    private var accountPresenceManager: AccountPresenceManager!
    private var notificationAutolockReportManager: NotificationAutolockReportManager!
    fileprivate let managedContactsDisposable = MetaDisposable()
    fileprivate let managedStickerPacksDisposable = MetaDisposable()
    private let becomeMasterDisposable = MetaDisposable()
    private let managedServiceViewsDisposable = MetaDisposable()
    private let managedServiceViewsActionDisposable = MetaDisposable()
    private let managedOperationsDisposable = DisposableSet()
    private var storageSettingsDisposable: Disposable?
    private var automaticCacheEvictionContext: AutomaticCacheEvictionContext?
    
    private var taskManager: AccountTaskManager?
    
    public let importableContacts = Promise<[DeviceContactNormalizedPhoneNumber: ImportableDeviceContactData]>()
    
    public let shouldBeServiceTaskMaster = Promise<AccountServiceTaskMasterMode>()
    public let shouldKeepOnlinePresence = Promise<Bool>()
    public let autolockReportDeadline = Promise<Int32?>()
    public let shouldExplicitelyKeepWorkerConnections = Promise<Bool>(false)
    public let shouldKeepBackgroundDownloadConnections = Promise<Bool>(false)
    
    private let networkStateValue = Promise<AccountNetworkState>(.waitingForNetwork)
    public var networkState: Signal<AccountNetworkState, NoError> {
        return self.networkStateValue.get()
    }
    
    private let networkTypeValue = Promise<NetworkType>()
    public var networkType: Signal<NetworkType, NoError> {
        return self.networkTypeValue.get()
    }
    private let atomicCurrentNetworkType = Atomic<NetworkType>(value: .none)
    public var immediateNetworkType: NetworkType {
        return self.atomicCurrentNetworkType.with { $0 }
    }
    private var networkTypeDisposable: Disposable?
    
    private let _loggedOut = ValuePromise<Bool>(false, ignoreRepeated: true)
    public var loggedOut: Signal<Bool, NoError> {
        return self._loggedOut.get()
    }
    
    private let _importantTasksRunning = ValuePromise<AccountRunningImportantTasks>([], ignoreRepeated: true)
    public var importantTasksRunning: Signal<AccountRunningImportantTasks, NoError> {
        return self._importantTasksRunning.get()
    }
    
    // MARK: Nicegram DB Changes
    public var isHidden: Bool
    private var isHiddenDisposable: Disposable?
    fileprivate let masterNotificationKey = Atomic<MasterNotificationKey?>(value: nil)
    
    var transformOutgoingMessageMedia: TransformOutgoingMessageMedia?
    
    private var lastSmallLogPostTimestamp: Double?
    private let smallLogPostDisposable = MetaDisposable()
    
    let networkStatsContext: NetworkStatsContext
    
    // MARK: Nicegram DB Changes
    public private(set) var keepServiceTaskMasterActiveState = false
    private var keepServiceTaskMasterActiveStateTimer: SwiftSignalKit.Timer?
    //
        
    public let filteredStorySubscriptionsContext: StorySubscriptionsContext?
    public let hiddenStorySubscriptionsContext: StorySubscriptionsContext?
    
    // MARK: Nicegram AccountExporter
    public var shouldKeepConnection = Signal<Bool, NoError>.single(true)
    //
    
    // MARK: Nicegram DB Changes, isHidden
    public init(accountManager: AccountManager<TelegramAccountManagerTypes>, id: AccountRecordId, basePath: String, testingEnvironment: Bool, postbox: Postbox, network: Network, networkArguments: NetworkInitializationArguments, peerId: PeerId, auxiliaryMethods: AccountAuxiliaryMethods, supplementary: Bool, isSupportUser: Bool, isHidden: Bool) {
        self.accountManager = accountManager
        self.id = id
        self.basePath = basePath
        self.testingEnvironment = testingEnvironment
        self.postbox = postbox
        self.network = network
        self.networkArguments = networkArguments
        self.peerId = peerId
        // MARK: Nicegram DB Changes
        self.isHidden = isHidden
        
        self.auxiliaryMethods = auxiliaryMethods
        self.supplementary = supplementary
        self.isSupportUser = isSupportUser
        
        self.networkStatsContext = NetworkStatsContext(postbox: postbox)
        
        self.peerInputActivityManager = PeerInputActivityManager()
        
        if !supplementary {
            self.filteredStorySubscriptionsContext = StorySubscriptionsContext(accountPeerId: peerId, postbox: postbox, network: network, isHidden: false)
            self.hiddenStorySubscriptionsContext = StorySubscriptionsContext(accountPeerId: peerId, postbox: postbox, network: network, isHidden: true)
        } else {
            self.filteredStorySubscriptionsContext = nil
            self.hiddenStorySubscriptionsContext = nil
        }
        
        self.callSessionManager = CallSessionManager(postbox: postbox, network: network, accountPeerId: peerId, maxLayer: networkArguments.voipMaxLayer, versions: networkArguments.voipVersions, addUpdates: { [weak self] updates in
            self?.stateManager?.addUpdates(updates)
        })
        
        self.mediaReferenceRevalidationContext = MediaReferenceRevalidationContext()
        
        self.stateManager = AccountStateManager(accountPeerId: self.peerId, accountManager: accountManager, postbox: self.postbox, network: self.network, callSessionManager: self.callSessionManager, addIsContactUpdates: { [weak self] updates in
            self?.contactSyncManager?.addIsContactUpdates(updates)
        }, shouldKeepOnlinePresence: self.shouldKeepOnlinePresence.get(), peerInputActivityManager: self.peerInputActivityManager, auxiliaryMethods: auxiliaryMethods)
        
        self.viewTracker = AccountViewTracker(account: self)
        self.viewTracker.resetPeerHoleManagement = { [weak self] peerId in
            self?.resetPeerHoleManagement?(peerId)
        }
        
        self.taskManager = AccountTaskManager(
            stateManager: self.stateManager,
            accountManager: accountManager,
            networkArguments: networkArguments,
            viewTracker: self.viewTracker,
            mediaReferenceRevalidationContext: self.mediaReferenceRevalidationContext,
            isMainApp: !supplementary,
            testingEnvironment: testingEnvironment
        )
        
        self.contactSyncManager = ContactSyncManager(postbox: postbox, network: network, accountPeerId: peerId, stateManager: self.stateManager)
        self.localInputActivityManager = PeerInputActivityManager()
        self.accountPresenceManager = AccountPresenceManager(shouldKeepOnlinePresence: self.shouldKeepOnlinePresence.get(), network: network)
        let _ = (postbox.transaction { transaction -> Void in
            transaction.updatePeerPresencesInternal(presences: [peerId: TelegramUserPresence(status: .present(until: Int32.max - 1), lastActivity: 0)], merge: { _, updated in return updated })
            transaction.setNeedsPeerGroupMessageStatsSynchronization(groupId: Namespaces.PeerGroup.archive, namespace: Namespaces.Message.Cloud)
        }).start()
        self.notificationAutolockReportManager = NotificationAutolockReportManager(deadline: self.autolockReportDeadline.get(), network: network)
        self.autolockReportDeadline.set(
            networkArguments.autolockDeadine
            |> distinctUntilChanged
        )
        
        self.messageMediaPreuploadManager = MessageMediaPreuploadManager()
        self.pendingMessageManager = PendingMessageManager(network: network, postbox: postbox, accountPeerId: peerId, auxiliaryMethods: auxiliaryMethods, stateManager: self.stateManager, localInputActivityManager: self.localInputActivityManager, messageMediaPreuploadManager: self.messageMediaPreuploadManager, revalidationContext: self.mediaReferenceRevalidationContext)
        if !supplementary {
            self.pendingStoryManager = PendingStoryManager(postbox: postbox, network: network, accountPeerId: peerId, stateManager: self.stateManager, messageMediaPreuploadManager: self.messageMediaPreuploadManager, revalidationContext: self.mediaReferenceRevalidationContext, auxiliaryMethods: self.auxiliaryMethods)
        } else {
            self.pendingStoryManager = nil
        }
        self.pendingUpdateMessageManager = PendingUpdateMessageManager(postbox: postbox, network: network, stateManager: self.stateManager, messageMediaPreuploadManager: self.messageMediaPreuploadManager, mediaReferenceRevalidationContext: self.mediaReferenceRevalidationContext)
        self.pendingPeerMediaUploadManager = PendingPeerMediaUploadManager(postbox: postbox, network: network, stateManager: self.stateManager, accountPeerId: self.peerId)
        
        self.network.loggedOut = { [weak self] in
            Logger.shared.log("Account", "network logged out")
            if let strongSelf = self {
                strongSelf._loggedOut.set(true)
                strongSelf.callSessionManager.dropAll()
            }
        }
        self.network.didReceiveSoftAuthResetError = { [weak self] in
            self?.postSmallLogIfNeeded()
        }
        
        let networkStateQueue = Queue()
        // MARK: Nicegram DB Changes
        self.isHiddenDisposable = (accountManager.accountRecords()
        |> map { view -> Bool in
            return view.records.first(where: { $0.id == id })?.attributes.contains(where: { $0.isHiddenAccountAttribute }) ?? false
        }
        |> distinctUntilChanged(isEqual: ==)
        |> deliverOnMainQueue).start(next: { [weak self] isHidden in
            guard let strongSelf = self else { return }
            
            strongSelf.isHidden = isHidden
        })
        
        let networkStateSignal = combineLatest(queue: networkStateQueue, self.stateManager.isUpdating, network.connectionStatus)
        |> map { isUpdating, connectionStatus -> AccountNetworkState in
            switch connectionStatus {
                case .waitingForNetwork:
                    return .waitingForNetwork
                case let .connecting(proxyAddress, proxyHasConnectionIssues):
                    var proxyState: AccountNetworkProxyState?
                    if let proxyAddress = proxyAddress {
                        proxyState = AccountNetworkProxyState(address: proxyAddress, hasConnectionIssues: proxyHasConnectionIssues)
                    }
                    return .connecting(proxy: proxyState)
                case let .updating(proxyAddress):
                    var proxyState: AccountNetworkProxyState?
                    if let proxyAddress = proxyAddress {
                        proxyState = AccountNetworkProxyState(address: proxyAddress, hasConnectionIssues: false)
                    }
                    return .updating(proxy: proxyState)
                case let .online(proxyAddress):
                    var proxyState: AccountNetworkProxyState?
                    if let proxyAddress = proxyAddress {
                        proxyState = AccountNetworkProxyState(address: proxyAddress, hasConnectionIssues: false)
                    }
                    
                    if isUpdating {
                        return .updating(proxy: proxyState)
                    } else {
                        return .online(proxy: proxyState)
                    }
            }
        }
        self.networkStateValue.set(networkStateSignal
        |> distinctUntilChanged)
        
        self.networkTypeValue.set(currentNetworkType())
        let atomicCurrentNetworkType = self.atomicCurrentNetworkType
        self.networkTypeDisposable = self.networkTypeValue.get().start(next: { value in
            let _ = atomicCurrentNetworkType.swap(value)
        })
        
        let serviceTasksMasterBecomeMaster = self.shouldBeServiceTaskMaster.get()
        |> distinctUntilChanged
        |> deliverOn(self.serviceQueue)
        
        self.becomeMasterDisposable.set(serviceTasksMasterBecomeMaster.start(next: { [weak self] value in
            if let strongSelf = self, (value == .now || value == .always) {
                strongSelf.postbox.becomeMasterClient()
            }
        }))
        
        let shouldBeMaster = combineLatest(self.shouldBeServiceTaskMaster.get(), postbox.isMasterClient())
        |> map { [weak self] shouldBeMaster, isMaster -> Bool in
            if shouldBeMaster == .always && !isMaster {
                self?.postbox.becomeMasterClient()
            }
            return (shouldBeMaster == .now || shouldBeMaster == .always) && isMaster
        }
        |> distinctUntilChanged
        
        // MARK: Nicegram AccountExporter, save signal before set to network.shouldKeepConnection
        self.shouldKeepConnection = shouldBeMaster
        //
        self.network.shouldKeepConnection.set(shouldBeMaster)
        self.network.shouldExplicitelyKeepWorkerConnections.set(self.shouldExplicitelyKeepWorkerConnections.get())
        self.network.shouldKeepBackgroundDownloadConnections.set(self.shouldKeepBackgroundDownloadConnections.get())
        
        self.managedServiceViewsDisposable.set(shouldBeMaster.start(next: { [weak self] value in
            guard let strongSelf = self else {
                return
            }
            
            if value {
                Logger.shared.log("Account", "Became master")
                let data = managedServiceViews(accountPeerId: peerId, network: network, postbox: postbox, stateManager: strongSelf.stateManager, pendingMessageManager: strongSelf.pendingMessageManager)
                
                let resetPeerHoles = data.resetPeerHoles
                strongSelf.resetPeerHoleManagement = { peerId in
                    resetPeerHoles(peerId)
                }
                strongSelf.managedServiceViewsActionDisposable.set(data.disposable)
            } else {
                Logger.shared.log("Account", "Resigned master")
                strongSelf.managedServiceViewsActionDisposable.set(nil)
            }
        }))
        
        let pendingMessageManager = self.pendingMessageManager
        Logger.shared.log("Account", "Begin watching unsent message ids")
        self.managedOperationsDisposable.add(postbox.unsentMessageIdsView().start(next: { [weak pendingMessageManager] view in
            pendingMessageManager?.updatePendingMessageIds(view.ids)
        }))
        
        self.managedOperationsDisposable.add(managedSecretChatOutgoingOperations(auxiliaryMethods: auxiliaryMethods, postbox: self.postbox, network: self.network, accountPeerId: peerId, mode: .all).start())
        self.managedOperationsDisposable.add(managedCloudChatRemoveMessagesOperations(postbox: self.postbox, network: self.network, stateManager: self.stateManager).start())
        self.managedOperationsDisposable.add(managedAutoremoveMessageOperations(network: self.network, postbox: self.postbox, isRemove: true).start())
        self.managedOperationsDisposable.add(managedAutoremoveMessageOperations(network: self.network, postbox: self.postbox, isRemove: false).start())
        self.managedOperationsDisposable.add(managedAutoexpireStoryOperations(network: self.network, postbox: self.postbox).start())
        self.managedOperationsDisposable.add(managedPeerTimestampAttributeOperations(network: self.network, postbox: self.postbox).start())
        self.managedOperationsDisposable.add(managedSynchronizeViewStoriesOperations(postbox: self.postbox, network: self.network, stateManager: self.stateManager).start())
        self.managedOperationsDisposable.add(managedSynchronizePeerStoriesOperations(postbox: self.postbox, network: self.network, stateManager: self.stateManager).start())
        self.managedOperationsDisposable.add(managedLocalTypingActivities(activities: self.localInputActivityManager.allActivities(), postbox: self.stateManager.postbox, network: self.stateManager.network, accountPeerId: self.stateManager.accountPeerId).start())
        
        let extractedExpr1: [Signal<AccountRunningImportantTasks, NoError>] = [
            managedSynchronizeChatInputStateOperations(postbox: self.postbox, network: self.network) |> map { inputStates in
                if inputStates {
                    //print("inputStates: true")
                }
                return inputStates ? AccountRunningImportantTasks.other : []
            },
            self.pendingMessageManager.hasPendingMessages |> map { hasPendingMessages in
                if !hasPendingMessages.isEmpty {
                    //print("hasPendingMessages: true")
                }
                return !hasPendingMessages.isEmpty ? AccountRunningImportantTasks.pendingMessages : []
            },
            (self.pendingStoryManager?.hasPending ?? .single(false)) |> map { hasPending in
                if hasPending {
                    //print("hasPending: true")
                }
                return hasPending ? AccountRunningImportantTasks.pendingMessages : []
            },
            self.pendingUpdateMessageManager.updatingMessageMedia |> map { updatingMessageMedia in
                if !updatingMessageMedia.isEmpty {
                    //print("updatingMessageMedia: true")
                }
                return !updatingMessageMedia.isEmpty ? AccountRunningImportantTasks.pendingMessages : []
            },
            self.pendingPeerMediaUploadManager.uploadingPeerMedia |> map { uploadingPeerMedia in
                if !uploadingPeerMedia.isEmpty {
                    //print("uploadingPeerMedia: true")
                }
                return !uploadingPeerMedia.isEmpty ? AccountRunningImportantTasks.pendingMessages : []
            },
            self.accountPresenceManager.isPerformingUpdate() |> map { presenceUpdate in
                if presenceUpdate {
                    //print("accountPresenceManager isPerformingUpdate: true")
                    //return []
                }
                return presenceUpdate ? AccountRunningImportantTasks.other : []
            },
            //self.notificationAutolockReportManager.isPerformingUpdate() |> map { $0 ? AccountRunningImportantTasks.other : [] }
        ]
        let extractedExpr: [Signal<AccountRunningImportantTasks, NoError>] = extractedExpr1
        let importantBackgroundOperations: [Signal<AccountRunningImportantTasks, NoError>] = extractedExpr
        let importantBackgroundOperationsRunning = combineLatest(queue: Queue(), importantBackgroundOperations)
        |> map { values -> AccountRunningImportantTasks in
            var result: AccountRunningImportantTasks = []
            for value in values {
                result.formUnion(value)
            }
            return result
        }
        
        self.managedOperationsDisposable.add(importantBackgroundOperationsRunning.start(next: { [weak self] value in
            if let strongSelf = self {
                strongSelf._importantTasksRunning.set(value)
            }
        }))
        self.managedOperationsDisposable.add((accountManager.sharedData(keys: [SharedDataKeys.proxySettings])
        |> map { sharedData -> ProxyServerSettings? in
            if let settings = sharedData.entries[SharedDataKeys.proxySettings]?.get(ProxySettings.self) {
                return settings.effectiveActiveServer
            } else {
                return nil
            }
        }
        |> distinctUntilChanged).start(next: { activeServer in
            let updated = activeServer.flatMap { activeServer -> MTSocksProxySettings? in
                return activeServer.mtProxySettings
            }
            network.context.updateApiEnvironment { environment in
                let current = environment?.socksProxySettings
                let updateNetwork: Bool
                if let current = current, let updated = updated {
                    updateNetwork = !current.isEqual(updated)
                } else {
                    updateNetwork = (current != nil) != (updated != nil)
                }
                if updateNetwork {
                    network.dropConnectionStatus()
                    return environment?.withUpdatedSocksProxySettings(updated)
                } else {
                    return nil
                }
            }
        }))

        if !supplementary {
            let mediaBox = postbox.mediaBox
            let _ = (accountManager.sharedData(keys: [SharedDataKeys.cacheStorageSettings])
            |> take(1)).start(next: { [weak mediaBox] sharedData in
                guard let mediaBox = mediaBox else {
                    return
                }
                let settings: CacheStorageSettings = sharedData.entries[SharedDataKeys.cacheStorageSettings]?.get(CacheStorageSettings.self) ?? CacheStorageSettings.defaultSettings
                mediaBox.setMaxStoreTimes(general: settings.defaultCacheStorageTimeout, shortLived: 60 * 60, gigabytesLimit: settings.defaultCacheStorageLimitGigabytes)
            })
        }
        
        let _ = masterNotificationsKey(masterNotificationKeyValue: self.masterNotificationKey, postbox: self.postbox, ignoreDisabled: false, createIfNotExists: true).start(next: { key in
            let encoder = JSONEncoder()
            if let data = try? encoder.encode(key) {
                let _ = try? data.write(to: URL(fileURLWithPath: "\(basePath)/notificationsKey"))
            }
        })
        
        self.stateManager.updateConfigRequested = { [weak self] in
            self?.restartConfigurationUpdates()
            self?.taskManager?.reloadAppConfiguration()
        }
        self.restartConfigurationUpdates()
        
        self.automaticCacheEvictionContext = AutomaticCacheEvictionContext(postbox: postbox, accountManager: accountManager)
        
        /*#if DEBUG
        self.managedOperationsDisposable.add(debugFetchAllStickers(account: self).start(completed: {
            print("debugFetchAllStickers done")
        }))
        #endif*/
    }
    
    // MARK: Nicegram DB Changes
    deinit {
        self.managedContactsDisposable.dispose()
        self.managedStickerPacksDisposable.dispose()
        self.managedServiceViewsDisposable.dispose()
        self.managedServiceViewsActionDisposable.dispose()
        self.managedOperationsDisposable.dispose()
        self.storageSettingsDisposable?.dispose()
        self.smallLogPostDisposable.dispose()
        self.networkTypeDisposable?.dispose()
        self.isHiddenDisposable?.dispose()
    }
    
    public func temporarilyKeepActive() {
        Queue.mainQueue().async {
            self.keepServiceTaskMasterActiveState = true
            self.keepServiceTaskMasterActiveStateTimer?.invalidate()
            self.keepServiceTaskMasterActiveStateTimer = Timer(timeout: 10.0, repeat: false, completion: { [weak self] in
                guard let strongSelf = self else { return }
                
                strongSelf.keepServiceTaskMasterActiveState = false
            }, queue: .mainQueue())
            self.keepServiceTaskMasterActiveStateTimer?.start()
        }
    }
    
    private func restartConfigurationUpdates() {
        self.managedOperationsDisposable.add(managedConfigurationUpdates(accountManager: self.accountManager, postbox: self.postbox, network: self.network).start())
    }
    
    private func postSmallLogIfNeeded() {
        let timestamp = CFAbsoluteTimeGetCurrent()
        if self.lastSmallLogPostTimestamp == nil || self.lastSmallLogPostTimestamp! < timestamp - 30.0 {
            self.lastSmallLogPostTimestamp = timestamp
            let network = self.network
            
            self.smallLogPostDisposable.set((Logger.shared.collectShortLog()
            |> mapToSignal { events -> Signal<Never, NoError> in
                if events.isEmpty {
                    return .complete()
                } else {
                    return network.request(Api.functions.help.saveAppLog(events: events.map { event -> Api.InputAppEvent in
                        return .inputAppEvent(time: event.0, type: "", peer: 0, data: .jsonString(value: event.1))
                    }))
                    |> ignoreValues
                    |> `catch` { _ -> Signal<Never, NoError> in
                        return .complete()
                    }
                }
            }).start())
        }
    }
    
    public func resetStateManagement() {
        self.stateManager.reset()
        self.restartContactManagement()
        self.managedStickerPacksDisposable.set(manageStickerPacks(network: self.network, postbox: self.postbox).start())
        if !self.supplementary {
            self.viewTracker.chatHistoryPreloadManager.start()
        }
    }
    
    public func resetCachedData() {
        self.viewTracker.reset()
    }
    
    public func cleanupTasks(lowImpact: Bool) -> Signal<Never, NoError> {
        let postbox = self.postbox
        
        return _internal_reindexCacheInBackground(account: self, lowImpact: lowImpact)
        |> then(
            Signal { subscriber in
                return postbox.mediaBox.updateResourceIndex(otherResourceContentType: MediaResourceUserContentType.other.rawValue, lowImpact: lowImpact, completion: {
                    subscriber.putCompletion()
                })
            }
        )
    }
    
    public func restartContactManagement() {
        self.contactSyncManager.beginSync(importableContacts: self.importableContacts.get())
    }
    
    public func addAdditionalPreloadHistoryPeerId(peerId: PeerId) -> Disposable {
        return self.viewTracker.chatHistoryPreloadManager.addAdditionalPeerId(peerId: peerId)
    }
    
    public func peerInputActivities(peerId: PeerActivitySpace) -> Signal<[(PeerId, PeerInputActivity)], NoError> {
        return self.peerInputActivityManager.activities(peerId: peerId)
        |> map { activities in
            return activities.map({ ($0.0, $0.1.activity) })
        }
    }
    
    public func allPeerInputActivities() -> Signal<[PeerActivitySpace: [(PeerId, PeerInputActivity)]], NoError> {
        return self.peerInputActivityManager.allActivities()
        |> map { activities in
            var result: [PeerActivitySpace: [(PeerId, PeerInputActivity)]] = [:]
            for (chatPeerId, chatActivities) in activities {
                result[chatPeerId] = chatActivities.map { ($0.0, $0.1.activity) }
            }
            return result
        }
    }
    
    public func updateLocalInputActivity(peerId: PeerActivitySpace, activity: PeerInputActivity, isPresent: Bool) {
        self.localInputActivityManager.transaction { manager in
            if isPresent {
                manager.addActivity(chatPeerId: peerId, peerId: self.peerId, activity: activity)
            } else {
                manager.removeActivity(chatPeerId: peerId, peerId: self.peerId, activity: activity)
            }
        }
    }
    
    public func acquireLocalInputActivity(peerId: PeerActivitySpace, activity: PeerInputActivity) -> Disposable {
        return self.localInputActivityManager.acquireActivity(chatPeerId: peerId, peerId: self.peerId, activity: activity)
    }
    
    public func addUpdates(serializedData: Data) -> Void {
        /*if let object = Api.parse(Buffer(data: serializedData)) {
            self.stateManager.addUpdates()
        }*/
    }
}

public func accountNetworkUsageStats(account: Account, reset: ResetNetworkUsageStats) -> Signal<NetworkUsageStats, NoError> {
    return networkUsageStats(basePath: account.basePath, reset: reset)
}

public func updateAccountNetworkUsageStats(account: Account, category: MediaResourceStatsCategory, delta: NetworkUsageStatsConnectionsEntry) {
    updateNetworkUsageStats(basePath: account.basePath, category: category, delta: delta)
}

public typealias FetchCachedResourceRepresentation = (_ account: Account, _ resource: MediaResource, _ representation: CachedMediaResourceRepresentation) -> Signal<CachedMediaResourceRepresentationResult, NoError>
public typealias TransformOutgoingMessageMedia = (_ postbox: Postbox, _ network: Network, _ media: AnyMediaReference, _ userInteractive: Bool) -> Signal<AnyMediaReference?, NoError>

public func setupAccount(_ account: Account, fetchCachedResourceRepresentation: FetchCachedResourceRepresentation? = nil, transformOutgoingMessageMedia: TransformOutgoingMessageMedia? = nil) {
    account.postbox.mediaBox.fetchResource = { [weak account] resource, intervals, parameters -> Signal<MediaResourceDataFetchResult, MediaResourceDataFetchError> in
        if let strongAccount = account {
            if let result = strongAccount.auxiliaryMethods.fetchResource(strongAccount.postbox, resource, intervals, parameters) {
                return result
            } else if let result = fetchResource(account: strongAccount, resource: resource, intervals: intervals, parameters: parameters) {
                return result
            } else {
                return .never()
            }
        } else {
            return .never()
        }
    }
    
    account.postbox.mediaBox.fetchCachedResourceRepresentation = { [weak account] resource, representation in
        if let strongAccount = account, let fetchCachedResourceRepresentation = fetchCachedResourceRepresentation {
            return fetchCachedResourceRepresentation(strongAccount, resource, representation)
        } else {
            return .never()
        }
    }
    
    account.transformOutgoingMessageMedia = transformOutgoingMessageMedia
    account.pendingMessageManager.transformOutgoingMessageMedia = transformOutgoingMessageMedia
    account.pendingUpdateMessageManager.transformOutgoingMessageMedia = transformOutgoingMessageMedia
}

public func standaloneStateManager(
    accountManager: AccountManager<TelegramAccountManagerTypes>,
    networkArguments: NetworkInitializationArguments,
    id: AccountRecordId,
    encryptionParameters: ValueBoxEncryptionParameters,
    rootPath: String,
    auxiliaryMethods: AccountAuxiliaryMethods
) -> Signal<AccountStateManager?, NoError> {
    let path = "\(rootPath)/\(accountRecordIdPathName(id))"

    let postbox = openPostbox(
        basePath: path + "/postbox",
        seedConfiguration: telegramPostboxSeedConfiguration,
        encryptionParameters: encryptionParameters,
        timestampForAbsoluteTimeBasedOperations: Int32(CFAbsoluteTimeGetCurrent() + NSTimeIntervalSince1970),
        isMainProcess: false,
        isTemporary: false,
        isReadOnly: false,
        useCopy: false,
        useCaches: false,
        removeDatabaseOnError: false
    )
    
    Logger.shared.log("StandaloneStateManager", "Prepare request postbox")

    return postbox
    |> take(1)
    |> mapToSignal { result -> Signal<AccountStateManager?, NoError> in
        switch result {
        case .upgrading:
            Logger.shared.log("StandaloneStateManager", "Received postbox: upgrading")
            
            return .single(nil)
        case .error:
            Logger.shared.log("StandaloneStateManager", "Received postbox: error")
            
            return .single(nil)
        case let .postbox(postbox):
            Logger.shared.log("StandaloneStateManager", "Received postbox: valid")
            
            return accountManager.transaction { transaction -> (LocalizationSettings?, ProxySettings?) in
                return (nil, transaction.getSharedData(SharedDataKeys.proxySettings)?.get(ProxySettings.self))
            }
            |> mapToSignal { localizationSettings, proxySettings -> Signal<AccountStateManager?, NoError> in
                Logger.shared.log("StandaloneStateManager", "Received settings")
                
                return postbox.transaction { transaction -> (PostboxCoding?, LocalizationSettings?, ProxySettings?, NetworkSettings?) in
                    Logger.shared.log("StandaloneStateManager", "Getting state")
                    
                    let state = transaction.getState()

                    return (state, localizationSettings, proxySettings, transaction.getPreferencesEntry(key: PreferencesKeys.networkSettings)?.get(NetworkSettings.self))
                }
                |> mapToSignal { accountState, localizationSettings, proxySettings, networkSettings -> Signal<AccountStateManager?, NoError> in
                    Logger.shared.log("StandaloneStateManager", "Received state")
                    
                    let keychain = makeExclusiveKeychain(id: id, postbox: postbox)

                    if let accountState = accountState {
                        switch accountState {
                        case _ as UnauthorizedAccountState:
                            Logger.shared.log("StandaloneStateManager", "state is UnauthorizedAccountState")
                            
                            return .single(nil)
                        case let authorizedState as AuthorizedAccountState:
                            Logger.shared.log("StandaloneStateManager", "state is valid")
                            
                            return postbox.transaction { transaction -> String? in
                                return (transaction.getPeer(authorizedState.peerId) as? TelegramUser)?.phone
                            }
                            |> mapToSignal { phoneNumber in
                                Logger.shared.log("StandaloneStateManager", "received phone number")
                                
                                let mediaReferenceRevalidationContext = MediaReferenceRevalidationContext()
                                let networkStatsContext = NetworkStatsContext(postbox: postbox)
                                
                                return initializedNetwork(
                                    accountId: id,
                                    arguments: networkArguments,
                                    supplementary: true,
                                    datacenterId: Int(authorizedState.masterDatacenterId),
                                    keychain: keychain,
                                    basePath: path,
                                    testingEnvironment: authorizedState.isTestingEnvironment,
                                    languageCode: localizationSettings?.primaryComponent.languageCode,
                                    proxySettings: proxySettings,
                                    networkSettings: networkSettings,
                                    phoneNumber: phoneNumber,
                                    useRequestTimeoutTimers: false,
                                    appConfiguration: .defaultValue
                                )
                                |> map { network -> AccountStateManager? in
                                    Logger.shared.log("StandaloneStateManager", "received network")
                                    
                                    postbox.mediaBox.fetchResource = { [weak postbox] resource, intervals, parameters -> Signal<MediaResourceDataFetchResult, MediaResourceDataFetchError> in
                                        guard let postbox = postbox else {
                                            return .never()
                                        }
                                        if let result = auxiliaryMethods.fetchResource(
                                            postbox,
                                            resource,
                                            intervals,
                                            parameters
                                        ) {
                                            return result
                                        } else if let result = fetchResource(
                                            accountPeerId: authorizedState.peerId,
                                            postbox: postbox,
                                            network: network,
                                            mediaReferenceRevalidationContext: mediaReferenceRevalidationContext,
                                            networkStatsContext: networkStatsContext,
                                            isTestingEnvironment: authorizedState.isTestingEnvironment,
                                            resource: resource,
                                            intervals: intervals,
                                            parameters: parameters
                                        ) {
                                            return result
                                        } else {
                                            return .never()
                                        }
                                    }
                                    
                                    return AccountStateManager(
                                        accountPeerId: authorizedState.peerId,
                                        accountManager: accountManager,
                                        postbox: postbox,
                                        network: network,
                                        callSessionManager: nil,
                                        addIsContactUpdates: { _ in
                                        },
                                        shouldKeepOnlinePresence: .single(false),
                                        peerInputActivityManager: nil,
                                        auxiliaryMethods: auxiliaryMethods
                                    )
                                }
                            }
                        default:
                            Logger.shared.log("StandaloneStateManager", "Unexpected accountState")
                            
                            assertionFailure("Unexpected accountState \(accountState)")
                            return .single(nil)
                        }
                    } else {
                        return .single(nil)
                    }
                }
            }
        }
    }
}
