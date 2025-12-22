load("@bazel_skylib//rules:common_settings.bzl",
    "bool_flag",
)

load("@bazel_skylib//lib:selects.bzl", "selects")

load("@build_bazel_rules_apple//apple:ios.bzl",
    "ios_application",
    "ios_extension",
    "ios_framework",
    "ios_unit_test",
    "ios_ui_test",
)

load("@build_bazel_rules_apple//apple:resources.bzl",
    "swift_intent_library",
)

load("@build_bazel_rules_swift//swift:swift.bzl",
    "swift_library",
)

load(
    "@rules_xcodeproj//xcodeproj:defs.bzl",
    "top_level_target",
    "top_level_targets",
    "xcodeproj",
    "xcode_provisioning_profile",
)

load("@build_bazel_rules_apple//apple:apple.bzl", "local_provisioning_profile")

load("//build-system/bazel-utils:plist_fragment.bzl",
    "plist_fragment",
)

load(
    "@build_configuration//:variables.bzl",
    "telegram_bazel_path",
    "telegram_use_xcode_managed_codesigning",
    "telegram_bundle_id",
    "telegram_aps_environment",
    "telegram_team_id",
    "telegram_enable_icloud",
    "telegram_enable_siri",
    "google_client_scheme", 
)

load("@build_bazel_rules_apple//apple:resources.bzl",
    "swift_intent_library",
)

load("//build-system/bazel-utils:spm.bzl",
    "generate_spm",
)

config_setting(
    name = "debug",
    values = {
        "compilation_mode": "dbg",
    },
)

bool_flag(
    name = "disableExtensions",
    build_setting_default = False,
    visibility = ["//visibility:public"],
)

bool_flag(
    name = "disableProvisioningProfiles",
    build_setting_default = False,
    visibility = ["//visibility:public"],
)

bool_flag(
    name = "projectIncludeRelease",
    build_setting_default = False,
    visibility = ["//visibility:public"],
)

config_setting(
    name = "disableExtensionsSetting",
    flag_values = {
        ":disableExtensions": "True",
    },
)

config_setting(
    name = "disableProvisioningProfilesSetting",
    flag_values = {
        ":disableProvisioningProfiles": "True",
    },
)

config_setting(
    name = "projectIncludeReleaseSetting",
    flag_values = {
        ":projectIncludeRelease": "True",
    },
)

bool_flag(
    name = "disableStripping",
    build_setting_default = False,
    visibility = ["//visibility:public"],
)

config_setting(
    name = "disableStrippingSetting",
    flag_values = {
        ":disableStripping": "True",
    },
)

genrule(
    name = "empty",
    outs = ["empty.swift"],
    cmd = "touch $(OUTS)",
)

genrule(
    name = "GeneratedPresentationStrings",
    srcs = [
        "//build-system:GenerateStrings/GenerateStrings.py",
        "Telegram-iOS/en.lproj/Localizable.strings",
    ],
    cmd = '''
        python3 $(location //build-system:GenerateStrings/GenerateStrings.py) \\
            --source=$(location Telegram-iOS/en.lproj/Localizable.strings) \\
            --outImplementation=$(location GeneratedPresentationStrings/Sources/PresentationStrings.m) \\
            --outHeader=$(location GeneratedPresentationStrings/PublicHeaders/PresentationStrings/PresentationStrings.h) \\
            --outData=$(location GeneratedPresentationStrings/Resources/PresentationStrings.data) \\
    ''',
    outs = [
        "GeneratedPresentationStrings/PublicHeaders/PresentationStrings/PresentationStrings.h",
        "GeneratedPresentationStrings/Sources/PresentationStrings.m",
        "GeneratedPresentationStrings/Resources/PresentationStrings.data",
    ],
)

minimum_os_version = "14.0"

notificationServiceExtensionVersion = "v1"

empty_languages = [
    "ar",
    "be",
    "ca",
    "de",
    "es",
    "fa",
    "fr",
    "id",
    "it",
    "ko",
    "ms",
    "nl",
    "pl",
    "pt",
    "ru",
    "tr",
    "uk",
    "uz",
]

[
    genrule(
        name = "Localizable_{}.strings".format(language),
        outs = ["{}.lproj/Localizable.strings".format(language)],
        cmd = "touch $(OUTS)",
    ) for language in empty_languages
]

objc_library(
    name = "PresentationStrings",
    enable_modules = True,
    module_name = "PresentationStrings",
    srcs = [
        "GeneratedPresentationStrings/Sources/PresentationStrings.m",
    ],
    hdrs = [
        "GeneratedPresentationStrings/PublicHeaders/PresentationStrings/PresentationStrings.h",
    ],
    includes = [
        "GeneratedPresentationStrings/PublicHeaders",
    ],
    sdk_frameworks = [
        "Foundation",
    ],
    deps = [
        "//submodules/NumberPluralizationForm:NumberPluralizationForm",
        "//submodules/AppBundle:AppBundle",
    ],
    visibility = [
        "//visibility:public",
    ],
)

swift_library(
    name = "_LocalDebugOptions",
    srcs = [":empty"],
    copts = [
        "-Xfrontend",
        "-serialize-debugging-options",
    ],
    deps = [
        "//submodules/AsyncDisplayKit:AsyncDisplayKit",
        "//submodules/AppBundle:AppBundle",
        "//submodules/ObjCRuntimeUtils:ObjCRuntimeUtils",
        "//submodules/UIKitRuntimeUtils:UIKitRuntimeUtils",
        "//submodules/Crc32:Crc32",
        "//submodules/MurMurHash32:MurMurHash32",
        "//submodules/StringTransliteration:StringTransliteration",
        "//submodules/sqlcipher:sqlcipher",
        "//submodules/NumberPluralizationForm:NumberPluralizationForm",
        "//submodules/EncryptionProvider:EncryptionProvider",
        "//submodules/MtProtoKit:MtProtoKit",
    ],
    module_name = "_LocalDebugOptions",
    tags = ["no-remote"],
    visibility = ["//visibility:public"],
)

debug_deps = select({
    ":debug": [":_LocalDebugOptions"],
    "//conditions:default": [],
})

selects.config_setting_group(
    name = "resolvedDisableStrippingSetting",
    match_any = [":debug", ":disableStrippingSetting"],
)

strip_framework = select({
    ":resolvedDisableStrippingSetting": None,
    "//conditions:default": ":StripFramework",
})

filegroup(
    name = "AppResources",
    srcs = glob([
        "Telegram-iOS/Resources/**/*",
    ], exclude = ["Telegram-iOS/Resources/**/.*"]),
)

filegroup(
    name = "AppStringResources",
    srcs = [
        "Telegram-iOS/en.lproj/Localizable.strings",
    ] + [
        "{}.lproj/Localizable.strings".format(language) for language in empty_languages
    ] + glob(
        [
            "Telegram-iOS/*.lproj/NiceLocalizable.strings",
        ]
    )
)

filegroup(
    name = "AppIntentVocabularyResources",
    srcs = glob([
        "Telegram-iOS/*.lproj/AppIntentVocabulary.plist",
    ], exclude = ["Telegram-iOS/*.lproj/**/.*"]),
)

filegroup(
    name = "InfoPlistStringResources",
    srcs = glob([
        "Telegram-iOS/*.lproj/InfoPlist.strings",
    ], exclude = ["Telegram-iOS/*.lproj/**/.*"]),
)

filegroup(
    name = "Icons",
    srcs = glob([
        "Telegram-iOS/Icons.xcassets/**/*",
    ], exclude = ["Telegram-iOS/Icons.xcassets/**/.*"]),
)

