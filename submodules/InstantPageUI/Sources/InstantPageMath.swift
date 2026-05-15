import Foundation
import UIKit
import SwiftMath

enum InstantPageMathMode {
    case inline
    case block
}

struct InstantPageMathRenderResult {
    let image: UIImage
    let size: CGSize
    let width: CGFloat
    let ascent: CGFloat
    let descent: CGFloat
}

final class InstantPageMathAttachment: NSObject {
    let latex: String
    let fontSize: CGFloat
    let textColor: UIColor
    let mode: InstantPageMathMode
    let rendered: InstantPageMathRenderResult

    init(latex: String, fontSize: CGFloat, textColor: UIColor, mode: InstantPageMathMode, rendered: InstantPageMathRenderResult) {
        self.latex = latex
        self.fontSize = fontSize
        self.textColor = textColor
        self.mode = mode
        self.rendered = rendered
    }

    func isEqual(to other: InstantPageMathAttachment) -> Bool {
        return self.latex == other.latex
            && self.fontSize == other.fontSize
            && self.mode == other.mode
            && self.textColor.isEqual(other.textColor)
            && self.rendered.size == other.rendered.size
            && self.rendered.ascent == other.rendered.ascent
            && self.rendered.descent == other.rendered.descent
    }
}

func instantPageMathAttachment(latex: String, fontSize: CGFloat, textColor: UIColor, mode: InstantPageMathMode) -> InstantPageMathAttachment? {
    let effectiveFontSize: CGFloat
    let multiplier: CGFloat = 1.12
    switch mode {
    case .inline:
        effectiveFontSize = fontSize * multiplier
    case .block:
        effectiveFontSize = fontSize * multiplier
    }

    guard let rendered = instantPageRenderMath(latex: latex, fontSize: effectiveFontSize, textColor: textColor, mode: mode) else {
        return nil
    }
    return InstantPageMathAttachment(latex: latex, fontSize: effectiveFontSize, textColor: textColor, mode: mode, rendered: rendered)
}

private func instantPageRenderMath(latex: String, fontSize: CGFloat, textColor: UIColor, mode: InstantPageMathMode) -> InstantPageMathRenderResult? {
    let renderMode: MTMathUILabelMode
    switch mode {
    case .inline:
        renderMode = .text
    case .block:
        renderMode = .display
    }

    guard let rendered = MTMathRenderer.render(latex: latex, fontSize: fontSize, textColor: textColor, mode: renderMode) else {
        return nil
    }
    return InstantPageMathRenderResult(
        image: rendered.image,
        size: rendered.size,
        width: rendered.width,
        ascent: rendered.ascent,
        descent: rendered.descent
    )
}
