load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "NGAssistant",
    module_name = "NGAssistant",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    deps = [
        "//submodules/AccountContext:AccountContext",
        "//submodules/Postbox:Postbox",
        "//submodules/TelegramCore:TelegramCore",
        "//Nicegram/NGLoadingIndicator:NGLoadingIndicator",
        "//Nicegram/NGLocalization:NGLocalization",
        "//Nicegram/NGLogging:NGLogging",
        "//Nicegram/NGModels:NGModels",
        "//Nicegram/NGSpecialOffer:NGSpecialOffer",
        "//Nicegram/NGTheme:NGTheme",
		"@swiftpkg_nicegram_assistant_ios//:Sources_NGAiChatUI",
        "@swiftpkg_nicegram_assistant_ios//:Sources_NGAuth",
        "@swiftpkg_nicegram_assistant_ios//:Sources_NGRepoUser",
    ],
    visibility = ["//visibility:public"],

)
