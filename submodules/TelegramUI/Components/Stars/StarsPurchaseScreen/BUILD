load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

NGDEPS = [
    "//Nicegram/NGStrings:NGStrings",
    "//submodules/TelegramUI/Components/ButtonComponent",
]

swift_library(
    name = "StarsPurchaseScreen",
    module_name = "StarsPurchaseScreen",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        #"-warnings-as-errors",
    ],
    deps = NGDEPS + [
        "//submodules/AsyncDisplayKit",
        "//submodules/Display",
        "//submodules/Postbox",
        "//submodules/TelegramCore",
        "//submodules/SSignalKit/SwiftSignalKit",
        "//submodules/ComponentFlow",
        "//submodules/Components/ViewControllerComponent",
        "//submodules/Components/ComponentDisplayAdapters",
        "//submodules/Components/MultilineTextComponent",
        "//submodules/Components/BalancedTextComponent",
        "//submodules/TelegramPresentationData",
        "//submodules/AccountContext",
        "//submodules/AppBundle",
        "//submodules/ItemListUI",
        "//submodules/TelegramStringFormatting",
        "//submodules/PresentationDataUtils",
        "//submodules/Components/SheetComponent",
        "//submodules/UndoUI",
        "//submodules/TextFormat",
        "//submodules/TelegramUI/Components/ListSectionComponent",
        "//submodules/TelegramUI/Components/ListActionItemComponent",
        "//submodules/TelegramUI/Components/ScrollComponent",
        "//submodules/TelegramUI/Components/TextLoadingEffect",
        "//submodules/TelegramUI/Components/Premium/PremiumStarComponent",
        "//submodules/Components/BlurredBackgroundComponent",
        "//submodules/Components/BundleIconComponent",
        "//submodules/ConfettiEffect",
        "//submodules/AnimatedStickerNode",
        "//submodules/TelegramAnimatedStickerNode",
        "//submodules/TelegramUI/Components/Stars/ItemShimmeringLoadingComponent",
    ],
    visibility = [
        "//visibility:public",
    ],
)
