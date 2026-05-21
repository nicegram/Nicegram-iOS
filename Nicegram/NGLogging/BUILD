load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "NGLogging",
    module_name = "NGLogging",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    deps = [
		"@swiftpkg_firebase_ios_sdk//:FirebaseAnalytics",
        "@swiftpkg_nicegram_assistant_ios//:FeatAiChatAnalysis",
        "//submodules/TelegramCore:TelegramCore",
		"@swiftpkg_nicegram_assistant_ios//:NGAnalytics",
    ],
    visibility = [
        "//visibility:public",
    ],
)
