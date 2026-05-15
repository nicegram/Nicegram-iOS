import Swift2D
import SwiftSVG
#if canImport(UIKit) && !os(watchOS)
import UIKit

@IBDesignable open class SVGImageView: UIImageView {

    public var width: CGFloat {
        CGFloat(svg.originalSize.width)
    }

    public var height: CGFloat {
        CGFloat(svg.originalSize.height)
    }

    open var svg: SVG = SVG() {
        didSet {
            updateSubviews()
        }
    }

    public var widthToHeightAspectRatio: CGFloat {
        guard !width.isNaN, width > 0.0 else {
            return 0.0
        }

        guard !height.isNaN, height > 0.0 else {
            return 0.0
        }

        return width / height
    }

    public var heightToWidthAspectRatio: CGFloat {
        guard !height.isNaN, height > 0.0 else {
            return 0.0
        }

        guard !width.isNaN, width > 0.0 else {
            return 0.0
        }

        return height / width
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        updateSubviews()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        updateSubviews()
    }

    override public var intrinsicContentSize: CGSize {
        CGSize(width: width, height: height)
    }

    override public var bounds: CGRect {
        didSet {
            updateSubviews()
        }
    }

    override public func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        updateSubviews()
    }

    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateSubviews()
    }

    public func updateSubviews() {
        image = svg.uiImage(size: Size(bounds.size))
    }
}

#endif
