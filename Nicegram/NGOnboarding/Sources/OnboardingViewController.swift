import UIKit
import UIKitRuntimeUtils
import SnapKit
import NGCoreUI
import NGStrings

class OnboardingViewController: UIViewController {
    
    //  MARK: - UI Elements

    private let pagesStack = UIStackView()
    private let scrollView = UIScrollView()
    private let pageControl = UIStackView()
    private let nextButton = CustomButton()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIDevice.current.userInterfaceIdiom == .phone ? .portrait : .all
    }
    
    //  MARK: - Handlers
    
    private let onComplete: () -> Void
    
    //  MARK: - Logic
    
    private let items: [OnboardingPageViewModel]
    private let languageCode: String
    
    //  MARK: - Lifecycle
    
    init(items: [OnboardingPageViewModel], languageCode: String, onComplete: @escaping () -> Void) {
        self.items = items
        self.languageCode = languageCode
        self.onComplete = onComplete
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        self.view = UIView()
        setupUI()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.delegate = self
        
        display(items: self.items)
        display(buttonTitle: l("NicegramOnboarding.Continue", languageCode))
        
        nextButton.touchUpInside = { [weak self] in
            self?.goToNextPage()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        UIApplication.shared.internalSetStatusBarHidden(true, animation: animated ? .fade : .none)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        updateViewAccordingToCurrentScrollOffset()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        UIApplication.shared.internalSetStatusBarHidden(false, animation: animated ? .fade : .none)
    }
}

extension OnboardingViewController {
    func display(items: [OnboardingPageViewModel]) {
        pagesStack.removeAllArrangedSubviews()
        pageControl.removeAllArrangedSubviews()
        
        for item in items {
            let pageView = OnboardingPageView()
            pageView.display(item)
            
            pagesStack.addArrangedSubview(pageView)
            pageView.snp.makeConstraints { make in
                make.width.equalTo(scrollView)
            }
            
            let pageIndicator = UIView()
            pageIndicator.layer.cornerRadius = 4
            pageIndicator.snp.makeConstraints { make in
                make.width.equalTo(8)
            }
            pageControl.addArrangedSubview(pageIndicator)
        }
    }
    
    func display(buttonTitle: String) {
        nextButton.display(title: buttonTitle, image: nil)
    }
}

extension OnboardingViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateViewAccordingToCurrentScrollOffset()
    }
}

//  MARK: - Private Functions

private extension OnboardingViewController {
    func goToNextPage() {
        let scrollViewWidth = scrollView.frame.width
        guard !scrollViewWidth.isZero else { return }
        
        let currentPage = (scrollView.contentOffset.x + (0.5 * scrollViewWidth)) / scrollViewWidth
        
        let nextPage = Int(currentPage) + 1
        guard items.indices.contains(nextPage) else {
            onComplete()
            return
        }
        
        let visibleRect = CGRect(
            origin: CGPoint(
                x: scrollViewWidth * CGFloat(nextPage),
                y: 0
            ),
            size: scrollView.frame.size
        )
        scrollView.scrollRectToVisible(visibleRect, animated: true)
    }
    
    func updateViewAccordingToCurrentScrollOffset() {
        let offset = scrollView.contentOffset
        let scrollViewSize = scrollView.frame.size
        guard !scrollViewSize.width.isZero else { return }
        
        let pageViews = (pagesStack.arrangedSubviews as? [OnboardingPageView]) ?? []
        for (index, pageView) in pageViews.enumerated() {
            let pageFrame = pageView.frame
            let visibleRect = CGRect(origin: offset, size: scrollViewSize)
            let intersection = pageFrame.intersection(visibleRect)
            
            let fractionWidth = intersection.width / scrollViewSize.width
            
            let pageIndicatorColor = linearInterpolatedColor(from: Constants.inactivePageIndicatorColor, to: Constants.activePageIndicatorColor, fraction: fractionWidth)
            let pageIndicatorWidth = Constants.inactivePageIndicatorWidth + (Constants.activePageIndicatorWidth - Constants.inactivePageIndicatorWidth) * fractionWidth
            
            let pageIndicator = pageControl.arrangedSubviews[index]
            pageIndicator.backgroundColor = pageIndicatorColor
            pageIndicator.snp.updateConstraints { make in
                make.width.equalTo(pageIndicatorWidth)
            }
        
            pageControl.layoutIfNeeded()
            
            var pageView = pageView
            if UIView.userInterfaceLayoutDirection(for: scrollView.semanticContentAttribute) == .rightToLeft {
                pageView = pageViews[pageViews.count - index - 1]
            }
            if fractionWidth >= 0.5 {
                pageView.playVideo()
            } else {
                pageView.pauseVideo()
            }
        }
    }
}

//  MARK: - Constants

private extension OnboardingViewController {
    struct Constants {
        static let inactivePageIndicatorColor = UIColor.hex("333334")
        static let activePageIndicatorColor = UIColor.white
        
        static let inactivePageIndicatorWidth = CGFloat(8)
        static let activePageIndicatorWidth = CGFloat(24)
    }
}

//  MARK: - Setup UI

private extension OnboardingViewController {
    func setupUI() {
        view.backgroundColor = .black
        
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.isPagingEnabled = true
        
        pageControl.spacing = 8
        
        nextButton.applyMainActionStyle()
        
        for view in [scrollView, pagesStack, pageControl] {
            if UIView.userInterfaceLayoutDirection(for: view.semanticContentAttribute) == .rightToLeft {
                view.transform = CGAffineTransform(rotationAngle: .pi)
            }
        }
        
        let scrollContentView = UIView()
        
        scrollContentView.addSubview(pagesStack)
        pagesStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        scrollView.addSubview(scrollContentView)
        scrollContentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalToSuperview()
            make.width.equalToSuperview().priority(1)
        }
        
        view.addSubview(scrollView)
        view.addSubview(pageControl)
        view.addSubview(nextButton)
        
        nextButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(54)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(50)
        }
        
        pageControl.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(nextButton.snp.top).offset(-32)
            make.height.equalTo(8)
        }
        
        scrollView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(pageControl.snp.top).offset(-32)
        }
    }
}

private extension CustomButton {
    func applyMainActionStyle() {
        foregroundColor = .white
        backgroundColor = .legacyBlue
        layer.cornerRadius = 6
        configureTitleLabel { label in
            label.font = .systemFont(ofSize: 16, weight: .semibold)
        }
    }
}

private func linearInterpolatedColor(from: UIColor, to: UIColor, fraction: CGFloat) -> UIColor {
    let f = min(max(0, fraction), 1)

    guard let c1 = from.getComponents(),
          let c2 = to.getComponents() else {
        return from
    }

    let r = c1.r + (c2.r - c1.r) * f
    let g = c1.g + (c2.g - c1.g) * f
    let b = c1.b + (c2.b - c1.b) * f
    let a = c1.a + (c2.a - c1.a) * f

    return UIColor(red: r, green: g, blue: b, alpha: a)
}

private extension UIColor {
    func getComponents() -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat)? {
        let c = cgColor.components ?? []
        if c.count == 2 {
            return (r: c[0], g: c[0], b: c[0], a: c[1])
        } else if c.count == 4 {
            return (r: c[0], g: c[1], b: c[2], a: c[3])
        } else {
            return nil
        }
    }
}
