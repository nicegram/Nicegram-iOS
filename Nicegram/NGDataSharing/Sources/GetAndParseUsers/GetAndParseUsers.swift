import AccountContext
import FeatDataSharing

public func getAndParseUsers(context: AccountContext) {
    Task {
        let getAndParseUsersUseCase = DataSharingModule.shared.getAndParseUsersUseCase()
        let parser = UserParserFromApi(context: context)
        try await getAndParseUsersUseCase(
            parse: { username in
                do {
                    let user = try await parser.parse(username)
                    return .success(user)
                } catch {
                    return .error(
                        .init(
                            id: 0,
                            type: "bot",
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
