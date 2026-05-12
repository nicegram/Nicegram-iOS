load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "NGSpeechToText",
    module_name = "NGSpeechToText",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    deps = [
        "//submodules/AccountContext:AccountContext",
        "//submodules/Display:Display",
        "//submodules/ItemListUI:ItemListUI",
        "//submodules/SSignalKit/SwiftSignalKit:SwiftSignalKit",
        "//submodules/TelegramCore:TelegramCore",
        "//submodules/TelegramPresentationData:TelegramPresentationData",
        "//submodules/PresentationDataUtils:PresentationDataUtils",
        "//submodules/TelegramUI/Components/ChatControllerInteraction",
        "//submodules/TranslateUI:TranslateUI",
        "//submodules/Media/ConvertOpusToAAC",
        "//Nicegram/NGUI:NGUI",
        "@swiftpkg_nicegram_assistant_ios//:FeatPremiumUI",
    ],
    visibility = [
        "//visibility:public",
    ],
)
