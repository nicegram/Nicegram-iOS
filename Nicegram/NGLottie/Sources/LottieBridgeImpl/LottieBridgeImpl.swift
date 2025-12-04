import NGCoreUI

public class LottieBridgeImpl {
    public init() {}
}

extension LottieBridgeImpl: LottieBridge {
    public func lottieAnimationProvider() -> LottieAnimationProvider {
        LottieAnimationProviderImpl()
    }
    
    public func lottieView() -> LottieViewProtocol {
        LottieViewImpl()
    }
}
