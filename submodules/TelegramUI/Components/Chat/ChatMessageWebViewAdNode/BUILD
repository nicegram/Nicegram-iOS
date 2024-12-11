load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "ChatMessageWebViewAdNode",
    module_name = "ChatMessageWebViewAdNode",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        #"-warnings-as-errors",
    ],
    deps = [
        "//submodules/AsyncDisplayKit",
        "//submodules/TelegramUI/Components/ChatControllerInteraction",
        "//submodules/TelegramUI/Components/Chat/ChatMessageItemCommon",
        "//submodules/TelegramUI/Components/Chat/ChatMessageItemView",
        "//submodules/Display",
        "//submodules/SSignalKit/SwiftSignalKit",
        "//submodules/TelegramPresentationData",
        "@swiftpkg_nicegram_assistant_ios//:FeatAttentionEconomy",
    ],
    visibility = [
        "//visibility:public",
    ],
)