filegroup(
    name = "DefaultAppIcon",
    srcs = glob([
        "Telegram-iOS/DefaultAppIcon.xcassets/**/*",
    ], exclude = ["Telegram-iOS/DefaultAppIcon.xcassets/**/.*"]),
)

# Nicegram
filegroup(
    name = "GoogleService-Info",
    srcs = glob([
        "Telegram-iOS/GoogleService-Info.plist",
    ]),
)

# Nicegram
filegroup(
    name = "FirebaseRemoteConfigDefaults",
    srcs = glob([
        "Telegram-iOS/FirebaseRemoteConfigDefaults.plist",
    ], allow_empty=True),
)

# Nicegram AltIcons
# removed BlackClassicIcon, BlueClassicIcon 
alternate_icon_folders = [
    "BlackIcon",
    "BlackFilledIcon",
    "BlueIcon",
    "BlueFilledIcon",
    "WhiteFilledIcon",
    "New1",
    "New2",
    "New3",
    "NicegramAlt",
    "NicegramBetaIcon",
    "CommunityClassic",
    "CommunityOnyx",
    "CommunityRuby",
    "CommunityWatercolor",
    "Premium",
    "PremiumBlack",
    "PremiumTurbo",
    "NewBlack",
    "NewWhite"
]

[
    filegroup(
        name = "{}".format(name),
        srcs = glob([
            "Telegram-iOS/{}.alticon/*.png".format(name),
        ]),
    ) for name in alternate_icon_folders
]

filegroup(
    name = "LaunchScreen",
    srcs = glob([
        "Telegram-iOS/Base.lproj/LaunchScreen.xib",
    ]),
)

objc_library(
    name = "Main",
    srcs = [
        "Telegram-iOS/main.m"
    ],
)

NGRESOURCES = [
    ":FirebaseRemoteConfigDefaults",
    ":GoogleService-Info",
    "//Nicegram/NGResources:NGImagesAssets"
]

NGRESOURCES_DEPS = [
    "//Nicegram/NGResources:NGResources"
]

swift_library(
    name = "Lib",
    srcs = glob([
        "Telegram-iOS/Application.swift",
    ]),
    data = [
        ":Icons",
        ":AppResources",
        ":AppIntentVocabularyResources",
        ":InfoPlistStringResources",
        "//submodules/LegacyComponents:LegacyComponentsResources",
        "//submodules/LegacyComponents:LegacyComponentsAssets",
        "//submodules/OverlayStatusController:OverlayStatusControllerResources",
        "//submodules/PasswordSetupUI:PasswordSetupUIResources",
        "//submodules/PasswordSetupUI:PasswordSetupUIAssets",
        "//submodules/PremiumUI:PremiumUIResources",
        "//submodules/DrawingUI:DrawingUIResources",
        "//submodules/TelegramUI:TelegramUIResources",
        "//submodules/TelegramUI:TelegramUIAssets",
        "//submodules/TelegramUI/Components/Calls/CallScreen:Assets",
        ":GeneratedPresentationStrings/Resources/PresentationStrings.data",
    ] + NGRESOURCES,
    deps = [
        "//submodules/TelegramUI:TelegramUI",
        "//third-party/boringssl:crypto",
    ] + NGRESOURCES_DEPS
)

plist_fragment(
    name = "BuildNumberInfoPlist",
    extension = "plist",
    template =
    """
    <key>CFBundleVersion</key>
    <string>{buildNumber}</string>
    """
)

plist_fragment(
    name = "UrlTypesInfoPlist",
    extension = "plist",
    template =
    """
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
            <key>CFBundleURLName</key>
            <string>{telegram_bundle_id}</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>telegram</string>
                <string>nicegram</string>
            </array>
        </dict>
        <dict>
            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
            <key>CFBundleURLName</key>
            <string>{telegram_bundle_id}.compatibility</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>tg</string>
                <string>tonsite</string>
                <string>ng</string>
                <string>ngcn</string>
                <string>ncg</string>
                <string>tc</string>
                <string>nicegram-tc</string>
                <string>wc</string>
                <string>{google_client_scheme}</string>
            </array>
        </dict>
    </array>
    """.format(
        telegram_bundle_id = telegram_bundle_id,
        google_client_scheme = google_client_scheme,
    )
)

official_apple_pay_merchants = [
    "merchant.ph.telegra.Telegraph",
    "merchant.sberbank.ph.telegra.Telegraph",
    "merchant.sberbank.test.ph.telegra.Telegraph",
    "merchant.privatbank.test.telergramios",
    "merchant.privatbank.prod.telergram",
    "merchant.paymaster.test.telegramios",
    "merchant.paymaster.prod.telegramios",
    "merchant.smartglocal.prod.telegramios",
    "merchant.smartglocal.test.telegramios",
    "merchant.yoomoney.test.telegramios",
    "merchant.yoomoney.prod.telegramios",
    "merchant.org.telegram.Best2pay.test",
    "merchant.psbank.test.telegramios",
    "merchant.psbank.prod.telegramios",
    "merchant.org.telegram.billinenet.test",
    "merchant.org.telegram.billinenet.prod",
    "merchant.org.telegram.portmone.test",
    "merchant.org.telegram.portmone.prod",
    "merchant.org.telegram.ecommpay.test",
]

official_bundle_ids = [
    "ph.telegra.Telegraph",
    "org.telegram.Telegram-iOS",
]

nicegram_bundle_ids = [
    "ph.telegra.Telegraph",
    "org.telegram.Telegram-iOS",
    "app.nicegram",
]

store_bundle_ids = [
    "app.nicegram",
    "ph.telegra.Telegraph",
]

apple_pay_merchants = official_apple_pay_merchants if telegram_bundle_id == "ph.telegra.Telegraph" else []

apple_pay_merchants_fragment = "" if apple_pay_merchants == [] else """
<key>com.apple.developer.in-app-payments</key>
<array>
""" + "\n".join([
"    <string>{merchant_id}</string>".format(merchant_id=merchant_id) for merchant_id in apple_pay_merchants
]) + "\n" + """
</array>
"""

official_unrestricted_voip_fragment = """
<key>com.apple.developer.pushkit.unrestricted-voip</key>
<true/>
"""
unrestricted_voip_fragment = official_unrestricted_voip_fragment if telegram_bundle_id in official_bundle_ids else ""

official_carplay_fragment = """
<key>com.apple.developer.carplay-messaging</key>
<true/>
"""
carplay_fragment = official_carplay_fragment if telegram_bundle_id in official_bundle_ids else ""

icloud_fragment = "" if not telegram_enable_icloud else """
<key>com.apple.developer.icloud-services</key>
<array>
    <string>CloudKit</string>
    <string>CloudDocuments</string>
</array>
<key>com.apple.developer.icloud-container-identifiers</key>
<array>
    <string>iCloud.{telegram_bundle_id}</string>
</array>
<key>com.apple.developer.ubiquity-container-identifiers</key>
<array>
    <string>iCloud.{telegram_bundle_id}</string>
</array>
<key>com.apple.developer.ubiquity-kvstore-identifier</key>
<string>{telegram_team_id}.*</string>
<key>com.apple.developer.icloud-container-environment</key>
<string>{telegram_icloud_environment}</string>
""".format(
    telegram_team_id=telegram_team_id,
    telegram_bundle_id=telegram_bundle_id,
    telegram_icloud_environment="Production" if telegram_aps_environment == "production" else "Development"
)

associated_domains_fragment = "" if telegram_bundle_id not in nicegram_bundle_ids else """
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:telegram.me</string>
    <string>applinks:t.me</string>
    <string>applinks:nicegram.app</string>
    <string>applinks:yfqcuhfv.xyz</string>
    <string>applinks:*.t.me</string>
    <string>webcredentials:t.me</string>
    <string>webcredentials:telegram.org</string>
</array>
"""

