import Foundation
import BuildConfig

public struct NGEnvObj: Decodable {
    public let is_prod: Bool
    public let ng_api_key: String
    public let ng_api_url: String
    public let premium_bundle: String
    public let referral_bot: String
    public let remote_config_cache_duration_seconds: Double
    public let tapjoy_api_key: String
    public let telegram_auth_bot: String
    public let websocket_url: URL
    
    public let wallet: Wallet
    public struct Wallet: Decodable {
        public let keychainGroupIdentifier: String
        public let walletConnectProjectId: String
        public let web3AuthBackupQuestion: String
        public let web3AuthClientId: String
        public let web3AuthVerifier: String
        public let stonfiApiUrl: String
        public let stonfiNicegramApiUrl: String
    }
}

func parseNGEnv() -> NGEnvObj {
    let ngEnv = BuildConfig(baseAppBundleId: Bundle.main.bundleIdentifier!).ngEnv
    let decodedData = Data(base64Encoded: ngEnv)!

    return try! JSONDecoder().decode(NGEnvObj.self, from: decodedData)
}

public var NGENV = parseNGEnv()
