load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "HorizontalPeerItem",
    module_name = "HorizontalPeerItem",
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
        "//submodules/SelectablePeerNode:SelectablePeerNode",
        "//submodules/PeerOnlineMarkerNode:PeerOnlineMarkerNode",
        "//submodules/TelegramStringFormatting:TelegramStringFormatting",
        "//submodules/ContextUI:ContextUI",
        "//submodules/AccountContext:AccountContext",
        "//submodules/TelegramUIPreferences",
        "//submodules/TelegramUI/Components/AnimationCache",
        "//submodules/TelegramUI/Components/MultiAnimationRenderer",
    ],
    visibility = [
        "//visibility:public",
    ],
)
