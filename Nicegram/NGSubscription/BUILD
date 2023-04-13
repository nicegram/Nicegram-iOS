load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "NGSubscription",
    module_name = "NGSubscription",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    deps = [
        "@swiftpkg_snapkit//:Sources_SnapKit",
		"@swiftpkg_nicegram_assistant_ios//:Sources_NGCoreUI",
        "//submodules/Markdown:Markdown",
        "//submodules/TelegramPresentationData:TelegramPresentationData",
        "//Nicegram/NGStrings:NGStrings",
        "//Nicegram/SubscriptionAnalytics:SubscriptionAnalytics",
        "//Nicegram/NGLoadingIndicator:NGLoadingIndicator",
        "//Nicegram/NGEnv:NGEnv",
        "//Nicegram/NGTheme:NGTheme",
    ],
    visibility = [
        "//visibility:public",
    ],
)
