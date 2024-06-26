load("@rules_swift_package_manager//swiftpkg:defs.bzl", "swift_package")

def swift_dependencies():
    # version: 0.6.7
    swift_package(
        name = "swiftpkg_anycodable",
        commit = "862808b2070cd908cb04f9aafe7de83d35f81b05",
        dependencies_index = "@//:swift_deps_index.json",
        remote = "https://github.com/Flight-School/AnyCodable",
    )

    # version: 1.0.2
    swift_package(
        name = "swiftpkg_bigdecimal",
        commit = "04d17040e4615fbfda3a882b9881f6841f4bf557",
        dependencies_index = "@//:swift_deps_index.json",
        remote = "https://github.com/Zollerboy1/BigDecimal.git",
    )

    # version: 5.3.0
    swift_package(
        name = "swiftpkg_bigint",
        commit = "0ed110f7555c34ff468e72e1686e59721f2b0da6",
        dependencies_index = "@//:swift_deps_index.json",
        remote = "https://github.com/attaswift/BigInt",
    )

    # branch: release/1.0.0
    swift_package(
        name = "swiftpkg_core_swift",
        commit = "20b7275f60ad80634f056905d7f18292294cd510",
        dependencies_index = "@//:swift_deps_index.json",
        remote = "https://github.com/denis15yo/core-swift.git",
    )

    # version: 1.8.2
    swift_package(
        name = "swiftpkg_cryptoswift",
        commit = "c9c3df6ab812de32bae61fc0cd1bf6d45170ebf0",
        dependencies_index = "@//:swift_deps_index.json",
        remote = "https://github.com/krzyzanowskim/CryptoSwift.git",
    )

    # version: 0.1.2
    swift_package(
        name = "swiftpkg_curvelib.swift",
        commit = "7dad3bf1793de263f83406c08c18c9316abf082f",
        dependencies_index = "@//:swift_deps_index.json",
        remote = "https://github.com/tkey/curvelib.swift",
    )

    # version: 2.1.3
    swift_package(
        name = "swiftpkg_factory",
        commit = "587995f7d5cc667951d635fbf6b4252324ba0439",
        dependencies_index = "@//:swift_deps_index.json",
        remote = "https://github.com/hmlongco/Factory.git",
    )

    # version: 5.2.0
    swift_package(
        name = "swiftpkg_fetch_node_details_swift",
        commit = "bf2f0759da5c5c80765773b08c2756045edf608f",
        dependencies_index = "@//:swift_deps_index.json",
        remote = "https://github.com/torusresearch/fetch-node-details-swift.git",
    )

    # version: 2.6.1
    swift_package(
        name = "swiftpkg_floatingpanel",
        commit = "22d46c526084724a718b8c39ab77f12452712cc7",
        dependencies_index = "@//:swift_deps_index.json",
        remote = "https://github.com/scenee/FloatingPanel",
    )

    # branch: master
    swift_package(
        name = "swiftpkg_grdb.swift",
        commit = "afc958017ee4feefd3c61c8e2cddf81d079d2e39",
        dependencies_index = "@//:swift_deps_index.json",
        remote = "https://github.com/denis15yo/GRDB.swift.git",
    )

    # version: 20.0.0
    swift_package(
        name = "swiftpkg_keychain_swift",
        commit = "d108a1fa6189e661f91560548ef48651ed8d93b9",
        dependencies_index = "@//:swift_deps_index.json",
        remote = "https://github.com/evgenyneu/keychain-swift.git",
    )

    # version: 1.2.0
    swift_package(
        name = "swiftpkg_lnextensionexecutor",
        commit = "16b741f659e344f4569c9f9d32ef2298ef0233ff",
        dependencies_index = "@//:swift_deps_index.json",
        remote = "https://github.com/LeoNatan/LNExtensionExecutor",
    )

    # branch: main
    swift_package(
        name = "swiftpkg_navigation_stack_backport",
        commit = "66716ce9c31198931c2275a0b69de2fdaa687e74",
        dependencies_index = "@//:swift_deps_index.json",
        remote = "https://github.com/denis15yo/navigation-stack-backport.git",
    )

    # branch: develop
    swift_package(
        name = "swiftpkg_nicegram_assistant_ios",
        commit = "0985fd5dfae1676121c54c31fe2817059d5bf784",
        dependencies_index = "@//:swift_deps_index.json",
        remote = "git@bitbucket.org:mobyrix/nicegram-assistant-ios.git",
    )

    # branch: develop
    swift_package(
        name = "swiftpkg_nicegram_wallet_ios",
        commit = "241a210ee1b5cb9cb95d9245a4ed384973ee2ef2",
        dependencies_index = "@//:swift_deps_index.json",
        remote = "git@bitbucket.org:mobyrix/nicegram-wallet-ios.git",
    )

    # version: 14.3.1
    swift_package(
        name = "swiftpkg_qrcode",
        commit = "263f280d2c8144adfb0b6676109846cfc8dd552b",
        dependencies_index = "@//:swift_deps_index.json",
        remote = "https://github.com/WalletConnect/QRCode",
    )

    # version: 7.3.2
    swift_package(
        name = "swiftpkg_r.swift",
        commit = "4a0f8c97f1baa27d165dc801982c55bbf51126e5",
        dependencies_index = "@//:swift_deps_index.json",
        remote = "https://github.com/denis15yo/R.swift.git",
    )

    # version: 5.15.5
    swift_package(
        name = "swiftpkg_sdwebimage",
        commit = "b8523c1642f3c142b06dd98443ea7c48343a4dfd",
        dependencies_index = "@//:swift_deps_index.json",
        remote = "https://github.com/SDWebImage/SDWebImage.git",
    )

    # version: 3.1.1
    swift_package(
        name = "swiftpkg_session_manager_swift",
        commit = "c89d9205a1ce38cd6c6374b906a9039d9cc03f05",
        dependencies_index = "@//:swift_deps_index.json",
        remote = "https://github.com/Web3Auth/session-manager-swift.git",
    )

    # version: 4.0.0
    swift_package(
        name = "swiftpkg_single_factor_auth_swift",
        commit = "8baa2b8cf55b0a38cb98c412bea1c6597adb78ba",
        dependencies_index = "@//:swift_deps_index.json",
        remote = "https://github.com/Web3Auth/single-factor-auth-swift.git",
    )

    # version: 5.6.0
    swift_package(
        name = "swiftpkg_snapkit",
        commit = "2842e6e84e82eb9a8dac0100ca90d9444b0307f4",
        dependencies_index = "@//:swift_deps_index.json",
        remote = "https://github.com/SnapKit/SnapKit.git",
    )

    # version: 4.0.8
    swift_package(
        name = "swiftpkg_starscream",
        commit = "c6bfd1af48efcc9a9ad203665db12375ba6b145a",
        dependencies_index = "@//:swift_deps_index.json",
        remote = "https://github.com/daltoniam/Starscream.git",
    )

    # version: 0.4.3
    swift_package(
        name = "swiftpkg_subscriptionanalytics_ios",
        commit = "53bfc6c6f26322ec647b87c338a071714ac69420",
        dependencies_index = "@//:swift_deps_index.json",
        remote = "git@bitbucket.org:mobyrix/subscriptionanalytics-ios.git",
    )

    # version: 1.2.3
    swift_package(
        name = "swiftpkg_swift_argument_parser",
        commit = "0fbc8848e389af3bb55c182bc19ca9d5dc2f255b",
        dependencies_index = "@//:swift_deps_index.json",
        remote = "https://github.com/apple/swift-argument-parser",
    )

    # version: 1.1.0
    swift_package(
        name = "swiftpkg_swift_collections",
        commit = "ee97538f5b81ae89698fd95938896dec5217b148",
        dependencies_index = "@//:swift_deps_index.json",
        remote = "https://github.com/apple/swift-collections",
    )

    # version: 1.0.3
    swift_package(
        name = "swiftpkg_swift_http_types",
        commit = "1ddbea1ee34354a6a2532c60f98501c35ae8edfa",
        dependencies_index = "@//:swift_deps_index.json",
        remote = "https://github.com/apple/swift-http-types",
    )

    # version: 1.0.2
    swift_package(
        name = "swiftpkg_swift_numerics",
        commit = "0a5bc04095a675662cf24757cc0640aa2204253b",
        dependencies_index = "@//:swift_deps_index.json",
        remote = "https://github.com/apple/swift-numerics.git",
    )

    # version: 1.4.0
    swift_package(
        name = "swiftpkg_swift_openapi_runtime",
        commit = "a51b3bd6f2151e9a6f792ca6937a7242c4758768",
        dependencies_index = "@//:swift_deps_index.json",
        remote = "https://github.com/apple/swift-openapi-runtime",
    )

    # version: 1.0.1
    swift_package(
        name = "swiftpkg_swift_openapi_urlsession",
        commit = "9229842c63e9fc3bbd32c661d8274b4d9d8715f1",
        dependencies_index = "@//:swift_deps_index.json",
        remote = "https://github.com/apple/swift-openapi-urlsession.git",
    )

    # version: 1.0.3
    swift_package(
        name = "swiftpkg_swift_qrcode_generator",
        commit = "5ca09b6a2ad190f94aa3d6ddef45b187f8c0343b",
        dependencies_index = "@//:swift_deps_index.json",
        remote = "https://github.com/dagronf/swift-qrcode-generator",
    )

    # version: 1.1.6
    swift_package(
        name = "swiftpkg_swiftimagereadwrite",
        commit = "5596407d1cf61b953b8e658fa8636a471df3c509",
        dependencies_index = "@//:swift_deps_index.json",
        remote = "https://github.com/dagronf/SwiftImageReadWrite",
    )

    # version: 0.16.4
    swift_package(
        name = "swiftpkg_swiftystorekit",
        commit = "9ce911639680113dac9b554d6243e406a9758ebe",
        dependencies_index = "@//:swift_deps_index.json",
        remote = "https://github.com/bizz84/SwiftyStoreKit.git",
    )

    # version: 0.2.1
    swift_package(
        name = "swiftpkg_tkey_ios",
        commit = "c107450f0675351a9a1eaaefe60bcfa285ff1f9e",
        dependencies_index = "@//:swift_deps_index.json",
        remote = "https://github.com/tkey/tkey-ios.git",
    )

    # version: 0.1.5
    swift_package(
        name = "swiftpkg_ton_api_swift",
        commit = "1988939fe0ce6db6bc587cfe7c9d15dc3bca1d69",
        dependencies_index = "@//:swift_deps_index.json",
        remote = "https://github.com/tonkeeper/ton-api-swift",
    )

    # branch: main
    swift_package(
        name = "swiftpkg_ton_swift",
        commit = "e4c3def222afc125f7ee83c1569004e31f0cd05c",
        dependencies_index = "@//:swift_deps_index.json",
        remote = "https://github.com/denis15yo/ton-swift.git",
    )

    # version: 8.0.1
    swift_package(
        name = "swiftpkg_torus_utils_swift",
        commit = "4c17ef5166c162455d0a37115c033eeff8cb282d",
        dependencies_index = "@//:swift_deps_index.json",
        remote = "https://github.com/torusresearch/torus-utils-swift.git",
    )

    # version: 1.1.0
    swift_package(
        name = "swiftpkg_tweetnacl_swiftwrap",
        commit = "f8fd111642bf2336b11ef9ea828510693106e954",
        dependencies_index = "@//:swift_deps_index.json",
        remote = "https://github.com/bitmark-inc/tweetnacl-swiftwrap",
    )

    # version: 4.0.36
    swift_package(
        name = "swiftpkg_wallet_core",
        commit = "94116a24445c2052edbc7203baf68296c68ce8f4",
        dependencies_index = "@//:swift_deps_index.json",
        remote = "https://github.com/trustwallet/wallet-core.git",
    )

    # branch: develop
    swift_package(
        name = "swiftpkg_walletconnectswiftv2",
        commit = "1eacd732e321c9511859d7e73303d61d82af4d46",
        dependencies_index = "@//:swift_deps_index.json",
        remote = "https://github.com/denis15yo/WalletConnectSwiftV2.git",
    )

    # version: 2.9.0
    swift_package(
        name = "swiftpkg_xcodeedit",
        commit = "b6b67389a0f1a6fdd9c6457a8ab5b02eaab13c5c",
        dependencies_index = "@//:swift_deps_index.json",
        remote = "https://github.com/tomlokhorst/XcodeEdit",
    )
