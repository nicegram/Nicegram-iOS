import CoreRemoteConfig
import Foundation
import NGEnv

struct AppReviewLogin {
    static var phone : String {
        appReviewConfig().loginPhone
    }
}

// Remote Config

private func appReviewConfig() -> AppReviewConfig {
    RemoteConfigContainer.shared.remoteConfig().get(
        .init(
            key: "appReviewConfig",
            defaultValue: AppReviewConfig(
                loginPhone: ""
            )
        )
    )
}

private struct AppReviewConfig: Decodable {
    let loginPhone: String
}
