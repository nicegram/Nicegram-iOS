import AccountContext
import FeatDataSharing
import NGCore
import NGUtils
import SwiftSignalKit
import TelegramApi
import TelegramCore

class UserParserFromApi {
    let context: AccountContext

    init(context: AccountContext) {
        self.context = context
    }
}

extension UserParserFromApi {
    func parse(_ username: String) async throws -> User {
        let apiUser = try await getApiUser(username)
        let apiUserFull = try? await getApiUserFull(apiUser)
        
        let user = TelegramUser(user: apiUser)
        let botInfo = try user.botInfo.unwrap()
        let botInfoDetails = (apiUserFull?.botInfo).flatMap {
            BotInfo(apiBotInfo: $0)
        }

        let icon = try? await MediaFetcher(context: context)
            .getAvatarImage(
                peer: user,
                options: .init(
                    fetchIfMissing: true,
                    fetchTimeout: 10
                )
            )
            .base64EncodedString()

        return User.build(
            user: user,
            botInfo: botInfo,
            botInfoDetails: botInfoDetails,
            icon: icon,
            langCode: nil
        )
    }
}

private extension UserParserFromApi {
    func getApiUser(
        _ username: String
    ) async throws -> Api.User {
        let result = try await context.account.network
            .request(
                Api.functions.contacts.resolveUsername(
                    flags: 0,
                    username: username,
                    referer: nil
                )
            )
            .awaitForFirstValue()
        
        switch result {
        case let .resolvedPeer(resolvedPeer):
            let peer = resolvedPeer.peer
            let users = resolvedPeer.users
            
            let user = users.first {
                $0.peerId == peer.peerId
            }
            return try user.unwrap()
        }
    }
    
    func getApiUserFull(
        _ apiUser: Api.User
    ) async throws -> Api.UserFull.Cons_userFull {
        let inputUser = switch apiUser {
        case let .user(user):
            Api.InputUser.inputUser(
                .init(
                    userId: user.id,
                    accessHash: user.accessHash ?? 0
                )
            )
        case .userEmpty:
            throw UnexpectedError()
        }
        
        let result = try await context.account.network
            .request(Api.functions.users.getFullUser(id: inputUser))
            .awaitForFirstValue()
        
        switch result {
        case let .userFull(userFull):
            switch userFull.fullUser {
            case let .userFull(userFull):
                return userFull
            }
        }
    }
}
