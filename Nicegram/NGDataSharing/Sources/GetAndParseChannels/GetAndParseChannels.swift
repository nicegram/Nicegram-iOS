import AccountContext
import FeatDataSharing

public func getAndParseChannels(context: AccountContext) {
    Task {
        let getAndParseChannelsUseCase = DataSharingModule.shared.getAndParseChannelsUseCase()
        try await getAndParseChannelsUseCase(
            parse: { username in
                do {
                    let parser = ChannelParserFromApi(context: context)
                    let channel = try await parser.parse(username)
                    return .success(channel)
                } catch {
                    return .error(
                        .init(
                            id: 0,
                            type: "channel",
                            payload: .init(
                                username: username
                            ),
                            error: error.localizedDescription
                        )
                    )
                }
            }
        )
    }
}
