import Lottie
import NGCoreUI
import UIKit

class LottieViewImpl: UIView {
    
    //  MARK: - UI Elements
    
    private let animationView = AnimationView(
        configuration: LottieConfiguration(
            renderingEngine: .automatic,
            decodingStrategy: .dictionaryBased
        )
    )
    
    //  MARK: - Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        animationView.backgroundBehavior = .pauseAndRestore
        
        addSubview(animationView)
        animationView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension LottieViewImpl: LottieViewProtocol {
    func play(completion: @escaping () -> Void) {
        animationView.play { _ in
            completion()
        }
    }
    
    func setAnimation(_ animation: NGCoreUI.LottieAnimation) {
        let animation = (animation as? LottieAnimationImpl)?.animation
        animationView.animation = animation
    }
    
    func setImageProvider(_ imageProvider: ImageProvider?) {
        if let imageProvider {
            animationView.imageProvider = AnonymousImageProvider(
                provider: imageProvider
            )
        } else {
            animationView.imageProvider = BundleImageProvider(
                bundle: .main,
                searchPath: nil
            )
        }
    }
    
    func setLoopMode(_ loopMode: LoopMode) {
        let mode: LottieLoopMode
        switch loopMode {
        case .playOnce:
            mode = .playOnce
        case .loop:
            mode = .loop
        case .autoReverse:
            mode = .autoReverse
        case .repeat(let float):
            mode = .repeat(float)
        case .repeatBackwards(let float):
            mode = .repeatBackwards(float)
        }
        
        animationView.loopMode = mode
    }
    
    func stop() {
        animationView.stop()
    }
}

private class AnonymousImageProvider {
    let provider: LottieViewProtocol.ImageProvider
    
    init(provider: LottieViewProtocol.ImageProvider) {
        self.provider = provider
    }
}

extension AnonymousImageProvider: AnimationImageProvider {
    func imageForAsset(asset: ImageAsset) -> CGImage? {
        provider.image(asset.id)
    }
}