siri_fragment = "" if not telegram_enable_siri else """
<key>com.apple.developer.siri</key>
<true/>
"""

aps_fragment = "" if telegram_aps_environment == "" else """
<key>aps-environment</key>
<string>{telegram_aps_environment}</string>
""".format(telegram_aps_environment=telegram_aps_environment)

app_groups_fragment = """
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.{telegram_bundle_id}</string>
    </array>
    <key>application-identifier</key>
    <string>{telegram_team_id}.{telegram_bundle_id}</string>
""".format(
    telegram_team_id=telegram_team_id,
    telegram_bundle_id=telegram_bundle_id
)

official_communication_notifications_fragment = """
<key>com.apple.developer.usernotifications.communication</key>
<true/>
"""
# Nicegram, change 'official_bundle_ids' to 'nicegram_bundle_ids'
communication_notifications_fragment = official_communication_notifications_fragment if telegram_bundle_id in nicegram_bundle_ids else ""

official_notification_filtering_fragment = """
<key>com.apple.developer.usernotifications.filtering</key>
<true/>
"""
notification_filtering_fragment = official_notification_filtering_fragment if telegram_bundle_id == "ph.telegra.Telegraph" else ""

store_signin_fragment = """
<key>com.apple.developer.applesignin</key>
<array>
    <string>Default</string>
</array>
"""
signin_fragment = store_signin_fragment if telegram_bundle_id in store_bundle_ids else ""

# Nicegram, keychain_access_groups_fragment
keychain_access_groups_fragment = """
    <key>keychain-access-groups</key>
    <array>
        <string>{telegram_team_id}.{telegram_bundle_id}</string>
    </array>
""".format(
    telegram_team_id=telegram_team_id,
    telegram_bundle_id=telegram_bundle_id
)

plist_fragment(
    name = "TelegramEntitlements",
    extension = "entitlements",
    template = "".join([
        aps_fragment,
        app_groups_fragment,
        siri_fragment,
        associated_domains_fragment,
        icloud_fragment,
        apple_pay_merchants_fragment,
        unrestricted_voip_fragment,
        carplay_fragment,
        communication_notifications_fragment,
        notification_filtering_fragment,
        signin_fragment,
        # Nicegram, keychain_access_groups_fragment
        keychain_access_groups_fragment
    ])
)

plist_fragment(
    name = "VersionInfoPlist",
    extension = "plist",
    template =
    """
    <key>CFBundleShortVersionString</key>
    <string>{telegramVersion}</string>
    """
)

plist_fragment(
    name = "RequiredDeviceCapabilitiesPlist",
    extension = "plist",
    template =
    """
    <key>UIRequiredDeviceCapabilities</key>
    <array>
        <string>arm64</string>
    </array>
    """
)

plist_fragment(
    name = "AppNameInfoPlist",
    extension = "plist",
    template =
    """
    <key>CFBundleDisplayName</key>
    <string>Nicegram</string>
    """
)

plist_fragment( 
    name = "MtProtoKitInfoPlist",
    extension = "plist",
    template =
    """
    <key>CFBundleIdentifier</key>
    <string>{telegram_bundle_id}.MtProtoKit</string>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleName</key>
    <string>MtProtoKit</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    """.format(
        telegram_bundle_id = telegram_bundle_id,
    )
)

ios_framework(
    name = "MtProtoKitFramework",
    bundle_id = "{telegram_bundle_id}.MtProtoKit".format(
        telegram_bundle_id = telegram_bundle_id,
    ),
    families = [
        "iphone",
        "ipad",
    ],
    infoplists = [
        ":MtProtoKitInfoPlist",
        ":BuildNumberInfoPlist",
        ":VersionInfoPlist",
        ":RequiredDeviceCapabilitiesPlist",
    ],
    minimum_os_version = minimum_os_version,
    extension_safe = True,
    ipa_post_processor = strip_framework,
    deps = [
        "//submodules/MtProtoKit:MtProtoKit",
    ],
)

plist_fragment(
    name = "SwiftSignalKitInfoPlist",
    extension = "plist",
    template =
    """
    <key>CFBundleIdentifier</key>
    <string>{telegram_bundle_id}.SwiftSignalKit</string>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleName</key>
    <string>SwiftSignalKit</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    """.format(
        telegram_bundle_id = telegram_bundle_id,
    )
)

ios_framework(
    name = "SwiftSignalKitFramework",
    bundle_id = "{telegram_bundle_id}.SwiftSignalKit".format(
        telegram_bundle_id = telegram_bundle_id,
    ),
    families = [
        "iphone",
        "ipad",
    ],
    infoplists = [
        ":SwiftSignalKitInfoPlist",
        ":BuildNumberInfoPlist",
        ":VersionInfoPlist",
        ":RequiredDeviceCapabilitiesPlist",
    ],
    minimum_os_version = minimum_os_version,
    extension_safe = True,
    ipa_post_processor = strip_framework,
    deps = [
        "//submodules/SSignalKit/SwiftSignalKit:SwiftSignalKit",
    ],
)

plist_fragment(
    name = "PostboxInfoPlist",
    extension = "plist",
    template =
    """
    <key>CFBundleIdentifier</key>
    <string>{telegram_bundle_id}.Postbox</string>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleName</key>
    <string>Postbox</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    """.format(
        telegram_bundle_id = telegram_bundle_id,
    )
)

ios_framework(
    name = "PostboxFramework",
    bundle_id = "{telegram_bundle_id}.Postbox".format(
        telegram_bundle_id = telegram_bundle_id,
    ),
    families = [
        "iphone",
        "ipad",
    ],
    infoplists = [
        ":PostboxInfoPlist",
        ":BuildNumberInfoPlist",
        ":VersionInfoPlist",
        ":RequiredDeviceCapabilitiesPlist",
    ],
    frameworks = [
        ":SwiftSignalKitFramework",
    ],
    minimum_os_version = minimum_os_version,
    extension_safe = True,
    ipa_post_processor = strip_framework,
    deps = [
        "//submodules/Postbox:Postbox",
    ],
)

plist_fragment(
    name = "TelegramApiInfoPlist",
    extension = "plist",
    template =
    """
    <key>CFBundleIdentifier</key>
    <string>{telegram_bundle_id}.TelegramApi</string>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleName</key>
    <string>TelegramApi</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    """.format(
        telegram_bundle_id = telegram_bundle_id,
    )
)

plist_fragment(
    name = "TelegramCoreInfoPlist",
    extension = "plist",
    template =
    """
    <key>CFBundleIdentifier</key>
    <string>{telegram_bundle_id}.TelegramCore</string>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleName</key>
    <string>TelegramCore</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    """.format(
        telegram_bundle_id = telegram_bundle_id,
    )
)

ios_framework(
    name = "TelegramCoreFramework",
    bundle_id = "{telegram_bundle_id}.TelegramCore".format(
        telegram_bundle_id = telegram_bundle_id,
    ),
    families = [
        "iphone",
        "ipad",
    ],
    infoplists = [
        ":TelegramCoreInfoPlist",
        ":BuildNumberInfoPlist",
        ":VersionInfoPlist",
        ":RequiredDeviceCapabilitiesPlist",
    ],
    frameworks = [
        ":MtProtoKitFramework",
        ":SwiftSignalKitFramework",
        ":PostboxFramework",
    ],
    minimum_os_version = minimum_os_version,
    extension_safe = True,
    ipa_post_processor = strip_framework,
    deps = [
        "//submodules/TelegramCore:TelegramCore",
    ],
    visibility = [
        "//visibility:public",
    ]
)

