import AccountContext
import FeatDataSharing
import NGCore
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
        
        let user = TelegramRawApi.user(apiUser)
        let botInfo = try user.botInfo.unwrap()
        let botInfoDetails = (apiUserFull?.botInfo).flatMap {
            TelegramRawApi.botInfo($0)
        }

        return User.build(
            user: user,
            botInfo: botInfo,
            botInfoDetails: botInfoDetails,
            langCode: nil
        )
    }
}

private extension UserParserFromApi {
    func getApiUser(
        _ username: String
    ) async throws -> Api.User {
        let result = try await TelegramRawApi
            .request(
                Api.functions.contacts.resolveUsername(
                    flags: 0,
                    username: username,
                    referer: nil
                ),
                network: context.account.network
            )
            .awaitForFirstValue()
        
        switch result {
        case let .resolvedPeer(resolvedPeer):
            let peer = resolvedPeer.peer
            let users = resolvedPeer.users
            
            let user = users.first {
                TelegramRawApi.peerId($0) == TelegramRawApi.peerId(peer)
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
        
        let result = try await TelegramRawApi
            .request(
                Api.functions.users.getFullUser(id: inputUser),
                network: context.account.network
            )
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
