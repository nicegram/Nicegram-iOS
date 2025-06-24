import FeatDataSharing
import NGCore
import TelegramApi
import TelegramCore

//  MARK: - Local

extension InviteLink {
    init?(_ invite: ExportedInvitation) {
        switch invite {
        case let .link(link, _, isPermanent, requestApproval, isRevoked, adminId, date, _, _, _, _, _, _):
            self.init(
                adminId: adminId.id._internalGetInt64Value(),
                date: date,
                isPermanent: isPermanent,
                isRevoked: isRevoked,
                link: link,
                requestApproval: requestApproval
            )
        case .publicJoinRequest:
            return nil
        }
    }
}

extension [InviteLink] {
    init(_ invites: [ExportedInvitation]) {
        self = invites.compactMap { .init($0) }
    }
}

//  MARK: - Api

extension [InviteLink] {
    init(_ invite: Api.ExportedChatInvite?) {
        self.init(
            [invite]
                .compactMap { $0 }
                .map { .init(apiExportedInvite: $0) }
        )
    }
}