plist_fragment(
    name = "AsyncDisplayKitInfoPlist",
    extension = "plist",
    template =
    """
    <key>CFBundleIdentifier</key>
    <string>{telegram_bundle_id}.AsyncDisplayKit</string>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleName</key>
    <string>AsyncDisplayKit</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    """.format(
        telegram_bundle_id = telegram_bundle_id,
    )
)

plist_fragment(
    name = "DisplayInfoPlist",
    extension = "plist",
    template =
    """
    <key>CFBundleIdentifier</key>
    <string>{telegram_bundle_id}.Display</string>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleName</key>
    <string>Display</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    """.format(
        telegram_bundle_id = telegram_bundle_id,
    )
)

genrule(
    name = "StripFramework",
    cmd_bash =
"""
    echo 'for f in $$1/*.framework; do binary_name=`echo $$(basename $$f) | sed -e "s/\\\\.framework//"`; strip -ST $$f/$$binary_name; done;' > $(location StripFramework.sh)
    echo '' >> $(location StripFramework.sh)
""",
    outs = [
        "StripFramework.sh",
    ],
    executable = True,
    visibility = [
        "//visibility:public",
    ]
)

genrule(
    name = "GenerateAddAlternateIcons",
    srcs = [
        "Telegram-iOS/AddAlternateIcons.sh",
    ],
    cmd_bash =
"""
    cat $(location Telegram-iOS/AddAlternateIcons.sh) >> $(location AddAlternateIcons.sh)
""",
    outs = [
        "AddAlternateIcons.sh",
    ],
    executable = True,
    visibility = [
        "//visibility:public",
    ]
)

sh_binary(
    name = "AddAlternateIcons",
    data = [
        "Telegram-iOS/AlternateIcons.plist",
        "Telegram-iOS/AlternateIcons-iPad.plist",
    ],
    srcs = [":GenerateAddAlternateIcons"],
)

plist_fragment(
    name = "TelegramUIInfoPlist",
    extension = "plist",
    template =
    """
    <key>CFBundleIdentifier</key>
    <string>{telegram_bundle_id}.TelegramUI</string>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleName</key>
    <string>TelegramUI</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    """.format(
        telegram_bundle_id = telegram_bundle_id,
    )
)

ios_framework(
    name = "TelegramUIFramework",
    bundle_id = "{telegram_bundle_id}.TelegramUI".format(
        telegram_bundle_id = telegram_bundle_id,
    ),
    families = [
        "iphone",
        "ipad",
    ],
    infoplists = [
        ":TelegramUIInfoPlist",
        ":BuildNumberInfoPlist",
        ":VersionInfoPlist",
        ":RequiredDeviceCapabilitiesPlist",
    ],
    frameworks = [
        ":MtProtoKitFramework",
        ":SwiftSignalKitFramework",
        ":PostboxFramework",
        ":TelegramCoreFramework",
    ],
    minimum_os_version = minimum_os_version,
    extension_safe = True,
    ipa_post_processor = strip_framework,
    deps = [
        "//submodules/TelegramUI:TelegramUI",
    ] + debug_deps,
)

plist_fragment(
    name = "ShareInfoPlist",
    extension = "plist",
    template = 
    """
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleIdentifier</key>
    <string>{telegram_bundle_id}.Share</string>
    <key>CFBundleName</key>
    <string>Nicegram</string>
    <key>CFBundlePackageType</key>
    <string>XPC!</string>
    <key>NSExtension</key>
    <dict>
        <key>NSExtensionAttributes</key>
        <dict>
            <key>IntentsSupported</key>
            <array>
                <string>INSendMessageIntent</string>
            </array>
            <key>NSExtensionActivationRule</key>
            <string>SUBQUERY (
    extensionItems,
    $extensionItem,
    SUBQUERY (
        $extensionItem.attachments,
        $attachment,
        ANY $attachment.registeredTypeIdentifiers UTI-CONFORMS-TO "public.file-url" ||
        ANY $attachment.registeredTypeIdentifiers UTI-CONFORMS-TO "public.movie" ||
        ANY $attachment.registeredTypeIdentifiers UTI-CONFORMS-TO "public.image" ||
        ANY $attachment.registeredTypeIdentifiers UTI-CONFORMS-TO "public.url" ||
        ANY $attachment.registeredTypeIdentifiers UTI-CONFORMS-TO "public.text" ||
        ANY $attachment.registeredTypeIdentifiers UTI-CONFORMS-TO "public.audio" ||
        ANY $attachment.registeredTypeIdentifiers UTI-CONFORMS-TO "public.data" ||
        ANY $attachment.registeredTypeIdentifiers UTI-CONFORMS-TO "public.vcard" ||
        ANY $attachment.registeredTypeIdentifiers UTI-CONFORMS-TO "com.apple.pkpass"
    ).@count == $extensionItem.attachments.@count
).@count &gt; 0</string>
        </dict>
        <key>NSExtensionPointIdentifier</key>
        <string>com.apple.share-services</string>
        <key>NSExtensionPrincipalClass</key>
        <string>ShareRootController</string>
    </dict>
    """.format(
        telegram_bundle_id = telegram_bundle_id,
    )
)

swift_library(
    name = "ShareExtensionLib",
    module_name = "ShareExtensionLib",
    srcs = glob([
        "Share/**/*.swift",
    ]),
    copts = [
        #"-warnings-as-errors",
    ],
    deps = [
        "//submodules/TelegramUI",
        "//submodules/TelegramUI/Components/ShareExtensionContext"
    ],
)

ios_extension(
    name = "ShareExtension",
    bundle_id = "{telegram_bundle_id}.Share".format(
        telegram_bundle_id = telegram_bundle_id,
    ),
    families = [
        "iphone",
        "ipad",
    ],
    infoplists = [
        ":ShareInfoPlist",
        ":VersionInfoPlist",
        ":RequiredDeviceCapabilitiesPlist",
        ":BuildNumberInfoPlist",
        ":AppNameInfoPlist",
    ],
    minimum_os_version = minimum_os_version,
    provisioning_profile = select({
        ":disableProvisioningProfilesSetting": None,
        "//conditions:default": "@build_configuration//provisioning:Share.mobileprovision",
    }),
    deps = [":ShareExtensionLib"],
    frameworks = [
        ":TelegramUIFramework"
    ],
)

plist_fragment(
    name = "NotificationContentInfoPlist",
    extension = "plist",
    template = 
    """
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleIdentifier</key>
    <string>{telegram_bundle_id}.NotificationContent</string>
    <key>CFBundleName</key>
    <string>Nicegram</string>
    <key>CFBundlePackageType</key>
    <string>XPC!</string>
    <key>NSExtension</key>
    <dict>
        <key>NSExtensionAttributes</key>
        <dict>
            <key>UNNotificationExtensionCategory</key>
            <array>
                <string>withReplyMedia</string>
                <string>withMuteMedia</string>
            </array>
            <key>UNNotificationExtensionInitialContentSizeRatio</key>
            <real>0.0001</real>
        </dict>
        <key>NSExtensionPointIdentifier</key>
        <string>com.apple.usernotifications.content-extension</string>
        <key>NSExtensionPrincipalClass</key>
        <string>NotificationViewController</string>
    </dict>
    """.format(
        telegram_bundle_id = telegram_bundle_id,
    )
)

objc_library(
    name = "NotificationContentExtensionLink",
    srcs = [
        "NotificationContent/main.m",
    ],
    sdk_frameworks = [
        "UserNotificationsUI",
    ],
)

