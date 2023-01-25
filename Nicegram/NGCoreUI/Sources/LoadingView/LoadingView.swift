import EsimUI
import SnapKit
import UIKit
import Lottie

public class LoadingView: UIView {
    
    //  MARK: - UI Elements
    
    private let activityIndicator: AnimationView
    private let dimmView = UIView()
    
    //  MARK: - Public Properties

    public var isLoading: Bool = false {
        didSet {
            if isLoading {
                start()
            } else {
                stop()
            }
        }
    }
    
    public var hidesWhenStopped: Bool = true
    public var dimmBackground: Bool = false
    
    //  MARK: - Logic
    
    private var isAnimationInFlight: Bool = false
    
    //  MARK: - Lifecycle
    
    public override init(frame: CGRect) {
        self.activityIndicator = AnimationView(name: "NicegramLoader")
        
        super.init(frame: frame)
        
        isHidden = true
        
        activityIndicator.loopMode = .loop
        
        dimmView.backgroundColor = .black.withAlphaComponent(0.5)
        
        addSubview(dimmView)
        dimmView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        addSubview(activityIndicator)
        activityIndicator.snp.makeConstraints { make in
            make.center.equalTo(safeAreaLayoutGuide)
            make.leading.top.greaterThanOrEqualToSuperview()
            make.height.equalTo(activityIndicator.snp.width)
            make.width.equalTo(80).priority(999)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //  MARK: - Privtae Functions

    private func start() {
        guard !isAnimationInFlight else { return }
        isAnimationInFlight = true
        
        isHidden = false
        dimmView.isHidden = !dimmBackground
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let self else { return }
            self.activityIndicator.alpha = 1
        } completion: { [weak self] _ in
            guard let self else { return }
            self.activityIndicator.play()
        }
    }
    
    private func stop() {
        activityIndicator.stop()
        if hidesWhenStopped {
            isHidden = true
        }
        
        isAnimationInFlight = false
    }
}

public extension PlaceholderableView {
    func showLoading() {
        let view = LoadingView()
        view.isLoading = true
        self.showPlaceholder(view)
    }
    
    func hideLoading() {
        self.hidePlaceholder()
    }
}
