import TelegramApi
import TelegramCore

//  MARK: - Local

extension [String] {
    init(_ usernames: [TelegramPeerUsername]) {
        self = usernames.map(\.username)
    }
}

//  MARK: - Api

extension [String] {
    init(_ usernames: [Api.Username]?) {
        guard let usernames else {
            self = []
            return
        }
        
        self.init(
            usernames.map { TelegramPeerUsername(apiUsername: $0) }
        )
    }
}
