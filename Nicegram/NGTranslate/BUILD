load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "NGTranslate",
    module_name = "NGTranslate",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    deps = [
        "@swiftpkg_nicegram_assistant_ios//:FeatSpeechToText",
        "@swiftpkg_nicegram_assistant_ios//:NGCore",
        "//submodules/AccountContext:AccountContext",
        "//submodules/SSignalKit/SwiftSignalKit:SwiftSignalKit",
        "//submodules/TelegramCore:TelegramCore",        
        "//Nicegram/NGLogging:NGLogging",
        "//Nicegram/NGData:NGData",
        "//Nicegram/NGModels:NGModels",
        "//Nicegram/NGStrings:NGStrings",
        "//Nicegram/NGUtils:NGUtils"
    ],
    visibility = [
        "//visibility:public",
    ],
)
