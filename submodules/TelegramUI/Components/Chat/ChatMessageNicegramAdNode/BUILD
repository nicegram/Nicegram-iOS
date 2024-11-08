load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

# todo: cleanup
swift_library(
    name = "ChatMessageNicegramAdNode",
    module_name = "ChatMessageNicegramAdNode",
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
