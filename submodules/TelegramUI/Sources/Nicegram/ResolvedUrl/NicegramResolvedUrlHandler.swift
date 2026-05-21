import AccountContext

class NicegramResolvedUrlHandler {
    private let params: OpenResolvedUrlParams
    
    init(_ params: OpenResolvedUrlParams) {
        self.params = params
    }
}

extension NicegramResolvedUrlHandler {
    func handle(_ url: ResolvedUrl.Nicegram) async {
        await setProgress(true)
        
        switch url {
        case let .autoJoin(autoJoin):
            await AutoJoinHandler(params).handle(autoJoin)
        }
        
        await setProgress(false)
    }
}

private extension NicegramResolvedUrlHandler {
    @MainActor
    func setProgress(_ active: Bool) {
        params.progress?.set(.single(active))
    }
}
