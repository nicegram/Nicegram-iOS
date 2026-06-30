import Foundation
import UIKit
import AsyncDisplayKit
import Display
import AccountContext
import TelegramCore
import TelegramPresentationData

// A paged carousel for an `InstantPageBlock.slideshow`. Ports V1's InstantPageSlideshowNode /
// InstantPageSlideshowPagerNode (InstantPageSlideshowItemNode.swift), simplified to create all pages
// eagerly (slideshows are short; this avoids V1's central±1 index bookkeeping and makes the gallery
// transition source available for every page). Each image page hosts an `InstantPageImageNode` exactly
// like the static media views; non-image medias render an empty page (matches V1).
final class InstantPageV2SlideshowView: UIView, InstantPageItemView, UIScrollViewDelegate {
    private(set) var item: InstantPageV2SlideshowItem
    var itemFrame: CGRect { return self.item.frame }

    private let renderContext: InstantPageV2RenderContext
    private var theme: InstantPageTheme

    private let scrollView: UIScrollView
    private let pageControlNode: PageControlNode

    // One wrapper view per media (so page count stays aligned with the page control). `pageImageNodes`
    // holds only the real image nodes; it may be shorter than `pageViews` if a non-image media appears
    // (which `layoutSlideshow` currently filters out). Nothing relies on positional correspondence.
    private var pageViews: [UIView] = []
    private var pageImageNodes: [InstantPageImageNode] = []

    init(item: InstantPageV2SlideshowItem, renderContext: InstantPageV2RenderContext, theme: InstantPageTheme) {
        self.item = item
        self.renderContext = renderContext
        self.theme = theme
        self.scrollView = UIScrollView()
        self.pageControlNode = PageControlNode(dotColor: .white, inactiveDotColor: UIColor(white: 1.0, alpha: 0.5))

        super.init(frame: item.frame)

        self.backgroundColor = theme.panelSecondaryColor   // structural
        self.clipsToBounds = true                          // structural

        self.scrollView.disablesInteractiveTransitionGestureRecognizer = true
        
        self.scrollView.isPagingEnabled = true
        self.scrollView.showsHorizontalScrollIndicator = false
        self.scrollView.showsVerticalScrollIndicator = false
        self.scrollView.scrollsToTop = false
        if #available(iOS 11.0, *) {
            self.scrollView.contentInsetAdjustmentBehavior = .never
        }
        self.scrollView.delegate = self
        self.addSubview(self.scrollView)                   // structural

        self.pageControlNode.isUserInteractionEnabled = false
        self.addSubview(self.pageControlNode.view)         // structural

        self.rebuildPages()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func rebuildPages() {
        for view in self.pageViews {
            view.removeFromSuperview()
        }
        self.pageViews = []
        self.pageImageNodes = []

        let renderContext = self.renderContext
        // The image node owns this closure, and is owned (transitively) by self — capture weakly.
        let openMedia: (InstantPageMedia) -> Void = { [weak self] tapped in
            guard let self else { return }
            handleOpenMediaTap(tapped: tapped, wrapper: self, renderContext: renderContext)
        }

        for media in self.item.medias {
            let pageView = UIView()
            pageView.clipsToBounds = true
            if case .image = media.media {
                let node = makeMediaWrapper(
                    frame: CGRect(origin: .zero, size: self.item.frame.size),
                    media: media,
                    webPage: self.item.webPage,
                    attributes: [],
                    renderContext: self.renderContext,
                    theme: self.theme,
                    openMedia: openMedia,
                    longPressMedia: { _ in }
                )
                pageView.addSubview(node.view)
                self.pageImageNodes.append(node)
            }
            // Non-image medias (none in practice — layoutSlideshow filters to images) get an empty page
            // to keep page indices aligned with the page control.
            self.scrollView.addSubview(pageView)
            self.pageViews.append(pageView)
        }

        self.pageControlNode.pagesCount = self.item.medias.count
        self.pageControlNode.setPage(0.0)
        // Re-register media indices when rebuilding while already on-window (positional reuse with
        // changed content); no-ops before the view is attached, where didMoveToWindow handles it.
        self.registerMedias()
        self.setNeedsLayout()
    }

    private func registerMedias() {
        guard self.window != nil else { return }
        // Register under every contained media index so transitionArgsFor(media) can find this view.
        for media in self.item.medias {
            registerInRootRegistry(wrapper: self, mediaIndex: media.index)
        }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        self.registerMedias()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let size = self.bounds.size
        guard size.width > 0.0, size.height > 0.0 else { return }

        self.scrollView.frame = CGRect(origin: .zero, size: size)
        for (i, pageView) in self.pageViews.enumerated() {
            pageView.frame = CGRect(x: CGFloat(i) * size.width, y: 0.0, width: size.width, height: size.height)
        }
        for node in self.pageImageNodes {
            node.frame = CGRect(origin: .zero, size: size)
        }
        self.scrollView.contentSize = CGSize(width: CGFloat(self.pageViews.count) * size.width, height: size.height)

        self.pageControlNode.layer.transform = CATransform3DIdentity
        self.pageControlNode.frame = CGRect(x: 0.0, y: size.height - 20.0, width: size.width, height: 20.0)
        let maxWidth = size.width - 36.0
        let pageControlSize = self.pageControlNode.calculateSizeThatFits(size)
        if pageControlSize.width > maxWidth, pageControlSize.width > 0.0 {
            let scale = maxWidth / pageControlSize.width
            self.pageControlNode.layer.transform = CATransform3DMakeScale(scale, scale, 1.0)
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let width = self.bounds.size.width
        guard width > 0.0, !self.item.medias.isEmpty else { return }
        let page = Int((scrollView.contentOffset.x + width / 2.0) / width)
        let clamped = max(0, min(self.item.medias.count - 1, page))
        self.pageControlNode.setPage(CGFloat(clamped))
    }

    func update(item: InstantPageV2SlideshowItem, theme: InstantPageTheme, renderContext: InstantPageV2RenderContext) {
        let mediasChanged = self.item.medias.map { $0.index } != item.medias.map { $0.index }
        self.item = item
        self.theme = theme
        self.backgroundColor = theme.panelSecondaryColor
        if mediasChanged {
            self.rebuildPages()
        } else {
            let strings = renderContext.context.sharedContext.currentPresentationData.with { $0 }.strings
            for node in self.pageImageNodes {
                node.update(strings: strings, theme: theme)
            }
        }
        self.setNeedsLayout()
    }

    // MARK: InstantPageItemView gallery hooks

    func instantPageTransitionNode(for media: InstantPageMedia) -> (ASDisplayNode, CGRect, () -> (UIView?, UIView?))? {
        for node in self.pageImageNodes {
            if let transition = node.transitionNode(media: media) {
                return transition
            }
        }
        return nil
    }

    func instantPageUpdateHiddenMedia(_ media: InstantPageMedia?) {
        for node in self.pageImageNodes {
            node.updateHiddenMedia(media: media)
        }
    }
}
