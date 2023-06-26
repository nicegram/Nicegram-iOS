import Lottie
import NGCoreUI
import UIKit

public class LottieViewImpl: UIView {
    
    //  MARK: - UI Elements
    
    private let animationView = AnimationView()
    
    //  MARK: - Lifecycle
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(animationView)
        animationView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension LottieViewImpl: LottieView {
    public func play(completion: @escaping () -> Void) {
        animationView.play { _ in
            completion()
        }
    }
    
    public func setAnimation(name: String, bundle: Bundle) {
        animationView.animation = Animation.named(name, bundle: bundle)
    }
}
