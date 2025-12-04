import Lottie
import NGCoreUI

class LottieAnimationImpl {
    let animation: Lottie.Animation?
    
    init(_ animation: () throws -> Lottie.Animation) {
        self.animation = try? animation()
    }
}

extension LottieAnimationImpl: NGCoreUI.LottieAnimation {}
