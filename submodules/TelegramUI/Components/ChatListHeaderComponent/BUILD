load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

NGDEPS = [
    "@swiftpkg_nicegram_assistant_ios//:NGAiChatUI",
    "@swiftpkg_nicegram_assistant_ios//:FeatImagesHubUI",
]

swift_library(
    name = "ChatListHeaderComponent",
    module_name = "ChatListHeaderComponent",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        #"-warnings-as-errors",
    ],
    deps = NGDEPS + [
        "//submodules/SSignalKit/SwiftSignalKit",
        "//submodules/Display",
        "//submodules/ComponentFlow",
        "//submodules/TelegramPresentationData",
        "//submodules/TelegramUI/Components/ChatListTitleView",
        "//submodules/AccountContext",
        "//submodules/TelegramCore",
        "//submodules/AppBundle",
        "//submodules/AsyncDisplayKit",
        "//submodules/AnimationUI",
        "//submodules/TelegramUI/Components/Stories/StoryPeerListComponent",
        "//submodules/Components/ComponentDisplayAdapters",
        "//submodules/SearchUI",
        "//submodules/TelegramUI/Components/MoreHeaderButton",
    ],
    visibility = [
        "//visibility:public",
    ],
)
