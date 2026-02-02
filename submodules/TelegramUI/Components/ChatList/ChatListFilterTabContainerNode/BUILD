load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

NGDEPS = [
    "//Nicegram/NGStrings",
]

swift_library(
    name = "ChatListFilterTabContainerNode",
    module_name = "ChatListFilterTabContainerNode",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ],
    deps = NGDEPS + [
        "//submodules/AsyncDisplayKit",
        "//submodules/Display",
        "//submodules/TelegramCore",
        "//submodules/TelegramPresentationData",
        "//submodules/TelegramUI/Components/TextNodeWithEntities",
        "//submodules/AccountContext",
        "//submodules/ComponentFlow",
        "//submodules/Components/ComponentDisplayAdapters",
        "//submodules/TelegramUI/Components/GlassBackgroundComponent",
        "//submodules/TelegramUI/Components/LiquidLens",
    ],
    visibility = [
        "//visibility:public",
    ],
)
