load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "NGUtils",
    module_name = "NGUtils",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    deps = [
        "//submodules/AccountContext",
        "//submodules/ItemListUI",
        "//third-party/webrtc:webrtc_objc",
        "@swiftpkg_nicegram_assistant_ios//:CoreAnalytics",
        "@swiftpkg_nicegram_assistant_ios//:FeatAiChatAnalysis",
        "@swiftpkg_nicegram_assistant_ios//:FeatAttentionEconomy",
        "@swiftpkg_nicegram_assistant_ios//:FeatCalls",
        "@swiftpkg_nicegram_assistant_ios//:FeatSensitiveContentAccess",
        "@swiftpkg_nicegram_assistant_ios//:FeatUserArchetype",
        "@swiftpkg_nicegram_wallet_ios//:NicegramWallet",
    ],
    visibility = [
        "//visibility:public",
    ],
)
