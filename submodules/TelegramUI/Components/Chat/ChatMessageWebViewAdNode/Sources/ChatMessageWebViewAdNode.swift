import AsyncDisplayKit
import ChatMessageItemCommon
import ChatMessageItemView
import Combine
import Display
import NGCore
import ShareController
import WebKit

@available(iOS 15.0, *)
class ChatMessageWebViewAdNode: ListViewItemNode {
    private let layoutConstants = (ChatMessageItemLayoutConstants.compact, ChatMessageItemLayoutConstants.regular)
    
    var item: ChatMessageWebViewAdItem?
    
    private let bannerView: AdWebView
    private let bannerNode: ASDisplayNode
    
    override var visibility: ListViewItemNodeVisibility {
        didSet {
            let visiblePart: Double
            switch visibility {
            case .none:
                visiblePart = 0.0
            case let .visible(part, _):
                visiblePart = part
            }
        }
    }
    
    required init(rotated: Bool) {
        let bannerView = AdWebView()
        self.bannerView = bannerView
        self.bannerNode = ASDisplayNode {
            bannerView
        }
        
        super.init(layerBacked: false, dynamicBounce: true, rotated: rotated)
        
        if rotated {
            self.transform = CATransform3DMakeRotation(CGFloat.pi, 0.0, 0.0, 1.0)
        }
        
        self.addSubnode(bannerNode)
    }
    
    func setupItem(_ item: ChatMessageWebViewAdItem) {
        self.item = item
    }
    
    override func layoutForParams(_ params: ListViewItemLayoutParams, item: ListViewItem, previousItem: ListViewItem?, nextItem: ListViewItem?) {
        
    }
    
    func asyncLayout() -> (_ item: ChatMessageWebViewAdItem, _ params: ListViewItemLayoutParams, _ mergedTop: Bool, _ mergedBottom: Bool, _ dateAtBottom: Bool) -> (ListViewItemNodeLayout, (ListViewItemUpdateAnimation) -> Void) {
        return { [weak self] item, params, mergedTop, mergedBottom, dateHeaderAtBottom -> (ListViewItemNodeLayout, (ListViewItemUpdateAnimation) -> Void) in
            guard let self else {
                return (
                    ListViewItemNodeLayout(
                        contentSize: .zero,
                        insets: .zero
                    ),
                    { _ in }
                )
            }
            
            let presentationData = item.presentationData
            let layoutConstants = chatMessageItemLayoutConstants(layoutConstants, params: params, presentationData: presentationData)
            var insets = layoutConstants.bubble.contentInsets
                    .sum(.vertical(layoutConstants.bubble.defaultSpacing))
                    .sum(.horizontal(layoutConstants.bubble.edgeInset))
                    .sum(.left(params.leftInset).right(params.rightInset))
            let horizontalInsets = max(insets.left, insets.right)
            insets.left = horizontalInsets
            insets.right = horizontalInsets
            
            let size = CGSize(
                width: params.width,
                height: 115
            )
            
            let layout = ListViewItemNodeLayout(
                contentSize: size,
                insets: .zero
            )
            
            let apply: (ListViewItemUpdateAnimation) -> Void = { [weak self] _ in
                guard let self else { return }
                bannerNode.frame = CGRect(origin: .zero, size: size)
                    .inset(by: insets)
            }
            
            return (layout, apply)
        }
    }
    
    override public func animateInsertion(_ currentTimestamp: Double, duration: Double, options: ListViewItemAnimationOptions) {
        super.animateInsertion(currentTimestamp, duration: duration, options: options)
        
        self.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2)
    }
    
    override public func animateRemoved(_ currentTimestamp: Double, duration: Double) {
        super.animateRemoved(currentTimestamp, duration: duration)
        
        self.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.2, removeOnCompletion: false)
    }
    
    override public func animateAdded(_ currentTimestamp: Double, duration: Double) {
        super.animateAdded(currentTimestamp, duration: duration)
        
        self.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2)
    }
}

private class AdWebView: UIView {
    private let webView = WKWebView()
    
    private let log = NGCore.Log(category: "web-view-ad")
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        super.init(frame: .zero)
        
        self.layer.masksToBounds = true
        self.layer.cornerRadius = 16
        
        webView.navigationDelegate = self
        webView.uiDelegate = self
        
        webView.loadHTMLString(
            "<ins class=\"353c53b9\" data-key=\"bcbe3580e70a0f41972da0a03333b971\"></ins><script async src=\"https://adscdn.adhost.io/0a2586fe.js\"></script>",
            baseURL: nil
        )
        
        webView.publisher(for: \.isLoading)
            .sink { [weak self] isLoading in
                guard let self else { return }
                log("isLoading=\(isLoading)")
            }
            .store(in: &cancellables)
        
        self.addSubview(webView)
        webView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AdWebView: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        log("decide policy for action \(navigationAction.logDesc)")
        return .allow
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse) async -> WKNavigationResponsePolicy {
        log("decide policy for response \(navigationResponse.logDesc)")
        return .allow
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        log("navigation from the main frame has started")
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        log("received a server redirect for a request")
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        log("has started to receive content for the main frame")
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        log("navigation is complete")
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: any Error) {
        log("didFail navigation \(error)")
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: any Error) {
        log("didFailProvisionalNavigation navigation \(error)")
    }
    
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        log("webViewWebContentProcessDidTerminate")
    }
}

extension AdWebView: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        log("creates a new web view \(navigationAction.logDesc)")
        webView.load(navigationAction.request)
        return nil
    }
}

private extension WKNavigationAction {
    var logDesc: String {
        self.request.url?.absoluteString ?? ""
    }
}

private extension WKNavigationResponse {
    var logDesc: String {
        self.response.url?.absoluteString ?? ""
    }
}

private extension UIEdgeInsets {
    func sum(_ other: UIEdgeInsets) -> UIEdgeInsets {
        UIEdgeInsets(
            top: self.top + other.top,
            left: self.left + other.left,
            bottom: self.bottom + other.bottom,
            right: self.right + other.right
        )
    }
}
