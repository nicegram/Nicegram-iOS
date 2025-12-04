import Foundation
import Lottie
import NGCoreUI

class LottieAnimationProviderImpl {}

extension LottieAnimationProviderImpl: LottieAnimationProvider {
    func load(data: Data) -> NGCoreUI.LottieAnimation {
        LottieAnimationImpl {
            try .from(data: data)
        }
    }
    
    func load(url: URL?) -> NGCoreUI.LottieAnimation {
        LottieAnimationImpl {
            try .filepath(url.unwrap()._wrapperPath()).unwrap()
        }
    }
}