swift_library(
    name = "NotificationContentExtensionLib",
    module_name = "NotificationContentExtensionLib",
    srcs = glob([
        "NotificationContent/**/*.swift",
    ]),
    copts = [
        #"-warnings-as-errors",
    ],
    deps = [
        "//submodules/TelegramUI:TelegramUI",
        ":NotificationContentExtensionLink",
    ],
)

'''genrule(
    name = "SetMinOsVersionNotificationContentExtension",
    cmd_bash =
"""
    name=NotificationContentExtension.appex
    cat $(location PatchMinOSVersion.source.sh) | sed -e "s/<<<MIN_OS_VERSION>>>/10\\.0/g" | sed -e "s/<<<NAME>>>/$$name/g" > $(location SetMinOsVersionNotificationContentExtension.sh)
""",
    srcs = [
        "PatchMinOSVersion.source.sh",
    ],
    outs = [
        "SetMinOsVersionNotificationContentExtension.sh",
    ],
    executable = True,
    visibility = [
        "//visibility:public",
    ]
)'''

ios_extension(
    name = "NotificationContentExtension",
    bundle_id = "{telegram_bundle_id}.NotificationContent".format(
        telegram_bundle_id = telegram_bundle_id,
    ),
    families = [
        "iphone",
        "ipad",
    ],
    infoplists = [
        ":NotificationContentInfoPlist",
        ":VersionInfoPlist",
        ":RequiredDeviceCapabilitiesPlist",
        ":BuildNumberInfoPlist",
        ":AppNameInfoPlist",
    ],
    minimum_os_version = minimum_os_version, # maintain the same minimum OS version across extensions
    #ipa_post_processor = ":SetMinOsVersionNotificationContentExtension",
    provisioning_profile = select({
        ":disableProvisioningProfilesSetting": None,
        "//conditions:default": "@build_configuration//provisioning:NotificationContent.mobileprovision",
    }),
    deps = [":NotificationContentExtensionLib"],
    frameworks = [
        ":TelegramUIFramework"
    ],
)

plist_fragment(
    name = "WidgetInfoPlist",
    extension = "plist",
    template = 
    """
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleIdentifier</key>
    <string>{telegram_bundle_id}.Widget</string>
    <key>CFBundleName</key>
    <string>Nicegram</string>
    <key>CFBundlePackageType</key>
    <string>XPC!</string>
    <key>NSExtension</key>
    <dict>
        <key>NSExtensionPointIdentifier</key>
        <string>com.apple.widgetkit-extension</string>
    </dict>
    <key>UIRequiredDeviceCapabilities</key>
    <array>
        <string>arm64</string>
    </array>
    """.format(
        telegram_bundle_id = telegram_bundle_id,
    )
)

filegroup(
    name = "WidgetAssets",
    srcs = glob(["WidgetKitWidget/WidgetImages.xcassets/**"]),
    visibility = ["//visibility:public"],
)

swift_library(
    name = "WidgetExtensionLib",
    module_name = "WidgetExtensionLib",
    srcs = glob([
        "WidgetKitWidget/**/*.swift",
    ]),
    copts = [
        #"-warnings-as-errors",
    ],
    data = [
        ":WidgetAssets",
    ],
    deps = [
        "//submodules/BuildConfig:BuildConfig",
        "//submodules/WidgetItems:WidgetItems_iOS14",
        "//submodules/WidgetItemsUtils:WidgetItemsUtils",
        "//submodules/AppLockState:AppLockState",
        "//submodules/SSignalKit/SwiftSignalKit:SwiftSignalKit",
        "//submodules/Postbox:Postbox",
        "//submodules/TelegramCore:TelegramCore",
        "//submodules/OpenSSLEncryptionProvider:OpenSSLEncryptionProvider",
        "//Telegram:GeneratedSources",
    ],
)

genrule(
    name = "SetMinOsVersionWidgetExtension",
    cmd_bash =
"""
    name=WidgetExtension.appex
    cat $(location PatchMinOSVersion.source.sh) | sed -e "s/<<<MIN_OS_VERSION>>>/14\\.0/g" | sed -e "s/<<<NAME>>>/$$name/g" > $(location SetMinOsVersionWidgetExtension.sh)
""",
    srcs = [
        "PatchMinOSVersion.source.sh",
    ],
    outs = [
        "SetMinOsVersionWidgetExtension.sh",
    ],
    executable = True,
    visibility = [
        "//visibility:public",
    ]
)

ios_extension(
    name = "WidgetExtension",
    bundle_id = "{telegram_bundle_id}.Widget".format(
        telegram_bundle_id = telegram_bundle_id,
    ),
    families = [
        "iphone",
        "ipad",
    ],
    infoplists = [
        ":WidgetInfoPlist",
        ":VersionInfoPlist",
        ":RequiredDeviceCapabilitiesPlist",
        ":BuildNumberInfoPlist",
        ":AppNameInfoPlist",
    ],
    minimum_os_version = minimum_os_version, # maintain the same minimum OS version across extensions
    ipa_post_processor = ":SetMinOsVersionWidgetExtension",
    #provides_main = True,
    provisioning_profile = select({
        ":disableProvisioningProfilesSetting": None,
        "//conditions:default": "@build_configuration//provisioning:Widget.mobileprovision",
    }),
    deps = [
        ":WidgetExtensionLib",
    ],
    frameworks = [
        ":SwiftSignalKitFramework",
        ":PostboxFramework",
        ":TelegramCoreFramework",
    ],
    visibility = [
        "//visibility:public",
    ]
)

plist_fragment(
    name = "IntentsInfoPlist",
    extension = "plist",
    template = 
    """
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleIdentifier</key>
    <string>{telegram_bundle_id}.SiriIntents</string>
    <key>CFBundleName</key>
    <string>Nicegram</string>
    <key>CFBundlePackageType</key>
    <string>XPC!</string>
    <key>NSExtension</key>
    <dict>
        <key>NSExtensionAttributes</key>
        <dict>
            <key>IntentsRestrictedWhileLocked</key>
            <array/>
            <key>IntentsRestrictedWhileProtectedDataUnavailable</key>
            <array/>
            <key>IntentsSupported</key>
            <array>
                <string>INSendMessageIntent</string>
                <string>INStartAudioCallIntent</string>
                <string>INSearchForMessagesIntent</string>
                <string>INSetMessageAttributeIntent</string>
                <string>INSearchCallHistoryIntent</string>
                <string>SelectFriendsIntent</string>
                <string>SelectAvatarFriendsIntent</string>
            </array>
        </dict>
        <key>NSExtensionPointIdentifier</key>
        <string>com.apple.intents-service</string>
        <key>NSExtensionPrincipalClass</key>
        <string>IntentHandler</string>
    </dict>
    """.format(
        telegram_bundle_id = telegram_bundle_id,
    )
)

swift_intent_library(
    name = "GeneratedSources",
    src = "SiriIntents/en.lproj/Intents.intentdefinition",
    module_name = "GeneratedSources",
    visibility = ["//visibility:public"],
)

filegroup(
    name = "IntentsAssets",
    srcs = glob(["SiriIntents/IntentsImages.xcassets/**"]),
    visibility = ["//visibility:public"],
)

