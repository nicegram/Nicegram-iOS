load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "SelectablePeerNode",
    module_name = "SelectablePeerNode",
    srcs = glob([
		"Sources/**/*.swift",
    ]),
    copts = [
        #"-warnings-as-errors",
    ],
    deps = [
        "//submodules/SSignalKit/SwiftSignalKit:SwiftSignalKit",
        "//submodules/TelegramCore:TelegramCore",
        "//submodules/Postbox:Postbox",
        "//submodules/AsyncDisplayKit:AsyncDisplayKit",
        "//submodules/Display:Display",
        "//submodules/TelegramPresentationData:TelegramPresentationData",
        "//submodules/PeerOnlineMarkerNode:PeerOnlineMarkerNode",
        "//submodules/AvatarNode:AvatarNode",
        "//submodules/LegacyComponents:LegacyComponents",
        "//submodules/ContextUI:ContextUI",
        "//submodules/LocalizedPeerData:LocalizedPeerData",
        "//submodules/AccountContext:AccountContext",
        "//submodules/CheckNode:CheckNode",
        "//submodules/ComponentFlow:ComponentFlow",
        "//submodules/TelegramUI/Components/EmojiStatusComponent:EmojiStatusComponent",
        "//submodules/TelegramUIPreferences",
        "//submodules/TelegramUI/Components/AnimationCache",
        "//submodules/TelegramUI/Components/MultiAnimationRenderer",
    ],
    visibility = [
        "//visibility:public",
    ],
)
