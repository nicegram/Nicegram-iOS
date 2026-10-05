import Foundation
import BuildConfig

public struct NGEnvObj: Decodable {
    public let is_prod: Bool
    public let ng_api_key: String
    public let ng_api_url: String
    public let premium_bundle: String
    public let referral_bot: String
    public let tapjoy_api_key: String
    public let telegram_auth_bot: String
    public let websocket_url: URL
}

func parseNGEnv() -> NGEnvObj {
    let ngEnv = BuildConfig(baseAppBundleId: Bundle.main.bundleIdentifier!).ngEnv
    let decodedData = Data(base64Encoded: ngEnv)!

    return try! JSONDecoder().decode(NGEnvObj.self, from: decodedData)
}

public var NGENV = parseNGEnv()