swift_library(
    name = "IntentsExtensionLib",
    module_name = "IntentsExtensionLib",
    srcs = glob([
        "SiriIntents/**/*.swift",
    ]),
    copts = [
        #"-warnings-as-errors",
    ],
    data = glob([
        "SiriIntents/*.lproj/Intents.intentdefinition"
    ]) + [
        ":IntentsAssets"
    ],
    deps = [
        "//submodules/SSignalKit/SwiftSignalKit:SwiftSignalKit",
        "//submodules/Postbox:Postbox",
        "//submodules/TelegramApi:TelegramApi",
        "//submodules/TelegramCore:TelegramCore",
        "//submodules/BuildConfig:BuildConfig",
        "//submodules/OpenSSLEncryptionProvider:OpenSSLEncryptionProvider",
        "//submodules/AppLockState:AppLockState",
        "//Telegram:GeneratedSources",
        "//submodules/WidgetItems:WidgetItems",
    ],
)

'''genrule(
    name = "SetMinOsVersionIntentsExtension",
    cmd_bash =
"""
    name=IntentsExtension.appex
    cat $(location PatchMinOSVersion.source.sh) | sed -e "s/<<<MIN_OS_VERSION>>>/10\\.0/g" | sed -e "s/<<<NAME>>>/$$name/g" > $(location SetMinOsVersionIntentsExtension.sh)
""",
    srcs = [
        "PatchMinOSVersion.source.sh",
    ],
    outs = [
        "SetMinOsVersionIntentsExtension.sh",
    ],
    executable = True,
    visibility = [
        "//visibility:public",
    ]
)'''

ios_extension(
    name = "IntentsExtension",
    bundle_id = "{telegram_bundle_id}.SiriIntents".format(
        telegram_bundle_id = telegram_bundle_id,
    ),
    families = [
        "iphone",
        "ipad",
    ],
    infoplists = [
        ":IntentsInfoPlist",
        ":VersionInfoPlist",
        ":RequiredDeviceCapabilitiesPlist",
        ":BuildNumberInfoPlist",
        ":AppNameInfoPlist",
    ],
    minimum_os_version = minimum_os_version, # maintain the same minimum OS version across extensions
    #ipa_post_processor = ":SetMinOsVersionIntentsExtension",
    provisioning_profile = select({
        ":disableProvisioningProfilesSetting": None,
        "//conditions:default": "@build_configuration//provisioning:Intents.mobileprovision",
    }),
    deps = [":IntentsExtensionLib"],
    frameworks = [
        ":SwiftSignalKitFramework",
        ":PostboxFramework",
        ":TelegramCoreFramework",
    ],
)

plist_fragment(
    name = "BroadcastUploadInfoPlist",
    extension = "plist",
    template = 
    """
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleIdentifier</key>
    <string>{telegram_bundle_id}.BroadcastUpload</string>
    <key>CFBundleName</key>
    <string>Telegram</string>
    <key>CFBundlePackageType</key>
    <string>XPC!</string>
    <key>NSExtension</key>
    <dict>
        <key>NSExtensionPointIdentifier</key>
        <string>com.apple.broadcast-services-upload</string>
        <key>NSExtensionPrincipalClass</key>
        <string>BroadcastUploadSampleHandler</string>
        <key>RPBroadcastProcessMode</key>
        <string>RPBroadcastProcessModeSampleBuffer</string>
    </dict>
    """.format(
        telegram_bundle_id = telegram_bundle_id,
    )
)

swift_library(
    name = "BroadcastUploadExtensionLib",
    module_name = "BroadcastUploadExtensionLib",
    srcs = glob([
        "BroadcastUpload/**/*.swift",
    ]),
    copts = [
        #"-warnings-as-errors",
    ],
    deps = [
        "//submodules/TelegramUI:TelegramUI",
        "//submodules/TelegramVoip:TelegramVoip",
        "//submodules/SSignalKit/SwiftSignalKit:SwiftSignalKit",
        "//submodules/BuildConfig:BuildConfig",
        "//submodules/WidgetItems:WidgetItems",
        "//submodules/BroadcastUploadHelpers:BroadcastUploadHelpers",
    ],
)

'''genrule(
    name = "SetMinOsVersionBroadcastUploadExtension",
    cmd_bash =
"""
    name=BroadcastUploadExtension.appex
    cat $(location PatchMinOSVersion.source.sh) | sed -e "s/<<<MIN_OS_VERSION>>>/11\\.0/g" | sed -e "s/<<<NAME>>>/$$name/g" > $(location SetMinOsVersionBroadcastUploadExtension.sh)
""",
    srcs = [
        "PatchMinOSVersion.source.sh",
    ],
    outs = [
        "SetMinOsVersionBroadcastUploadExtension.sh",
    ],
    executable = True,
    visibility = [
        "//visibility:public",
    ]
)'''

ios_extension(
    name = "BroadcastUploadExtension",
    bundle_id = "{telegram_bundle_id}.BroadcastUpload".format(
        telegram_bundle_id = telegram_bundle_id,
    ),
    families = [
        "iphone",
        "ipad",
    ],
    infoplists = [
        ":BroadcastUploadInfoPlist",
        ":VersionInfoPlist",
        ":RequiredDeviceCapabilitiesPlist",
        ":BuildNumberInfoPlist",
        ":AppNameInfoPlist",
    ],
    minimum_os_version = minimum_os_version, # maintain the same minimum OS version across extensions
    #ipa_post_processor = ":SetMinOsVersionBroadcastUploadExtension",
    provisioning_profile = select({
        ":disableProvisioningProfilesSetting": None,
        "//conditions:default": "@build_configuration//provisioning:BroadcastUpload.mobileprovision",
    }),
    deps = [":BroadcastUploadExtensionLib"],
    frameworks = [
        ":TelegramUIFramework",
        ":SwiftSignalKitFramework",
    ],
)

plist_fragment(
    name = "NotificationServiceInfoPlist",
    extension = "plist",
    template = 
    """
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleIdentifier</key>
    <string>{telegram_bundle_id}.NotificationService</string>
    <key>CFBundleName</key>
    <string>Nicegram</string>
    <key>CFBundlePackageType</key>
    <string>XPC!</string>
    <key>NSExtension</key>
    <dict>
        <key>NSExtensionPointIdentifier</key>
        <string>com.apple.usernotifications.service</string>
        <key>NSExtensionPrincipalClass</key>
        <string>NotificationService</string>
        <key>NSExtensionAttributes</key>
        <dict>
            <key>IntentsSupported</key>
            <array>
                <string>INSendMessageIntent</string>
            </array>
        </dict>
    </dict>
    """.format(
        telegram_bundle_id = telegram_bundle_id
    )
)

ios_extension(
    name = "NotificationServiceExtension" + notificationServiceExtensionVersion,
    bundle_id = "{telegram_bundle_id}.NotificationService".format(
        telegram_bundle_id = telegram_bundle_id,
    ),
    families = [
        "iphone",
        "ipad",
    ],
    infoplists = [
        ":NotificationServiceInfoPlist",
        ":VersionInfoPlist",
        ":RequiredDeviceCapabilitiesPlist",
        ":BuildNumberInfoPlist",
        ":AppNameInfoPlist",
    ],
    minimum_os_version = minimum_os_version, # maintain the same minimum OS version across extensions
    provisioning_profile = select({
        ":disableProvisioningProfilesSetting": None,
        "//conditions:default": "@build_configuration//provisioning:NotificationService.mobileprovision",
    }),
    deps = ["//Telegram/NotificationService:NotificationServiceExtensionLib"],
    frameworks = [
        ":MtProtoKitFramework",
        ":SwiftSignalKitFramework",
        ":PostboxFramework",
        ":TelegramCoreFramework",
        ":TelegramUIFramework",
    ],
)

# Nicegram
nicegram_queries_schemes = """
<string>appesim</string>
<string>com.sticker.studio</string>
<string>inlab</string>
<string>plnt</string>
"""

