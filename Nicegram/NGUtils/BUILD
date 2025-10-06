load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "NGUtils",
    module_name = "NGUtils",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    deps = [
        "//submodules/AccountContext:AccountContext",
        "//submodules/ItemListUI:ItemListUI",
        "//third-party/webrtc:webrtc_objc",
        "@swiftpkg_firebase_ios_sdk//:FirebaseAnalytics",
        "@swiftpkg_nicegram_assistant_ios//:FeatAiChatAnalysis",
        "@swiftpkg_nicegram_assistant_ios//:FeatAttentionEconomy",
        "@swiftpkg_nicegram_assistant_ios//:FeatCalls",
        "@swiftpkg_nicegram_assistant_ios//:NGAnalytics",
        "@swiftpkg_nicegram_wallet_ios//:NicegramWallet",
    ],
    visibility = [
        "//visibility:public",
    ],
)
