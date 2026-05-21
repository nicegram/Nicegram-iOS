import Foundation
import NGEnv
import _NGRemoteConfig

struct AppReviewLogin {
    static var codeURL: String {
        appReviewConfig().loginCodeUrl
    }
    static var phone : String {
        appReviewConfig().loginPhone
    }
    
    static var sendCodeDate: Date?
    static var isActive: Bool {
        sendCodeDate != nil
    }
}

// Remote Config

private func appReviewConfig() -> AppReviewConfig {
    RemoteConfigContainer.shared.remoteConfig().get(
        .init(
            key: "appReviewConfig",
            defaultValue: AppReviewConfig(
                loginPhone: "",
                loginCodeUrl: ""
            )
        )
    )
}

private struct AppReviewConfig: Decodable {
    let loginPhone: String
    let loginCodeUrl: String
}
