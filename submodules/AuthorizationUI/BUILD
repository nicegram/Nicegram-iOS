load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

NGDEPS = [
    "@swiftpkg_nicegram_assistant_ios//:FeatAccountBackup",
    "@swiftpkg_nicegram_assistant_ios//:FeatAuth",
    "@swiftpkg_nicegram_assistant_ios//:FeatPhoneEntryBanner",
    "@swiftpkg_nicegram_assistant_ios//:FeatOnboarding"
]

swift_library(
    name = "AuthorizationUI",
    module_name = "AuthorizationUI",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        #"-warnings-as-errors",
    ],
    deps = NGDEPS + [
        "//submodules/AsyncDisplayKit:AsyncDisplayKit",
        "//submodules/TelegramCore:TelegramCore",
        "//submodules/Postbox:Postbox",
        "//submodules/Display:Display",
        "//submodules/SSignalKit/SSignalKit",
        "//submodules/SSignalKit/SwiftSignalKit:SwiftSignalKit",
        "//submodules/TextFormat:TextFormat",
        "//submodules/Markdown:Markdown",
        "//submodules/TelegramPresentationData:TelegramPresentationData",
        "//submodules/AccountContext:AccountContext",
        "//submodules/CountrySelectionUI:CountrySelectionUI",
        "//submodules/PhoneNumberFormat:PhoneNumberFormat",
        "//submodules/LegacyComponents:LegacyComponents",
        "//submodules/LegacyMediaPickerUI:LegacyMediaPickerUI",
        "//submodules/PasswordSetupUI:PasswordSetupUI",
        "//submodules/TelegramNotices:TelegramNotices",
        "//submodules/ProgressNavigationButtonNode:ProgressNavigationButtonNode",
        "//submodules/AnimatedStickerNode:AnimatedStickerNode",
        "//submodules/TelegramAnimatedStickerNode:TelegramAnimatedStickerNode",
        "//submodules/SolidRoundedButtonNode:SolidRoundedButtonNode",
        "//submodules/ImageCompression:ImageCompression",
        "//submodules/RMIntro:RMIntro",
        "//submodules/QrCode:QrCode",
        "//submodules/PhoneInputNode:PhoneInputNode",
        "//submodules/CodeInputView:CodeInputView",
        "//submodules/DebugSettingsUI:DebugSettingsUI",
        "//submodules/InvisibleInkDustNode:InvisibleInkDustNode",
        "//submodules/AuthorizationUtils:AuthorizationUtils",
        "//submodules/ManagedAnimationNode:ManagedAnimationNode",
        "//submodules/AlertUI:AlertUI",
        "//submodules/TelegramUI/Components/TextNodeWithEntities:TextNodeWithEntities",
        "//submodules/MoreButtonNode:MoreButtonNode",
        "//submodules/ContextUI:ContextUI",
        "//submodules/InAppPurchaseManager",
        "//submodules/TelegramUI/Components/Premium/PremiumCoinComponent",
    ],
    visibility = [
        "//visibility:public",
    ],
)