# Nicegram
nicegram_skad_network_items = """
<key>SKAdNetworkItems</key>
<array>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>ecpz2srf59.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>7ug5zh24hu.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>9t245vhmpl.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>prcb7njmu6.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>5lm9lj6jb7.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>578prtvx9j.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>22mmun2rn5.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>uw77j35x4d.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>c6k4g5qg8m.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>hs6bdukanm.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>yclnxrl5pm.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>3sh42y64q3.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>cj5566h2ga.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>klf5c3l5u5.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>8s468mfl3y.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>2u9pt9hc89.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>7rz58n8ntl.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>ppxm28t8ap.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>5tjdwbrq8w.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>238da6jt44.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>24t9a8vw3c.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>252b5q8x7y.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>3qy4746246.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>3rd42ekr43.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>424m5254lk.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>4468km3ulz.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>44jx6755aq.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>44n7hlldy6.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>488r3q3dtq.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>4fzdc2evr5.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>4pfyvq9l8r.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>523jb4fst2.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>52fl2v3hgk.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>5a6flpkh64.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>5l3tpt7t6e.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>737z793b9f.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>97r2b46745.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>9rd848q2bz.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>9yg77x724h.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>av6w8kgt66.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>cg4yq2srnc.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>cstr6suwn9.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>dzg6xy7pwj.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>ejvt5qm6ak.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>f73kdq92p3.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>g28c52eehv.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>ggvn48r87g.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>glqzh8vgby.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>gvmwg8q7h5.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>hdw39hrw9y.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>kbd757ywx3.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>lr83yxwka7.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>m8dbw4sv7c.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>mlmmfzh3r3.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>mls7yz5dvl.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>mtkv5xtk9e.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>n66cz3y3bx.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>n9x2a789qt.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>nzq8sh4pbs.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>p78axxw29g.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>pu4na253f3.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>s39g8k73mm.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>t38b2kh725.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>tl55sbb4fm.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>u679fj5vs4.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>v72qych5uu.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>v79kvwwj4g.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>w9q455wk68.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>wg4vff78zm.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>wzmmz9fp6w.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>xy9t38ct57.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>y45688jllp.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>ydx93a7ass.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>yrqqpx2mcb.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>z4gj7hsk7h.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>zmvfpc5aq8.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>k674qkevps.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>2fnua5tdw4.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>9nlqeag3gk.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>n6fk4nfna4.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>e5fvkxwrpn.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>kbmxgpxpgc.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>294l99pt4k.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>r45fhb6rf7.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>pwa73g5rt2.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>3qcr597p9d.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>x44k69ngh6.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>a2p9lx4jpn.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>zq492l623r.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>c3frkrj4fj.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>6g9af3uyq4.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>74b6s63p6l.skadnetwork</string>
  </dict>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>32z4fx6l9h.skadnetwork</string>
  </dict>
</array>
"""

plist_fragment(
    name = "TelegramInfoPlist",
    extension = "plist",
    template = 
    """
    {nicegram_skad_network_items}
    <key>BGTaskSchedulerPermittedIdentifiers</key>
    <array>
        <string>{telegram_bundle_id}.refresh</string>
        <string>{telegram_bundle_id}.cleanup</string>
    </array>
    <key>CFBundleAllowMixedLocalizations</key>
    <true/>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleDisplayName</key>
    <string>Nicegram</string>
    <key>CFBundleIdentifier</key>
    <string>{telegram_bundle_id}</string>
    <key>CFBundleName</key>
    <string>Nicegram</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>ITSAppUsesNonExemptEncryption</key>
    <false/>
    <key>LSApplicationQueriesSchemes</key>
    <array>
        {nicegram_queries_schemes}
        <string>instagram</string>
        <string>comgooglemaps-x-callback</string>
        <string>foursquare</string>
        <string>here-location</string>
        <string>yandexmaps</string>
        <string>yandexnavi</string>
        <string>comgooglemaps</string>
        <string>youtube</string>
        <string>twitter</string>
        <string>vk</string>
        <string>waze</string>
        <string>googlechrome</string>
        <string>firefox</string>
        <string>touch-http</string>
        <string>yandexbrowser-open-url</string>
        <string>vimeo</string>
        <string>vine</string>
        <string>coub</string>
        <string>uber</string>
        <string>citymapper</string>
        <string>lyft</string>
        <string>opera-http</string>
        <string>firefox-focus</string>
        <string>ddgQuickLink</string>
        <string>moovit</string>
        <string>alook</string>
        <string>dgis</string>
        <string>microsoft-edge-http</string>
        <string>brave</string>
        <string>onionhttp</string>
        <string>ucbrowser</string>
        <string>dolphin</string>
        <string>instagram-stories</string>
        <string>yangomaps</string>
    </array>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <true/>
    </dict>
    <key>NSCameraUsageDescription</key>
    <string>We need this so that you can take and share photos and videos.</string>
    <key>NSContactsUsageDescription</key>
    <string>Nicegram stores your contacts heavily encrypted in the cloud to let you connect with your friends across all your devices.</string>
    <key>NSFaceIDUsageDescription</key>
    <string>You can use Face ID to unlock the app.</string>
    <key>NSLocationAlwaysUsageDescription</key>
    <string>When you send your location to your friends, Nicegram needs access to show them a map. You also need this to send locations from an Apple Watch.</string>
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>When you send your location to your friends, Nicegram needs access to show them a map.</string>
    <key>NSMicrophoneUsageDescription</key>
    <string>We need this so that you can record and share voice messages and videos with sound.</string>
    <key>NSMotionUsageDescription</key>
    <string>When you send your location to your friends, Nicegram needs access to show them a map.</string>
    <key>NSPhotoLibraryAddUsageDescription</key>
    <string>We use access to your photo library so you can attach and send photos and videos from your device in chats.</string>
    <key>NSPhotoLibraryUsageDescription</key>
    <string>We use access to your photo library so you can attach and send photos and videos from your device in chats.</string>
    <key>NSSiriUsageDescription</key>
    <string>You can use Siri to send messages.</string>
    <key>NSSpeechRecognitionUsageDescription</key>
    <string>We need this to transcribe audio messages on your request.</string>
    <key>NSUserActivityTypes</key>
    <array>
        <string>INSendMessageIntent</string>
        <string>RemindAboutChatIntent</string>
    </array>
    <key>UIAppFonts</key>
    <array>
        <string>SFCompactRounded-Semibold.otf</string>
        <string>AremacFS-Regular.otf</string>
        <string>AremacFS-Semibold.otf</string>
    </array>
    <key>UIBackgroundModes</key>
    <array>
        <string>audio</string>
        <string>fetch</string>
        <string>location</string>
        <string>remote-notification</string>
        <string>voip</string>
        <string>processing</string>
    </array>
    <key>UIDeviceFamily</key>
    <array>
        <integer>1</integer>
        <integer>2</integer>
    </array>
    <key>UIFileSharingEnabled</key>
    <false/>
    <key>UILaunchStoryboardName</key>
    <string>LaunchScreen</string>
    <key>UIRequiresPersistentWiFi</key>
    <true/>
    <key>UIStatusBarStyle</key>
    <string>UIStatusBarStyleDefault</string>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    <key>UISupportedInterfaceOrientations~ipad</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationPortraitUpsideDown</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    <key>UIViewControllerBasedStatusBarAppearance</key>
    <true/>
    <key>UIViewEdgeAntialiasing</key>
    <false/>
    <key>UIViewGroupOpacity</key>
    <false/>
    <key>UTImportedTypeDeclarations</key>
    <array>
        <dict>
            <key>UTTypeConformsTo</key>
            <array>
                <string>public.data</string>
            </array>
            <key>UTTypeDescription</key>
            <string>Telegram iOS Color Theme File</string>
            <key>UTTypeIconFiles</key>
            <array>
                <string>BlueIcon@3x.png</string>
            </array>
            <key>UTTypeIdentifier</key>
            <string>org.telegram.Telegram-iOS.theme</string>
            <key>UTTypeTagSpecification</key>
            <dict>
                <key>public.filename-extension</key>
                <array>
                    <string>tgios-theme</string>
                </array>
            </dict>
        </dict>
    </array>
    <key>CADisableMinimumFrameDurationOnPhone</key>
    <true/>
    <key>UIApplicationSupportsIndirectInputEvents</key>
    <true/>
    <key>GOOGLE_ANALYTICS_DEFAULT_ALLOW_ANALYTICS_STORAGE</key>
    <true/>
    <key>GOOGLE_ANALYTICS_DEFAULT_ALLOW_AD_STORAGE</key>
    <true/>
    <key>GOOGLE_ANALYTICS_DEFAULT_ALLOW_AD_USER_DATA</key>
    <true/>
    <key>GOOGLE_ANALYTICS_DEFAULT_ALLOW_AD_PERSONALIZATION_SIGNALS</key>
    <true/>
    <key>NSUbiquitousContainers</key>
    <dict>
        <key>iCloud.{telegram_bundle_id}</key>
        <dict>
            <key>NSUbiquitousContainerName</key>
            <string>Nicegram</string>
            <key>NSUbiquitousContainerSupportedFolderLevels</key>
            <string>ANY</string>
        </dict>
    </dict>
    """.format(
        nicegram_queries_schemes = nicegram_queries_schemes,
        nicegram_skad_network_items = nicegram_skad_network_items,
        telegram_bundle_id = telegram_bundle_id,
    )
)

