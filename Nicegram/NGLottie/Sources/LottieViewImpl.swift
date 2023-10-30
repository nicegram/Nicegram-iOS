import Lottie
import NGCoreUI
import UIKit

public class LottieViewImpl: UIView {
    
    //  MARK: - UI Elements
    
    private let animationView = AnimationView()
    
    //  MARK: - Lifecycle
    
    public override init(frame: CGRect) {
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
    public func play(completion: @escaping () -> Void) {
        animationView.play { _ in
            completion()
        }
    }
    
    public func setAnimation(fileUrl: URL?) {
        guard let fileUrl else { return }
        animationView.animation = Animation.filepath(
            fileUrl._wrapperPath()
        )
    }
    
    public func setLoopMode(_ loopMode: LoopMode) {
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
    
    public func stop() {
        animationView.stop()
    }
}
