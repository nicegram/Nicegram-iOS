load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "AudioBlob",
    module_name = "AudioBlob",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ],
    deps = [
        "//submodules/AsyncDisplayKit",
        "//submodules/Display",
        "//submodules/LegacyComponents",
        "//submodules/MetalEngine",
        # Nicegram NCG-5828 call recording, removed '//submodules/TelegramUI/Components/Calls/CallScreen' (unused here): it closes a cycle CallScreen -> NGCallRecorder -> UndoUI -> AnimatedAvatarSetNode -> AudioBlob -> CallScreen
        "//submodules/TelegramUI/Components/GlassBackgroundComponent",
    ],
    visibility = [
        "//visibility:public",
    ],
)
