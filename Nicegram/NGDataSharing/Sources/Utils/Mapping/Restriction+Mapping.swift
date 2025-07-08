import FeatDataSharing
import TelegramCore

//  MARK: - Local

extension [Restriction] {
    init(_ info: PeerAccessRestrictionInfo?) {
        self = (info?.rules ?? []).map { reason in
            return .init(
                platform: reason.platform,
                reason: reason.reason,
                text: reason.text
            )
        }
    }
}
