load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

NGDEPS = [
    "//Nicegram/NGUtils:NGUtils",
]

swift_library(
    name = "ChatPresentationInterfaceState",
    module_name = "ChatPresentationInterfaceState",
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
        "//submodules/AccountContext:AccountContext",
        "//submodules/ContextUI:ContextUI",
        "//submodules/ChatInterfaceState:ChatInterfaceState",
        "//submodules/TelegramUIPreferences:TelegramUIPreferences",
        "//submodules/TelegramPresentationData:TelegramPresentationData",
        "//submodules/ChatContextQuery",
        "//submodules/TooltipUI",
        "//submodules/AudioWaveform",
    ],
    visibility = [
        "//visibility:public",
    ],
)
