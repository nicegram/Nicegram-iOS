import FeatDataSharing
import NGCore
import Postbox
import TelegramApi
import TelegramCore

//  MARK: - Local

extension FeatDataSharing.Message.Author {
    init?(_ peer: Peer?) {
        guard let peer else { return nil }
        
        let id = peer.id.id._internalGetInt64Value()
        let username = peer.addressName
        let usernames = [String](peer.usernames)
        switch peer {
        case let user as TelegramUser:
            self = .user(
                .init(
                    id: id,
                    firstName: user.firstName,
                    lastName: user.lastName,
                    phone: user.phone,
                    username: username,
                    usernames: usernames
                )
            )
        case let group as TelegramGroup:
            self = .group(
                .init(
                    id: id,
                    title: group.title,
                    username: username,
                    usernames: usernames
                )
            )
        case let channel as TelegramChannel:
            self = .channel(
                .init(
                    id: id,
                    title: channel.title,
                    username: username,
                    usernames: usernames
                )
            )
        default:
            return nil
        }
    }
}

//  MARK: - Api

extension FeatDataSharing.Message.Author {
    init?(
        message: ApiMessageWrapped.Message,
        chats: [Api.Chat],
        users: [Api.User]
    ) {
        let chatPeers = chats.compactMap { peer(with: $0) }
        let userPeers = users.compactMap { TelegramUser(user: $0) }
        let peers = chatPeers + userPeers

        let fromId = (message.fromId ?? message.peerId).id
        let authorPeer = peers.first {
            $0.id.id._internalGetInt64Value() == fromId
        }
        
        self.init(authorPeer)
    }
}
