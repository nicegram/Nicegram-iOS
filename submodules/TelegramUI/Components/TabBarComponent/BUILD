load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

NGDEPS = [
    "//Nicegram/NGData",
]

swift_library(
    name = "TabBarComponent",
    module_name = "TabBarComponent",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ],
    deps = NGDEPS + [
        "//submodules/Display",
        "//submodules/TelegramPresentationData",
        "//submodules/ComponentFlow",
        "//submodules/Components/ComponentDisplayAdapters",
        "//submodules/Components/MultilineTextComponent",
        "//submodules/TelegramUI/Components/GlassBackgroundComponent",
        "//submodules/TelegramUI/Components/LottieComponent",
        "//submodules/Components/BundleIconComponent",
        "//submodules/TelegramUI/Components/TextBadgeComponent",
        "//submodules/UIKitRuntimeUtils",
        "//submodules/TelegramUI/Components/LiquidLens",
        "//submodules/AppBundle",
    ],
    visibility = [
        "//visibility:public",
    ],
)
