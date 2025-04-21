load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

NGDEPS = [
    "//Nicegram/NGUtils:NGUtils",
]

swift_library(
    name = "JoinLinkPreviewUI",
    module_name = "JoinLinkPreviewUI",
    srcs = glob([
		"Sources/**/*.swift",
    ]),
    copts = [
        #"-warnings-as-errors",
    ],
    deps = NGDEPS + [
        "//submodules/SSignalKit/SwiftSignalKit:SwiftSignalKit",
        "//submodules/AsyncDisplayKit:AsyncDisplayKit",
        "//submodules/Display:Display",
        "//submodules/TelegramCore:TelegramCore",
        "//submodules/TelegramPresentationData:TelegramPresentationData",
        "//submodules/AccountContext:AccountContext",
        "//submodules/AlertUI:AlertUI",
        "//submodules/PresentationDataUtils:PresentationDataUtils",
        "//submodules/ShareController:ShareController",
        "//submodules/SelectablePeerNode:SelectablePeerNode",
        "//submodules/UndoUI:UndoUI",
        "//submodules/SolidRoundedButtonNode:SolidRoundedButtonNode",
        "//submodules/ComponentFlow",
        "//submodules/TelegramUI/Components/EmojiStatusComponent",
        "//submodules/TelegramUI/Components/PeerManagement/OldChannelsController",
    ],
    visibility = [
        "//visibility:public",
    ],
)
