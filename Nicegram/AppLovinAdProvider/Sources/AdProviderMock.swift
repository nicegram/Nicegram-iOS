import NGAiChat

public class AdProviderMock {
    public init() {}
}

extension AdProviderMock: AdProvider {
    public func initialize() {}
    
    public func showAd() -> ShowAdResult {
        .error(nil)
    }
}
