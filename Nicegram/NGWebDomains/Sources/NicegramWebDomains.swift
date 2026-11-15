import Foundation

public enum NicegramWebDomains {}

public extension NicegramWebDomains {
    /// Every Nicegram web domain the app claims, `primary` included; the Business hosts are `businessPrimary` and `businessUniversalLink`.
    static var all: [String] { nicegramAllDomains }

    /// The Nicegram Business dashboard and its API: not claimed.
    static var businessPrimary: String { nicegramBusinessPrimaryDomain }

    /// The Nicegram Business universal-link host: claimed, but never one of `all`.
    static var businessUniversalLink: String { nicegramBusinessUniversalLinkDomain }

    /// The one domain the app links to.
    static var primary: String { nicegramPrimaryDomain }

    static func contains(_ host: String?) -> Bool {
        guard let host else { return false }
        return all.contains(host.lowercased())
    }
}
