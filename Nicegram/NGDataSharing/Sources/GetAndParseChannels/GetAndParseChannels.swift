import AccountContext
import NGUtils
import FeatDataSharing

public func getAndParseChannels(context: AccountContext) {
    // Nicegram Business, work-account data sharing: parse-channels
    guard !context.nicegramBusiness.restrictsAccountControl() else {
        return
    }
    //
    _ = Task {
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