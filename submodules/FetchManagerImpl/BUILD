load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "FetchManagerImpl",
    module_name = "FetchManagerImpl",
    srcs = glob([
		"Sources/**/*.swift",
    ]),
    copts = [
        #"-warnings-as-errors",
    ],
    deps = [
        "//submodules/SSignalKit/SwiftSignalKit:SwiftSignalKit",
        "//submodules/Postbox:Postbox",
        "//submodules/TelegramCore:TelegramCore",
        "//submodules/TelegramUIPreferences:TelegramUIPreferences",
        "//submodules/AccountContext:AccountContext",
        "//submodules/MediaPlayer:UniversalMediaPlayer",
        "//submodules/Utils/RangeSet:RangeSet",
        
        # Nicegram downloading feature
        "//submodules/SaveToCameraRoll:SaveToCameraRoll",
        "@swiftpkg_nicegram_assistant_ios//:NGCoreUI",
        "//Nicegram/NGData:NGData",
    ],
    visibility = [
        "//visibility:public",
    ],
)
