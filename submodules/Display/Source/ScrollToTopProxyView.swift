import UIKit
import AsyncDisplayKit

class ScrollToTopView: UIScrollView, UIScrollViewDelegate {
    var action: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.isOpaque = false
        self.delegate = self
        self.scrollsToTop = true
        self.contentInsetAdjustmentBehavior = .never
        if #available(iOS 17.0, *) {
            self.allowsKeyboardScrolling = false
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var frame: CGRect {
        didSet {
            let frame = self.frame
            self.contentSize = CGSize(width: frame.width, height: frame.height + 1000.0)
            self.contentOffset = CGPoint(x: 0.0, y: 1000.0)
        }
    }
    
    @objc func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        if let action = self.action {
            action()
        }
        
        return false
    }
    
    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        print("scrollViewDidScrollToTop")
    }
}

class ScrollToTopNode: ASDisplayNode {
    init(action: @escaping () -> Void) {
        super.init()
        
        self.setViewBlock({
            let view = ScrollToTopView(frame: CGRect())
            view.action = action
            return view
        })
    }
}
