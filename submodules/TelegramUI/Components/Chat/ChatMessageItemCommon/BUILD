load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

NGDEPS = [
    "//Nicegram/NGData:NGData",
]

swift_library(
    name = "ChatMessageItemCommon",
    module_name = "ChatMessageItemCommon",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        #"-warnings-as-errors",
    ],
    deps = NGDEPS + [
        "//submodules/Display",
        "//submodules/Postbox",
        "//submodules/TelegramCore",
        "//submodules/Emoji",
    ],
    visibility = [
        "//visibility:public",
    ],
)

