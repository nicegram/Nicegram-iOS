load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

NGDEPS = [
    "@swiftpkg_nicegram_assistant_ios//:Sources_NGAiChatUI",
]

swift_library(
    name = "ChatListHeaderComponent",
    module_name = "ChatListHeaderComponent",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ],
    deps = NGDEPS + [
        "//submodules/SSignalKit/SwiftSignalKit",
        "//submodules/Display",
        "//submodules/ComponentFlow",
        "//submodules/TelegramPresentationData",
        "//submodules/TelegramUI/Components/ChatListTitleView",
        "//submodules/AccountContext",
        "//submodules/AppBundle",
        "//submodules/AsyncDisplayKit",
        "//submodules/AnimationUI",
    ],
    visibility = [
        "//visibility:public",
    ],
)