local_provisioning_profile(
    name = "Telegram_local_profile",
    profile_name = "iOS Team Provisioning Profile: {}".format(telegram_bundle_id),
    team_id = telegram_team_id,
)

xcode_provisioning_profile(
   name = "Telegram_xcode_profile",
   managed_by_xcode = True,
   provisioning_profile = ":Telegram_local_profile",
)

ios_application(
    name = "Telegram",
    bundle_id = "{telegram_bundle_id}".format(
        telegram_bundle_id = telegram_bundle_id,
    ),
    families = ["iphone", "ipad"],
    minimum_os_version = minimum_os_version,
    provisioning_profile = select({
        ":disableProvisioningProfilesSetting": None,
        "//conditions:default": ":Telegram_xcode_profile" if telegram_use_xcode_managed_codesigning else "@build_configuration//provisioning:Telegram.mobileprovision",
    }),
    entitlements = ":TelegramEntitlements.entitlements",
    infoplists = [
        ":TelegramInfoPlist",
        ":BuildNumberInfoPlist",
        ":VersionInfoPlist",
        ":RequiredDeviceCapabilitiesPlist",
        ":UrlTypesInfoPlist",
    ],
    alternate_icons = [
        ":{}".format(name) for name in alternate_icon_folders
    ],
    resources = [
        ":LaunchScreen",
        ":DefaultAppIcon",
    ],
    frameworks = [
        ":MtProtoKitFramework",
        ":SwiftSignalKitFramework",
        ":PostboxFramework",
        ":TelegramCoreFramework",
        ":TelegramUIFramework",
    ],
    settings_bundle = "//Nicegram/NGSettingsBundle:NGSettingsBundle",
    strings = [
        ":AppStringResources",
    ],
    extensions = select({
        ":disableExtensionsSetting": [],
        "//conditions:default": [
            ":ShareExtension",
            ":NotificationContentExtension",
            ":NotificationServiceExtension" + notificationServiceExtensionVersion,
            ":IntentsExtension",
            ":WidgetExtension",
            ":BroadcastUploadExtension",
        ],
    }),
    deps = [
        ":Main",
        ":Lib",
    ],
    visibility = ["//visibility:public"],
)

xcodeproj(
    name = "Telegram_xcodeproj",
    bazel_path = telegram_bazel_path,
    project_name = "Telegram",
    tags = ["manual"],
    top_level_targets = top_level_targets(
        labels = [
            ":Telegram",
        ],
        target_environments = ["device", "simulator"],
    ),
    xcode_configurations = {
        "Debug": {
            "//command_line_option:compilation_mode": "dbg",
        },
        "Release": {
            "//command_line_option:compilation_mode": "opt",
        },
    },
    default_xcode_configuration = "Debug"
)

# Temporary targets used to simplify build tests

ios_application(
    name = "spm_build_app",
    bundle_id = "{telegram_bundle_id}".format(
        telegram_bundle_id = telegram_bundle_id,
    ),
    families = ["iphone", "ipad"],
    minimum_os_version = minimum_os_version,
    provisioning_profile = select({
        ":disableProvisioningProfilesSetting": None,
        "//conditions:default": "@build_configuration//provisioning:Telegram.mobileprovision",
    }),
    entitlements = ":TelegramEntitlements.entitlements",
    infoplists = [
        ":TelegramInfoPlist",
        ":BuildNumberInfoPlist",
        ":VersionInfoPlist",
        ":RequiredDeviceCapabilitiesPlist",
        ":UrlTypesInfoPlist",
    ],
    deps = [
        #"//submodules/Display",
        #"//submodules/TelegramCore",
        #"//submodules/FFMpegBinding",
        #"//third-party/webrtc",
        #"//third-party/webrtc:webrtc_objc",
        #"//submodules/AsyncDisplayKit",
        #"//submodules/ObjCRuntimeUtils",
        #"//submodules/OpusBinding",
        #"//third-party/boringssl:ssl",
        #"//third-party/boringssl:crypto",
        #"//submodules/TelegramVoip",
        #"//third-party/recaptcha:RecaptchaEnterprise",
        "//submodules/TelegramUI",
    ],
)

generate_spm(
    name = "spm_build_root",
    deps = [
        ":spm_build_app",
    ]
)

ios_application(
    name = "webrtc_build_test",
    bundle_id = "{telegram_bundle_id}".format(
        telegram_bundle_id = telegram_bundle_id,
    ),
    families = ["iphone", "ipad"],
    minimum_os_version = minimum_os_version,
    provisioning_profile = select({
        ":disableProvisioningProfilesSetting": None,
        "//conditions:default": "@build_configuration//provisioning:Telegram.mobileprovision",
    }),
    entitlements = ":TelegramEntitlements.entitlements",
    infoplists = [
        ":TelegramInfoPlist",
        ":BuildNumberInfoPlist",
        ":VersionInfoPlist",
        ":RequiredDeviceCapabilitiesPlist",
        ":UrlTypesInfoPlist",
    ],
    deps = [
        "//third-party/webrtc",
        "//third-party/webrtc:webrtc_objc",
    ],
)

ios_application(
    name = "libvpx_build_test",
    bundle_id = "{telegram_bundle_id}".format(
        telegram_bundle_id = telegram_bundle_id,
    ),
    families = ["iphone", "ipad"],
    minimum_os_version = minimum_os_version,
    provisioning_profile = select({
        ":disableProvisioningProfilesSetting": None,
        "//conditions:default": "@build_configuration//provisioning:Telegram.mobileprovision",
    }),
    entitlements = ":TelegramEntitlements.entitlements",
    infoplists = [
        ":TelegramInfoPlist",
        ":BuildNumberInfoPlist",
        ":VersionInfoPlist",
        ":RequiredDeviceCapabilitiesPlist",
        ":UrlTypesInfoPlist",
    ],
    deps = [
        "//third-party/libvpx:vpx",
    ],
)
