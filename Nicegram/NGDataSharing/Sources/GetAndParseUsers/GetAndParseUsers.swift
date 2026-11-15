import AccountContext
import NGUtils
import FeatDataSharing

public func getAndParseUsers(context: AccountContext) {
    // Nicegram Business, work-account data sharing: parse-users
    guard !context.nicegramBusiness.restrictsAccountControl() else {
        return
    }
    //
    _ = Task {
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
