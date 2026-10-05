load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "NGUtils",
    module_name = "NGUtils",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ],
    deps = [
        "//submodules/AccountContext",
        "//submodules/ItemListUI",
        "//submodules/Media/ConvertOpusToAAC:ConvertOpusToAAC",
        "//submodules/PhoneNumberFormat",
        "//third-party/webrtc:webrtc_objc",
        "@swiftpkg_nicegram_assistant_ios//:CoreAnalytics",
        "@swiftpkg_nicegram_assistant_ios//:FeatAiChatAnalysis",
        "@swiftpkg_nicegram_assistant_ios//:FeatAttentionEconomy",
        "@swiftpkg_nicegram_assistant_ios//:FeatAuth",
        "@swiftpkg_nicegram_assistant_ios//:FeatCalls",
        "@swiftpkg_nicegram_assistant_ios//:FeatCopilot",
        "@swiftpkg_nicegram_assistant_ios//:FeatSensitiveContentAccess",
        "@swiftpkg_nicegram_assistant_ios//:FeatTgAccountShop",
        "@swiftpkg_nicegram_assistant_ios//:FeatTranscription",
        "@swiftpkg_nicegram_assistant_ios//:FeatUserArchetype",
        "@swiftpkg_nicegram_assistant_ios//:FeatWhitebridge",
        "@swiftpkg_nicegram_assistant_ios//:NGCore",
        "@swiftpkg_nicegram_assistant_ios//:PaywallCore",
    ],
    visibility = [
        "//visibility:public",
    ],
)
