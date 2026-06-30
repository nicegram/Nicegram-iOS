import Foundation
import UIKit
import TelegramCore
import Display
import AsyncDisplayKit
import TelegramPresentationData
import TelegramUIPreferences
import TextFormat
import AccountContext
import ContextUI

public final class InstantPageUrlItem: Equatable {
    public let url: String
    public let webpageId: EngineMedia.Id?
    
    public init(url: String, webpageId: EngineMedia.Id?) {
        self.url = url
        self.webpageId = webpageId
    }
    
    public static func ==(lhs: InstantPageUrlItem, rhs: InstantPageUrlItem) -> Bool {
        return lhs.url == rhs.url && lhs.webpageId == rhs.webpageId
    }
}

struct InstantPageTextMarkedItem {
    let frame: CGRect
    let color: UIColor
    let range: NSRange
}

struct InstantPageTextSpoilerItem {
    let frame: CGRect
    let range: NSRange
}

struct InstantPageTextStrikethroughItem {
    let frame: CGRect
}

struct InstantPageTextUnderlineItem {
    let frame: CGRect
    let range: NSRange
    let color: UIColor?
}

struct InstantPageTextImageItem {
    let frame: CGRect
    let range: NSRange
    let id: EngineMedia.Id
}

struct InstantPageTextFormulaRun {
    let frame: CGRect
    let range: NSRange
    let attachment: InstantPageMathAttachment
}

struct InstantPageTextEmojiItem {
    let frame: CGRect
    let range: NSRange
    let emoji: ChatTextInputTextCustomEmojiAttribute
}

public struct InstantPageTextAnchorItem {
    public let name: String
    public let anchorText: NSAttributedString?
    public let empty: Bool
}

public struct InstantPageTextRangeRectEdge: Equatable {
    public var x: CGFloat
    public var y: CGFloat
    public var height: CGFloat
    
    public init(x: CGFloat, y: CGFloat, height: CGFloat) {
        self.x = x
        self.y = y
        self.height = height
    }
}

public final class InstantPageTextLine {
    let line: CTLine
    let range: NSRange
    public let frame: CGRect
    let strikethroughItems: [InstantPageTextStrikethroughItem]
    let underlineItems: [InstantPageTextUnderlineItem]
    let markedItems: [InstantPageTextMarkedItem]
    let spoilerItems: [InstantPageTextSpoilerItem]
    let imageItems: [InstantPageTextImageItem]
    let formulaItems: [InstantPageTextFormulaRun]
    let emojiItems: [InstantPageTextEmojiItem]
    public let anchorItems: [InstantPageTextAnchorItem]
    let isRTL: Bool
    public let characterRects: [CGRect]?   // line-local, one rect per character in `range`; nil = not computed

    init(line: CTLine, range: NSRange, frame: CGRect, strikethroughItems: [InstantPageTextStrikethroughItem], underlineItems: [InstantPageTextUnderlineItem], markedItems: [InstantPageTextMarkedItem], spoilerItems: [InstantPageTextSpoilerItem] = [], imageItems: [InstantPageTextImageItem], formulaItems: [InstantPageTextFormulaRun], emojiItems: [InstantPageTextEmojiItem] = [], anchorItems: [InstantPageTextAnchorItem], isRTL: Bool, characterRects: [CGRect]? = nil) {
        self.line = line
        self.range = range
        self.frame = frame
        self.strikethroughItems = strikethroughItems
        self.underlineItems = underlineItems
        self.markedItems = markedItems
        self.spoilerItems = spoilerItems
        self.imageItems = imageItems
        self.formulaItems = formulaItems
        self.emojiItems = emojiItems
        self.anchorItems = anchorItems
        self.isRTL = isRTL
        self.characterRects = characterRects
    }
}

private func frameForLine(_ line: InstantPageTextLine, boundingWidth: CGFloat, alignment: NSTextAlignment) -> CGRect {
    var lineFrame = line.frame
    if alignment == .center {
        lineFrame.origin.x = floor((boundingWidth - lineFrame.size.width) / 2.0)
    } else if alignment == .right || (alignment == .natural && line.isRTL) {
        lineFrame.origin.x = boundingWidth - lineFrame.size.width
    }
    return lineFrame
}

private func expandedFrameForLine(_ line: InstantPageTextLine, boundingWidth: CGFloat, alignment: NSTextAlignment) -> CGRect {
    var lineFrame = line.frame
    for imageItem in line.imageItems {
        if imageItem.frame.minY < lineFrame.minY {
            let delta = lineFrame.minY - imageItem.frame.minY - 2.0
            lineFrame = CGRect(x: lineFrame.minX, y: lineFrame.minY - delta, width: lineFrame.width, height: lineFrame.height + delta)
        }
        if imageItem.frame.maxY > lineFrame.maxY {
            let delta = imageItem.frame.maxY - lineFrame.maxY - 2.0
            lineFrame = CGRect(x: lineFrame.minX, y: lineFrame.minY, width: lineFrame.width, height: lineFrame.height + delta)
        }
    }
    for formulaItem in line.formulaItems {
        if formulaItem.frame.minY < lineFrame.minY {
            let delta = lineFrame.minY - formulaItem.frame.minY - 2.0
            lineFrame = CGRect(x: lineFrame.minX, y: lineFrame.minY - delta, width: lineFrame.width, height: lineFrame.height + delta)
        }
        if formulaItem.frame.maxY > lineFrame.maxY {
            let delta = formulaItem.frame.maxY - lineFrame.maxY - 2.0
            lineFrame = CGRect(x: lineFrame.minX, y: lineFrame.minY, width: lineFrame.width, height: lineFrame.height + delta)
        }
    }
    lineFrame = lineFrame.insetBy(dx: 0.0, dy: -4.0)
    if alignment == .center {
        lineFrame.origin.x = floor((boundingWidth - lineFrame.size.width) / 2.0)
    } else if alignment == .right || (alignment == .natural && line.isRTL) {
        lineFrame.origin.x = boundingWidth - lineFrame.size.width
    }
    return lineFrame
}

private func alignedAttachmentFrame(_ frame: CGRect, line: InstantPageTextLine, boundingWidth: CGFloat, alignment: NSTextAlignment) -> CGRect {
    let lineFrame = frameForLine(line, boundingWidth: boundingWidth, alignment: alignment)
    return frame.offsetBy(dx: lineFrame.minX - line.frame.minX, dy: 0.0)
}

private func localAttachmentBoundsForRange(_ range: NSRange, imageItems: [InstantPageTextImageItem], formulaItems: [InstantPageTextFormulaRun]) -> CGRect? {
    var result: CGRect?

    for imageItem in imageItems {
        if NSIntersectionRange(range, imageItem.range).length != 0 {
            if let current = result {
                result = current.union(imageItem.frame)
            } else {
                result = imageItem.frame
            }
        }
    }

    for formulaItem in formulaItems {
        if NSIntersectionRange(range, formulaItem.range).length != 0 {
            if let current = result {
                result = current.union(formulaItem.frame)
            } else {
                result = formulaItem.frame
            }
        }
    }

    return result
}

private func attachmentBoundsForRange(_ range: NSRange, line: InstantPageTextLine, boundingWidth: CGFloat, alignment: NSTextAlignment) -> CGRect? {
    guard let localBounds = localAttachmentBoundsForRange(range, imageItems: line.imageItems, formulaItems: line.formulaItems) else {
        return nil
    }
    return alignedAttachmentFrame(localBounds, line: line, boundingWidth: boundingWidth, alignment: alignment)
}

/// Block-level role of a text item, used to reconstruct markdown from a
/// selection. `kind` is the primary role; `quoteDepth` (0 = not quoted) is
/// orthogonal so a heading/list/code line inside a blockquote can be emitted
/// as e.g. `> ## Title`.
public struct InstantPageMarkdownBlockContext: Equatable {
    public enum Kind: Equatable {
        case paragraph
        case heading(level: Int)                                  // 1...6
        case title                                                // InstantPageBlock.title → "# "
        case listItem(ordered: Bool, marker: String, checked: Bool?)
        case code(language: String?)
        case tableCell(row: Int, column: Int, isHeader: Bool)
    }

    public var kind: Kind
    public var quoteDepth: Int

    public init(kind: Kind, quoteDepth: Int = 0) {
        self.kind = kind
        self.quoteDepth = quoteDepth
    }
}

public final class InstantPageTextItem: InstantPageItem {
    public let attributedString: NSAttributedString
    public let lines: [InstantPageTextLine]
    let rtlLineIndices: Set<Int>
    public var frame: CGRect
    let alignment: NSTextAlignment
    let opaqueBackground: Bool
    public let medias: [InstantPageMedia] = []
    public let anchors: [String: (Int, Bool)]
    public let wantsNode: Bool = false
    public let separatesTiles: Bool = false
    public var selectable: Bool = true
    public var markdownContext: InstantPageMarkdownBlockContext? = nil

    var containsRTL: Bool {
        return !self.rtlLineIndices.isEmpty
    }
    
    init(frame: CGRect, attributedString: NSAttributedString, alignment: NSTextAlignment, opaqueBackground: Bool, lines: [InstantPageTextLine]) {
        self.attributedString = attributedString
        self.alignment = alignment
        self.frame = frame
        self.opaqueBackground = opaqueBackground
        self.lines = lines
        var index = 0
        var rtlLineIndices = Set<Int>()
        var anchors: [String: (Int, Bool)] = [:]
        for line in lines {
            if line.isRTL {
                rtlLineIndices.insert(index)
            }
            for anchor in line.anchorItems {
                anchors[anchor.name] = (index, anchor.empty)
            }
            index += 1
        }
        self.rtlLineIndices = rtlLineIndices
        self.anchors = anchors
    }
    
    public func drawInTile(context: CGContext) {
        context.saveGState()
        context.textMatrix = CGAffineTransform(scaleX: 1.0, y: -1.0)
        context.translateBy(x: self.frame.minX, y: self.frame.minY)
        
        let clipRect = context.boundingBoxOfClipPath
        
        let upperOriginBound = clipRect.minY - 10.0
        let lowerOriginBound = clipRect.maxY + 10.0
        let boundsWidth = self.frame.size.width
        
        for i in 0 ..< self.lines.count {
            let line = self.lines[i]
            let lineFrame = frameForLine(line, boundingWidth: boundsWidth, alignment: self.alignment)
            if lineFrame.maxY < upperOriginBound || lineFrame.minY > lowerOriginBound {
                continue
            }
            
            let lineOrigin = lineFrame.origin
            context.textPosition = CGPoint(x: lineOrigin.x, y: lineOrigin.y + lineFrame.size.height)
            
            if !line.markedItems.isEmpty {
                context.saveGState()
                for item in line.markedItems {
                    let itemFrame = item.frame.offsetBy(dx: lineFrame.minX, dy: 0.0)
                    context.setFillColor(item.color.cgColor)
                    
                    let height = floor(item.frame.size.height * 2.2)
                    let rect = CGRect(x: itemFrame.minX - 2.0, y: floor(itemFrame.minY + (itemFrame.height - height) / 2.0), width: itemFrame.width + 4.0, height: height)
                    let path = UIBezierPath.init(roundedRect: rect, cornerRadius: 3.0)
                    context.addPath(path.cgPath)
                    context.fillPath()
                }
                context.restoreGState()
            }
            
            if self.opaqueBackground {
                context.setBlendMode(.normal)
            }
            
            let glyphRuns = CTLineGetGlyphRuns(line.line) as NSArray
            if glyphRuns.count != 0 {
                for run in glyphRuns {
                    let run = run as! CTRun
                    let glyphCount = CTRunGetGlyphCount(run)
                    CTRunDraw(run, context, CFRangeMake(0, glyphCount))
                }
            }
                        
            if self.opaqueBackground {
                context.setBlendMode(.copy)
            }
            
            if !line.strikethroughItems.isEmpty {
                for item in line.strikethroughItems {
                    let itemFrame = item.frame.offsetBy(dx: lineFrame.minX, dy: 0.0)
                    context.fill(CGRect(x: itemFrame.minX, y: itemFrame.minY + floor((lineFrame.size.height / 2.0) + 1.0), width: itemFrame.size.width, height: 1.0))
                }
            }

            if !line.underlineItems.isEmpty {
                for item in line.underlineItems {
                    var color: UIColor? = item.color
                    if color == nil {
                        self.attributedString.enumerateAttributes(in: item.range, options: []) { attributes, _, _ in
                            if let foreground = attributes[NSAttributedString.Key.foregroundColor] as? UIColor {
                                color = foreground
                            }
                        }
                    }
                    if let color {
                        context.setFillColor(color.cgColor)
                    }
                    let itemFrame = item.frame.offsetBy(dx: lineFrame.minX, dy: 0.0)
                    context.fill(CGRect(x: itemFrame.minX, y: itemFrame.minY + lineFrame.size.height + 2.0, width: itemFrame.size.width, height: 1.0))
                }
            }
        }
        
        context.restoreGState()
    }
    
    func attributesAtPoint(_ point: CGPoint) -> (Int, [NSAttributedString.Key: Any])? {
        let transformedPoint = CGPoint(x: point.x, y: point.y)
        let boundsWidth = self.frame.width
        for i in 0 ..< self.lines.count {
            let line = self.lines[i]

            let lineFrame = expandedFrameForLine(line, boundingWidth: boundsWidth, alignment: self.alignment)
            if lineFrame.insetBy(dx: -5.0, dy: -5.0).contains(transformedPoint) {
                var index = CTLineGetStringIndexForPosition(line.line, CGPoint(x: transformedPoint.x - lineFrame.minX, y: transformedPoint.y - lineFrame.minY))
                if index == self.attributedString.length {
                    index -= 1
                } else if index != 0 {
                    var glyphStart: CGFloat = 0.0
                    CTLineGetOffsetForStringIndex(line.line, index, &glyphStart)
                    if transformedPoint.x < glyphStart {
                        index -= 1
                    }
                }
                if index >= 0 && index < self.attributedString.length {
                    return (index, self.attributedString.attributes(at: index, effectiveRange: nil))
                }
                break
            }
        }
        return nil
    }

    public func attributesAtPoint(_ point: CGPoint, orNearest: Bool) -> (Int, [NSAttributedString.Key: Any])? {
        // Hit-testing (taps on links/entities) wants the character under the finger — keep the
        // strict, clamping behavior.
        if !orNearest {
            return self.attributesAtPoint(point)
        }
        guard !self.lines.isEmpty else {
            return nil
        }

        // Selection drags can travel outside the text bounds, so pick the vertically-closest line.
        let boundsWidth = self.frame.width
        var nearestLineIndex = 0
        var nearestDistance = CGFloat.greatestFiniteMagnitude
        for i in 0 ..< self.lines.count {
            let lineFrame = expandedFrameForLine(self.lines[i], boundingWidth: boundsWidth, alignment: self.alignment)
            let distance: CGFloat
            if point.y < lineFrame.minY {
                distance = lineFrame.minY - point.y
            } else if point.y > lineFrame.maxY {
                distance = point.y - lineFrame.maxY
            } else {
                distance = 0.0
            }
            if distance < nearestDistance {
                nearestDistance = distance
                nearestLineIndex = i
            }
        }

        let line = self.lines[nearestLineIndex]
        let lineFrame = expandedFrameForLine(line, boundingWidth: boundsWidth, alignment: self.alignment)
        let lineRange = CTLineGetStringRange(line.line)
        var index: Int
        if point.x <= lineFrame.minX {
            index = lineRange.location
        } else if point.x >= lineFrame.maxX {
            // Trailing edge: return the line's upper bound (one past its last character) so a
            // right-handle drag can include the last character/item of the line. The selection
            // upper bound is exclusive, so clamping to the last character's index — as the strict
            // path does — would always leave it unselected. Mirrors Display.TextNode.
            index = lineRange.location + lineRange.length
        } else {
            index = CTLineGetStringIndexForPosition(line.line, CGPoint(x: point.x - lineFrame.minX, y: 0.0))
            if index != 0 {
                var glyphStart: CGFloat = 0.0
                CTLineGetOffsetForStringIndex(line.line, index, &glyphStart)
                if point.x - lineFrame.minX < glyphStart {
                    index -= 1
                }
            }
        }
        guard index >= 0, index <= self.attributedString.length else {
            return nil
        }
        let attributes = index < self.attributedString.length ? self.attributedString.attributes(at: index, effectiveRange: nil) : [:]
        return (index, attributes)
    }

    private func attributeRects(name: NSAttributedString.Key, at index: Int) -> [CGRect]? {
        var range = NSRange()
        let _ = self.attributedString.attribute(name, at: index, effectiveRange: &range)
        if range.length != 0 {
            let boundsWidth = self.frame.width
            var rects: [CGRect] = []
            for i in 0 ..< self.lines.count {
                let line = self.lines[i]
                let lineRange = NSIntersectionRange(range, line.range)
                if lineRange.length != 0 {
                    var leftOffset: CGFloat = 0.0
                    if lineRange.location != line.range.location || line.isRTL {
                        leftOffset = floor(CTLineGetOffsetForStringIndex(line.line, lineRange.location, nil))
                    }
                    var rightOffset: CGFloat = line.frame.width
                    if lineRange.location + lineRange.length != line.range.length || line.isRTL {
                        rightOffset = ceil(CTLineGetOffsetForStringIndex(line.line, lineRange.location + lineRange.length, nil))
                    }
                    let lineFrame = frameForLine(line, boundingWidth: boundsWidth, alignment: self.alignment)
                    let width = abs(rightOffset - leftOffset)

                    var rect: CGRect?
                    if width > 1.0 {
                        rect = CGRect(origin: CGPoint(x: lineFrame.minX + (leftOffset < rightOffset ? leftOffset : rightOffset), y: lineFrame.minY), size: CGSize(width: width, height: lineFrame.size.height))
                    }
                    if let attachmentBounds = attachmentBoundsForRange(lineRange, line: line, boundingWidth: boundsWidth, alignment: self.alignment) {
                        if rect != nil {
                            rect = rect!.union(attachmentBounds)
                        } else {
                            rect = attachmentBounds
                        }
                    }
                    if let rect, rect.width > 1.0 {
                        rects.append(rect)
                    }
                }
            }
            if !rects.isEmpty {
                return rects
            }
        }
        return nil
    }
    
    public func linkSelectionRects(at point: CGPoint) -> [CGRect] {
        if let (index, dict) = self.attributesAtPoint(point) {
            let interactiveKeys = [
                TelegramTextAttributes.URL,
                TelegramTextAttributes.PeerMention,
                TelegramTextAttributes.PeerTextMention,
                TelegramTextAttributes.BotCommand,
                TelegramTextAttributes.Hashtag,
                TelegramTextAttributes.BankCard,
                TelegramTextAttributes.Date
            ]
            for key in interactiveKeys {
                let attrKey = NSAttributedString.Key(rawValue: key)
                if dict[attrKey] != nil, let rects = self.attributeRects(name: attrKey, at: index) {
                    return rects.compactMap { rect in
                        if rect.width > 5.0 {
                            return rect.insetBy(dx: 0.0, dy: -3.0)
                        } else {
                            return nil
                        }
                    }
                }
            }
        }
        return []
    }
    
    public func urlAttribute(at point: CGPoint) -> InstantPageUrlItem? {
        if let (_, dict) = self.attributesAtPoint(point) {
            if let url = dict[NSAttributedString.Key(rawValue: TelegramTextAttributes.URL)] as? InstantPageUrlItem {
                return url
            }
        }
        return nil
    }
    
    func rangeRects(in range: NSRange) -> (rects: [CGRect], start: InstantPageTextRangeRectEdge?, end: InstantPageTextRangeRectEdge?)? {
        guard range.length != 0 else {
            return nil
        }

        let boundsWidth = self.frame.width

        var rects: [(CGRect, CGRect)] = []
        var startEdge: InstantPageTextRangeRectEdge?
        var endEdge: InstantPageTextRangeRectEdge?
        for i in 0 ..< self.lines.count {
            let line = self.lines[i]
            let lineRange = NSIntersectionRange(range, line.range)
            if lineRange.length != 0 {
                var leftOffset: CGFloat = 0.0
                if lineRange.location != line.range.location || line.isRTL {
                    leftOffset = floor(CTLineGetOffsetForStringIndex(line.line, lineRange.location, nil))
                }
                var rightOffset: CGFloat = line.frame.width
                if lineRange.location + lineRange.length != line.range.upperBound || line.isRTL {
                    var secondaryOffset: CGFloat = 0.0
                    let rawOffset = CTLineGetOffsetForStringIndex(line.line, lineRange.location + lineRange.length, &secondaryOffset)
                    rightOffset = ceil(rawOffset)
                    if !rawOffset.isEqual(to: secondaryOffset) {
                        rightOffset = ceil(secondaryOffset)
                    }
                }

                let lineFrame = expandedFrameForLine(line, boundingWidth: boundsWidth, alignment: self.alignment)

                let width = max(0.0, abs(rightOffset - leftOffset))

                if line.range.contains(range.lowerBound) {
                    let offsetX = floor(CTLineGetOffsetForStringIndex(line.line, range.lowerBound, nil))
                    startEdge = InstantPageTextRangeRectEdge(x: lineFrame.minX + offsetX, y: lineFrame.minY, height: lineFrame.height)
                }
                if line.range.contains(range.upperBound - 1) {
                    let offsetX: CGFloat
                    if line.range.upperBound == range.upperBound {
                        offsetX = lineFrame.maxX
                    } else {
                        var secondaryOffset: CGFloat = 0.0
                        let primaryOffset = floor(CTLineGetOffsetForStringIndex(line.line, range.upperBound - 1, &secondaryOffset))
                        secondaryOffset = floor(secondaryOffset)
                        let nextOffet = floor(CTLineGetOffsetForStringIndex(line.line, range.upperBound, &secondaryOffset))

                        if primaryOffset != secondaryOffset {
                            offsetX = secondaryOffset
                        } else {
                            offsetX = nextOffet
                        }
                    }
                    endEdge = InstantPageTextRangeRectEdge(x: lineFrame.minX + offsetX, y: lineFrame.minY, height: lineFrame.height)
                }

                rects.append((lineFrame, CGRect(origin: CGPoint(x: lineFrame.minX + min(leftOffset, rightOffset), y: lineFrame.minY), size: CGSize(width: width, height: lineFrame.size.height))))
            }
        }
        if !rects.isEmpty, let startEdge = startEdge, let endEdge = endEdge {
            return (rects.map { $1 }, startEdge, endEdge)
        }
        return nil
    }

    public func textRangeRects(in range: NSRange) -> (rects: [CGRect], start: TextRangeRectEdge, end: TextRangeRectEdge)? {
        guard let result = self.rangeRects(in: range), let start = result.start, let end = result.end, !result.rects.isEmpty else {
            return nil
        }
        let startEdge = TextRangeRectEdge(x: start.x, y: start.y, height: start.height)
        let endEdge = TextRangeRectEdge(x: end.x, y: end.y, height: end.height)
        return (result.rects, startEdge, endEdge)
    }

    public func lineRects() -> [CGRect] {
        let boundsWidth = self.frame.width
        var rects: [CGRect] = []
        var topLeft = CGPoint(x: CGFloat.greatestFiniteMagnitude, y: 0.0)
        var bottomRight = CGPoint()
        
        var lastLineFrame: CGRect?
        for i in 0 ..< self.lines.count {
            let line = self.lines[i]
            
            let lineFrame = expandedFrameForLine(line, boundingWidth: boundsWidth, alignment: self.alignment)
            
            if lineFrame.minX < topLeft.x {
                topLeft = CGPoint(x: lineFrame.minX, y: topLeft.y)
            }
            if lineFrame.maxX > bottomRight.x {
                bottomRight = CGPoint(x: lineFrame.maxX, y: bottomRight.y)
            }
            
            if self.lines.count > 1 && i == self.lines.count - 1 {
                lastLineFrame = lineFrame
            } else {
                if lineFrame.minY < topLeft.y {
                    topLeft = CGPoint(x: topLeft.x, y: lineFrame.minY)
                }
                if lineFrame.maxY > bottomRight.y {
                    bottomRight = CGPoint(x: bottomRight.x, y: lineFrame.maxY)
                }
            }
        }
        rects.append(CGRect(x: topLeft.x, y: topLeft.y, width: bottomRight.x - topLeft.x, height: bottomRight.y - topLeft.y))
        if self.lines.count > 1, var lastLineFrame = lastLineFrame {
            let delta = lastLineFrame.minY - bottomRight.y
            lastLineFrame = CGRect(x: lastLineFrame.minX, y: bottomRight.y, width: lastLineFrame.width, height: lastLineFrame.height + delta)
            rects.append(lastLineFrame)
        }
        
        return rects
    }
    
    func effectiveWidth() -> CGFloat {
        var width: CGFloat = 0.0
        for line in self.lines {
            width = max(width, line.frame.width)
        }
        return ceil(width)
    }
    
    public func plainText() -> String {
        if let first = self.lines.first, let last = self.lines.last {
            return self.attributedString.attributedSubstring(from: NSMakeRange(first.range.location, last.range.location + last.range.length - first.range.location)).string
        }
        return ""
    }
    
    public func matchesAnchor(_ anchor: String) -> Bool {
        return false
    }
    
    public func node(context: AccountContext, strings: PresentationStrings, nameDisplayOrder: PresentationPersonNameOrder, theme: InstantPageTheme, sourceLocation: InstantPageSourceLocation, openMedia: @escaping (InstantPageMedia) -> Void, longPressMedia: @escaping (InstantPageMedia) -> Void, activatePinchPreview: ((PinchSourceContainerNode) -> Void)?, pinchPreviewFinished: ((InstantPageNode) -> Void)?, openPeer: @escaping (EnginePeer) -> Void, openUrl: @escaping (InstantPageUrlItem) -> Void, updateWebEmbedHeight: @escaping (CGFloat) -> Void, updateDetailsExpanded: @escaping (Bool) -> Void, currentExpandedDetails: [Int : Bool]?, getPreloadedResource: @escaping (String) -> Data?) -> InstantPageNode? {
        return nil
    }
    
    public func matchesNode(_ node: InstantPageNode) -> Bool {
        return false
    }
    
    public func distanceThresholdGroup() -> Int? {
        return nil
    }
    
    public func distanceThresholdWithGroupCount(_ count: Int) -> CGFloat {
        return 0.0
    }
}

final class InstantPageScrollableTextItem: InstantPageScrollableItem {
    var frame: CGRect
    let totalWidth: CGFloat
    let horizontalInset: CGFloat
    let medias: [InstantPageMedia] = []
    let wantsNode: Bool = true
    let separatesTiles: Bool = false
    
    let item: InstantPageTextItem
    let additionalItems: [InstantPageItem]
    let isRTL: Bool
    
    fileprivate init(frame: CGRect, item: InstantPageTextItem, additionalItems: [InstantPageItem], totalWidth: CGFloat, horizontalInset: CGFloat, rtl: Bool) {
        self.frame = frame
        self.item = item
        self.additionalItems = additionalItems
        self.totalWidth = totalWidth
        self.horizontalInset = horizontalInset
        self.isRTL = rtl
    }
    
    var contentSize: CGSize {
        return CGSize(width: self.totalWidth, height: self.frame.height)
    }
    
    func drawInTile(context: CGContext) {
        context.saveGState()
        context.translateBy(x: self.item.frame.minX, y: self.item.frame.minY)
        self.item.drawInTile(context: context)
        context.restoreGState()
    }
    
    func node(context: AccountContext, strings: PresentationStrings, nameDisplayOrder: PresentationPersonNameOrder, theme: InstantPageTheme, sourceLocation: InstantPageSourceLocation, openMedia: @escaping (InstantPageMedia) -> Void, longPressMedia: @escaping (InstantPageMedia) -> Void, activatePinchPreview: ((PinchSourceContainerNode) -> Void)?, pinchPreviewFinished: ((InstantPageNode) -> Void)?, openPeer: @escaping (EnginePeer) -> Void, openUrl: @escaping (InstantPageUrlItem) -> Void, updateWebEmbedHeight: @escaping (CGFloat) -> Void, updateDetailsExpanded: @escaping (Bool) -> Void, currentExpandedDetails: [Int : Bool]?, getPreloadedResource: @escaping (String) -> Data?) -> InstantPageNode? {
        var additionalNodes: [InstantPageNode] = []
        for item in additionalItems {
            if item.wantsNode {
                if let node = item.node(context: context, strings: strings, nameDisplayOrder: nameDisplayOrder, theme: theme, sourceLocation: sourceLocation, openMedia: { _ in }, longPressMedia: { _ in }, activatePinchPreview: nil, pinchPreviewFinished: nil, openPeer: { _ in }, openUrl: { _ in}, updateWebEmbedHeight: { _ in }, updateDetailsExpanded: { _ in }, currentExpandedDetails: nil, getPreloadedResource: getPreloadedResource) {
                    node.frame = item.frame
                    additionalNodes.append(node)
                }
            }
        }
        return InstantPageScrollableNode(item: self, additionalNodes: additionalNodes)
    }
    
    func matchesAnchor(_ anchor: String) -> Bool {
        return self.item.matchesAnchor(anchor)
    }
    
    func matchesNode(_ node: InstantPageNode) -> Bool {
        if let node = node as? InstantPageScrollableNode {
            return node.item === self
        }
        return false
    }
    
    func distanceThresholdGroup() -> Int? {
        return nil
    }
    
    func distanceThresholdWithGroupCount(_ count: Int) -> CGFloat {
        return 0.0
    }
    
    func linkSelectionRects(at point: CGPoint) -> [CGRect] {
        let rects = self.item.linkSelectionRects(at: point.offsetBy(dx: -self.item.frame.minX - self.horizontalInset, dy: -self.item.frame.minY))
        return rects.map { $0.offsetBy(dx: self.item.frame.minX + self.horizontalInset, dy: -self.item.frame.minY) }
    }
    
    func textItemAtLocation(_ location: CGPoint) -> (InstantPageTextItem, CGPoint)? {
        if self.item.selectable, self.item.frame.contains(location.offsetBy(dx: -self.item.frame.minX - self.horizontalInset, dy: -self.item.frame.minY)) {
            return (item, self.item.frame.origin.offsetBy(dx: self.horizontalInset, dy: -self.item.frame.minY))
        }
        return nil
    }
}

func attributedStringForRichText(_ text: RichText, styleStack: InstantPageTextStyleStack, url: InstantPageUrlItem? = nil, boundingWidth: CGFloat? = nil, formatDate: ((Int32, MessageTextEntityType.DateTimeFormat) -> String)? = nil) -> NSAttributedString {
    switch text {
        case .empty:
            return NSAttributedString(string: "", attributes: styleStack.textAttributes())
        case let .plain(string):
            var attributes = styleStack.textAttributes()
            if let url = url {
                attributes[NSAttributedString.Key(rawValue: TelegramTextAttributes.URL)] = url
            }
            return NSAttributedString(string: string, attributes: attributes)
        case let .bold(text):
            styleStack.push(.bold)
            let result = attributedStringForRichText(text, styleStack: styleStack, url: url, formatDate: formatDate)
            styleStack.pop()
            return result
        case let .italic(text):
            styleStack.push(.italic)
            let result = attributedStringForRichText(text, styleStack: styleStack, url: url, formatDate: formatDate)
            styleStack.pop()
            return result
        case let .underline(text):
            styleStack.push(.underline)
            let result = attributedStringForRichText(text, styleStack: styleStack, url: url, formatDate: formatDate)
            styleStack.pop()
            return result
        case let .strikethrough(text):
            styleStack.push(.strikethrough)
            let result = attributedStringForRichText(text, styleStack: styleStack, url: url, formatDate: formatDate)
            styleStack.pop()
            return result
        case let .fixed(text):
            styleStack.push(.fontFixed(true))
            let result = attributedStringForRichText(text, styleStack: styleStack, url: url, formatDate: formatDate)
            styleStack.pop()
            return result
        case let .url(text, url, webpageId):
            styleStack.push(.link(webpageId != nil))
            let result = attributedStringForRichText(text, styleStack: styleStack, url: InstantPageUrlItem(url: url, webpageId: webpageId), formatDate: formatDate)
            styleStack.pop()
            return result
        case let .email(text, email):
            styleStack.push(.bold)
            styleStack.push(.underline)
            let result = attributedStringForRichText(text, styleStack: styleStack, url: InstantPageUrlItem(url: "mailto:\(email)", webpageId: nil), formatDate: formatDate)
            styleStack.pop()
            styleStack.pop()
            return result
        case let .concat(texts):
            let string = NSMutableAttributedString()
            for text in texts {
                let substring = attributedStringForRichText(text, styleStack: styleStack, url: url, boundingWidth: boundingWidth, formatDate: formatDate)
                string.append(substring)
            }
            return string
        case let .subscript(text):
            styleStack.push(.subscript)
            let result = attributedStringForRichText(text, styleStack: styleStack, url: url, formatDate: formatDate)
            styleStack.pop()
            return result
        case let .superscript(text):
            styleStack.push(.superscript)
            let result = attributedStringForRichText(text, styleStack: styleStack, url: url, formatDate: formatDate)
            styleStack.pop()
            return result
        case let .marked(text):
            styleStack.push(.marker)
            let result = attributedStringForRichText(text, styleStack: styleStack, url: url, formatDate: formatDate)
            styleStack.pop()
            return result
        case let .phone(text, phone):
            styleStack.push(.bold)
            styleStack.push(.underline)
            let result = attributedStringForRichText(text, styleStack: styleStack, url: InstantPageUrlItem(url: "tel:\(phone)", webpageId: nil), formatDate: formatDate)
            styleStack.pop()
            styleStack.pop()
            return result
        case let .image(id, dimensions):
            struct RunStruct {
                let ascent: CGFloat
                let descent: CGFloat
                let width: CGFloat
            }
            var dimensions = dimensions
            if let boundingWidth = boundingWidth {
                dimensions = PixelDimensions(dimensions.cgSize.fittedToWidthOrSmaller(boundingWidth))
            }
            let extentBuffer = UnsafeMutablePointer<RunStruct>.allocate(capacity: 1)
            extentBuffer.initialize(to: RunStruct(ascent: 0.0, descent: 0.0, width: dimensions.cgSize.width))
            var callbacks = CTRunDelegateCallbacks(version: kCTRunDelegateVersion1, dealloc: { pointer in
                pointer.assumingMemoryBound(to: RunStruct.self).deallocate()
            }, getAscent: { (pointer) -> CGFloat in
                let d = pointer.assumingMemoryBound(to: RunStruct.self)
                return d.pointee.ascent
            }, getDescent: { (pointer) -> CGFloat in
                let d = pointer.assumingMemoryBound(to: RunStruct.self)
                return d.pointee.descent
            }, getWidth: { (pointer) -> CGFloat in
                let d = pointer.assumingMemoryBound(to: RunStruct.self)
                return d.pointee.width
            })
            let delegate = CTRunDelegateCreate(&callbacks, extentBuffer)
            let attrDictionaryDelegate = [(kCTRunDelegateAttributeName as NSAttributedString.Key): (delegate as Any), NSAttributedString.Key(rawValue: InstantPageMediaIdAttribute): id.id, NSAttributedString.Key(rawValue: InstantPageMediaDimensionsAttribute): dimensions]
            let mutableAttributedString = attributedStringForRichText(.plain(" "), styleStack: styleStack, url: url, formatDate: formatDate).mutableCopy() as! NSMutableAttributedString
            mutableAttributedString.addAttributes(attrDictionaryDelegate, range: NSMakeRange(0, mutableAttributedString.length))
            return mutableAttributedString
        case let .formula(latex):
            let attributes = styleStack.textAttributes()
            let textColor = (attributes[NSAttributedString.Key.foregroundColor] as? UIColor) ?? UIColor.black
            let fontSize = (attributes[NSAttributedString.Key.font] as? UIFont)?.pointSize ?? 16.0
            guard let attachment = instantPageMathAttachment(latex: latex, fontSize: fontSize, textColor: textColor, mode: .inline) else {
                var fallbackAttributes = attributes
                if let url = url {
                    fallbackAttributes[NSAttributedString.Key(rawValue: TelegramTextAttributes.URL)] = url
                }
                return NSAttributedString(string: latex, attributes: fallbackAttributes)
            }

            struct RunStruct {
                let ascent: CGFloat
                let descent: CGFloat
                let width: CGFloat
            }
            let extentBuffer = UnsafeMutablePointer<RunStruct>.allocate(capacity: 1)
            extentBuffer.initialize(to: RunStruct(ascent: attachment.rendered.ascent, descent: attachment.rendered.descent, width: attachment.rendered.size.width))
            var callbacks = CTRunDelegateCallbacks(version: kCTRunDelegateVersion1, dealloc: { pointer in
                pointer.assumingMemoryBound(to: RunStruct.self).deallocate()
            }, getAscent: { pointer -> CGFloat in
                let data = pointer.assumingMemoryBound(to: RunStruct.self)
                return data.pointee.ascent
            }, getDescent: { pointer -> CGFloat in
                let data = pointer.assumingMemoryBound(to: RunStruct.self)
                return data.pointee.descent
            }, getWidth: { pointer -> CGFloat in
                let data = pointer.assumingMemoryBound(to: RunStruct.self)
                return data.pointee.width
            })
            let delegate = CTRunDelegateCreate(&callbacks, extentBuffer)
            let mutableAttributedString = attributedStringForRichText(.plain(" "), styleStack: styleStack, url: url, formatDate: formatDate).mutableCopy() as! NSMutableAttributedString
            mutableAttributedString.addAttributes([
                kCTRunDelegateAttributeName as NSAttributedString.Key: delegate as Any,
                NSAttributedString.Key(rawValue: InstantPageFormulaAttribute): attachment
            ], range: NSMakeRange(0, mutableAttributedString.length))
            return mutableAttributedString
        case let .anchor(text, name):
            var empty = false
            var text = text
            if case .empty = text {
                empty = true
                text = .plain("\u{200b}")
            }
            let anchorText = !empty ? attributedStringForRichText(text, styleStack: styleStack, url: url, formatDate: formatDate) : nil
            styleStack.push(.anchor(name, anchorText, empty))
            let result = attributedStringForRichText(text, styleStack: styleStack, url: url, formatDate: formatDate)
            styleStack.pop()
            return result
        case let .textAutoUrl(text):
            styleStack.push(.link(false))
            let result = attributedStringForRichText(text, styleStack: styleStack, url: InstantPageUrlItem(url: text.plainText, webpageId: nil), formatDate: formatDate)
            styleStack.pop()
            return result
        case let .textAutoEmail(text):
            styleStack.push(.link(false))
            let result = attributedStringForRichText(text, styleStack: styleStack, url: InstantPageUrlItem(url: "mailto:\(text.plainText)", webpageId: nil), formatDate: formatDate)
            styleStack.pop()
            return result
        case let .textAutoPhone(text):
            styleStack.push(.link(false))
            let result = attributedStringForRichText(text, styleStack: styleStack, url: InstantPageUrlItem(url: "tel:\(text.plainText)", webpageId: nil), formatDate: formatDate)
            styleStack.pop()
            return result
        case let .textMention(text):
            styleStack.push(.link(false))
            let result = attributedStringForRichText(text, styleStack: styleStack, url: url, formatDate: formatDate)
            styleStack.pop()
            let mutable = result.mutableCopy() as! NSMutableAttributedString
            if mutable.length != 0 {
                mutable.addAttribute(NSAttributedString.Key(rawValue: TelegramTextAttributes.PeerTextMention), value: mutable.string, range: NSRange(location: 0, length: mutable.length))
            }
            return mutable
        case let .textMentionName(text, peerId):
            styleStack.push(.link(false))
            let result = attributedStringForRichText(text, styleStack: styleStack, url: url, formatDate: formatDate)
            styleStack.pop()
            let mutable = result.mutableCopy() as! NSMutableAttributedString
            if mutable.length != 0 {
                let mention = TelegramPeerMention(peerId: EnginePeer.Id(namespace: Namespaces.Peer.CloudUser, id: EnginePeer.Id.Id._internalFromInt64Value(peerId)), mention: mutable.string)
                mutable.addAttribute(NSAttributedString.Key(rawValue: TelegramTextAttributes.PeerMention), value: mention, range: NSRange(location: 0, length: mutable.length))
            }
            return mutable
        case let .textHashtag(text):
            styleStack.push(.link(false))
            let result = attributedStringForRichText(text, styleStack: styleStack, url: url, formatDate: formatDate)
            styleStack.pop()
            let mutable = result.mutableCopy() as! NSMutableAttributedString
            if mutable.length != 0 {
                mutable.addAttribute(NSAttributedString.Key(rawValue: TelegramTextAttributes.Hashtag), value: TelegramHashtag(peerName: nil, hashtag: mutable.string), range: NSRange(location: 0, length: mutable.length))
            }
            return mutable
        case let .textCashtag(text):
            styleStack.push(.link(false))
            let result = attributedStringForRichText(text, styleStack: styleStack, url: url, formatDate: formatDate)
            styleStack.pop()
            let mutable = result.mutableCopy() as! NSMutableAttributedString
            if mutable.length != 0 {
                mutable.addAttribute(NSAttributedString.Key(rawValue: TelegramTextAttributes.Hashtag), value: TelegramHashtag(peerName: nil, hashtag: mutable.string), range: NSRange(location: 0, length: mutable.length))
            }
            return mutable
        case let .textBotCommand(text):
            styleStack.push(.link(false))
            let result = attributedStringForRichText(text, styleStack: styleStack, url: url, formatDate: formatDate)
            styleStack.pop()
            let mutable = result.mutableCopy() as! NSMutableAttributedString
            if mutable.length != 0 {
                mutable.addAttribute(NSAttributedString.Key(rawValue: TelegramTextAttributes.BotCommand), value: mutable.string, range: NSRange(location: 0, length: mutable.length))
            }
            return mutable
        case let .textBankCard(text):
            styleStack.push(.link(false))
            let result = attributedStringForRichText(text, styleStack: styleStack, url: url, formatDate: formatDate)
            styleStack.pop()
            let mutable = result.mutableCopy() as! NSMutableAttributedString
            if mutable.length != 0 {
                mutable.addAttribute(NSAttributedString.Key(rawValue: TelegramTextAttributes.BankCard), value: mutable.string, range: NSRange(location: 0, length: mutable.length))
            }
            return mutable
        case let .textCustomEmoji(fileId, _):
            struct RunStruct {
                let ascent: CGFloat
                let descent: CGFloat
                let width: CGFloat
            }
            let attributes = styleStack.textAttributes()
            let font = (attributes[NSAttributedString.Key.font] as? UIFont) ?? UIFont.systemFont(ofSize: 17.0)
            // Size the inline emoji to the font's line height (A + D) plus a 4pt bump at the 17pt
            // body font (scaled proportionally). Must match the V2 layout's emoji cell size
            // (InstantPageV2Layout.swift). The run delegate still reports the font's own
            // ascent/descent (below), so the line height is unchanged — only the emoji width changes.
            let itemSize = font.ascender - font.descender + 4.0 * font.pointSize / 17.0
            let extentBuffer = UnsafeMutablePointer<RunStruct>.allocate(capacity: 1)
            extentBuffer.initialize(to: RunStruct(ascent: font.ascender, descent: font.descender, width: itemSize))
            var callbacks = CTRunDelegateCallbacks(version: kCTRunDelegateVersion1, dealloc: { pointer in
                pointer.assumingMemoryBound(to: RunStruct.self).deallocate()
            }, getAscent: { pointer -> CGFloat in
                let d = pointer.assumingMemoryBound(to: RunStruct.self)
                return d.pointee.ascent
            }, getDescent: { pointer -> CGFloat in
                let d = pointer.assumingMemoryBound(to: RunStruct.self)
                return d.pointee.descent
            }, getWidth: { pointer -> CGFloat in
                let d = pointer.assumingMemoryBound(to: RunStruct.self)
                return d.pointee.width
            })
            let delegate = CTRunDelegateCreate(&callbacks, extentBuffer)
            let emojiAttribute = ChatTextInputTextCustomEmojiAttribute(interactivelySelectedFromPackId: nil, fileId: fileId, file: nil)
            let mutableAttributedString = attributedStringForRichText(.plain(" "), styleStack: styleStack, url: url, formatDate: formatDate).mutableCopy() as! NSMutableAttributedString
            mutableAttributedString.addAttributes([
                kCTRunDelegateAttributeName as NSAttributedString.Key: delegate as Any,
                ChatTextInputAttributes.customEmoji: emojiAttribute
            ], range: NSMakeRange(0, mutableAttributedString.length))
            return mutableAttributedString
        case let .textSpoiler(text):
            let result = attributedStringForRichText(text, styleStack: styleStack, url: url, formatDate: formatDate)
            let mutable = result.mutableCopy() as! NSMutableAttributedString
            if mutable.length != 0 {
                mutable.addAttribute(NSAttributedString.Key(rawValue: TelegramTextAttributes.Spoiler), value: true, range: NSRange(location: 0, length: mutable.length))
            }
            return mutable
        case let .textDate(text, date, format):
            if let format, let formatDate {
                let formatted = formatDate(date, format)
                let result = attributedStringForRichText(.plain(formatted), styleStack: styleStack, url: url, formatDate: formatDate)
                let mutable = result.mutableCopy() as! NSMutableAttributedString
                if mutable.length != 0 {
                    mutable.addAttribute(NSAttributedString.Key(rawValue: TelegramTextAttributes.Date), value: date, range: NSRange(location: 0, length: mutable.length))
                }
                return mutable
            } else {
                return attributedStringForRichText(text, styleStack: styleStack, url: url, formatDate: formatDate)
            }
    }
}

func layoutTextItemWithString(_ string: NSAttributedString, boundingWidth: CGFloat, horizontalInset: CGFloat = 0.0, alignment: NSTextAlignment = .natural, offset: CGPoint, media: [EngineMedia.Id: EngineMedia] = [:], webpage: TelegramMediaWebpage? = nil, minimizeWidth: Bool = false, fitToWidth: Bool = false, maxNumberOfLines: Int = 0, opaqueBackground: Bool = false) -> (InstantPageTextItem?, [InstantPageItem], CGSize) {
    if string.length == 0 {
        return (nil, [], CGSize())
    }
    
    var lines: [InstantPageTextLine] = []
    var imageItems: [InstantPageTextImageItem] = []
    var formulaItems: [InstantPageTextFormulaItem] = []
    var font = string.attribute(NSAttributedString.Key.font, at: 0, effectiveRange: nil) as? UIFont
    if font == nil {
        let range = NSMakeRange(0, string.length)
        string.enumerateAttributes(in: range, options: []) { attributes, range, _ in
            if font == nil, let furtherFont = attributes[NSAttributedString.Key.font] as? UIFont {
                font = furtherFont
            }
        }
    }
    let image = string.attribute(NSAttributedString.Key.init(rawValue: InstantPageMediaIdAttribute), at: 0, effectiveRange: nil)
    let formula = string.attribute(NSAttributedString.Key(rawValue: InstantPageFormulaAttribute), at: 0, effectiveRange: nil)
    guard font != nil || image != nil || formula != nil else {
        return (nil, [], CGSize())
    }
    
    var lineSpacingFactor: CGFloat = 1.12
    if let lineSpacingFactorAttribute = string.attribute(NSAttributedString.Key(rawValue: InstantPageLineSpacingFactorAttribute), at: 0, effectiveRange: nil) {
        lineSpacingFactor = CGFloat((lineSpacingFactorAttribute as! NSNumber).floatValue)
    }
    
    let typesetter = CTTypesetterCreateWithAttributedString(string)
    let fontAscent = font?.ascender ?? 0.0
    let fontDescent = font?.descender ?? 0.0
    
    let fontLineHeight = floor(fontAscent + fontDescent)
    let fontLineSpacing = floor(fontLineHeight * lineSpacingFactor)
    
    var lastIndex: CFIndex = 0
    var currentLineOrigin = CGPoint()

    var hasAnchors = false
    var maxLineWidth: CGFloat = 0.0
    var extraDescent: CGFloat = 0.0
    let text = string.string
    var indexOffset: CFIndex?
    while true {
        var workingLineOrigin = currentLineOrigin
        
        let currentMaxWidth = boundingWidth - workingLineOrigin.x
        var lineCharacterCount: CFIndex
        var hadIndexOffset = false
        if minimizeWidth {
            var count = 0
            for ch in text.suffix(text.count - lastIndex) {
                count += 1
                if ch == " " || ch == "\n" || ch == "\t" {
                    break
                }
            }
            lineCharacterCount = count
        } else {
            let suggestedLineBreak = CTTypesetterSuggestLineBreak(typesetter, lastIndex, Double(currentMaxWidth))
            if let offset = indexOffset {
                lineCharacterCount = suggestedLineBreak + offset
                if lineCharacterCount <= 0 {
                    lineCharacterCount = suggestedLineBreak
                }
                indexOffset = nil
                hadIndexOffset = true
            } else {
                lineCharacterCount = suggestedLineBreak
            }
        }
        if lineCharacterCount > 0 {
            var line = CTTypesetterCreateLineWithOffset(typesetter, CFRangeMake(lastIndex, lineCharacterCount), 100.0)
            var lineWidth = CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))
            let lineRange = NSMakeRange(lastIndex, lineCharacterCount)
            let substring = string.attributedSubstring(from: lineRange).string
            
            var stop = false
            if maxNumberOfLines > 0 && lines.count == maxNumberOfLines - 1 && lastIndex + lineCharacterCount < string.length {
                let attributes = string.attributes(at: lastIndex + lineCharacterCount - 1, effectiveRange: nil)
                if let truncateString = CFAttributedStringCreate(nil, "\u{2026}" as CFString, attributes as CFDictionary) {
                    let truncateToken = CTLineCreateWithAttributedString(truncateString)
                    let tokenWidth = CGFloat(CTLineGetTypographicBounds(truncateToken, nil, nil, nil) + 3.0)
                    if let truncatedLine = CTLineCreateTruncatedLine(line, Double(lineWidth - tokenWidth), .end, truncateToken) {
                        lineWidth += tokenWidth
                        line = truncatedLine
                    }
                }
                stop = true
            }
            
            let hadExtraDescent = extraDescent > 0.0
            extraDescent = 0.0
            var lineImageItems: [InstantPageTextImageItem] = []
            var lineFormulaItems: [InstantPageTextFormulaRun] = []
            var lineMaxAttachmentHeight: CGFloat = 0.0
            var isRTL = false
            if let glyphRuns = CTLineGetGlyphRuns(line) as? [CTRun], !glyphRuns.isEmpty {
                if let run = glyphRuns.first, CTRunGetStatus(run).contains(CTRunStatus.rightToLeft) {
                    isRTL = true
                }
                
                var appliedLineOffset: CGFloat = 0.0
                for run in glyphRuns {
                    let cfRunRange = CTRunGetStringRange(run)
                    let runRange = NSMakeRange(cfRunRange.location == kCFNotFound ? NSNotFound : cfRunRange.location, cfRunRange.length)
                    string.enumerateAttributes(in: runRange, options: []) { attributes, range, _ in
                        if let id = attributes[NSAttributedString.Key.init(rawValue: InstantPageMediaIdAttribute)] as? Int64, let dimensions = attributes[NSAttributedString.Key.init(rawValue: InstantPageMediaDimensionsAttribute)] as? PixelDimensions {
                            var imageFrame = CGRect(origin: CGPoint(), size: dimensions.cgSize.fitted(CGSize(width: boundingWidth, height: boundingWidth)))
                            
                            let xOffset = CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(run).location, nil)
                            let yOffset = fontLineHeight.isZero ? 0.0 : floorToScreenPixels((fontLineHeight - imageFrame.size.height) / 2.0)
                            imageFrame.origin = imageFrame.origin.offsetBy(dx: workingLineOrigin.x + xOffset, dy: workingLineOrigin.y + yOffset)
                            
                            let minSpacing = fontLineSpacing - 4.0
                            let delta = workingLineOrigin.y - minSpacing - imageFrame.minY - appliedLineOffset
                            if !fontAscent.isZero && delta > 0.0 {
                                workingLineOrigin.y += delta
                                appliedLineOffset += delta
                                imageFrame.origin = imageFrame.origin.offsetBy(dx: 0.0, dy: delta)
                            }
                            if !fontLineHeight.isZero {
                                extraDescent = max(extraDescent, imageFrame.maxY - (workingLineOrigin.y + fontLineHeight + minSpacing))
                            }
                            lineMaxAttachmentHeight = max(lineMaxAttachmentHeight, imageFrame.height)
                            lineImageItems.append(InstantPageTextImageItem(frame: imageFrame, range: range, id: EngineMedia.Id(namespace: Namespaces.Media.CloudFile, id: id)))
                        } else if let attachment = attributes[NSAttributedString.Key(rawValue: InstantPageFormulaAttribute)] as? InstantPageMathAttachment {
                            let xOffset = CTLineGetOffsetForStringIndex(line, range.location, nil)
                            let baselineOffset = (attributes[NSAttributedString.Key.baselineOffset] as? CGFloat) ?? 0.0
                            var formulaFrame = CGRect(
                                origin: CGPoint(
                                    x: workingLineOrigin.x + xOffset,
                                    y: workingLineOrigin.y + fontLineHeight + baselineOffset - attachment.rendered.ascent
                                ),
                                size: attachment.rendered.size
                            )

                            let minSpacing = fontLineSpacing - 4.0
                            let delta = workingLineOrigin.y - minSpacing - formulaFrame.minY - appliedLineOffset
                            if !fontAscent.isZero && delta > 0.0 {
                                workingLineOrigin.y += delta
                                appliedLineOffset += delta
                                formulaFrame.origin = formulaFrame.origin.offsetBy(dx: 0.0, dy: delta)
                            }
                            if !fontLineHeight.isZero {
                                extraDescent = max(extraDescent, formulaFrame.maxY - (workingLineOrigin.y + fontLineHeight + minSpacing))
                            }
                            lineMaxAttachmentHeight = max(lineMaxAttachmentHeight, formulaFrame.height)
                            lineFormulaItems.append(InstantPageTextFormulaRun(frame: formulaFrame, range: range, attachment: attachment))
                        }
                    }
                }
            }
            
            if substring.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && (!lineImageItems.isEmpty || !lineFormulaItems.isEmpty) {
                extraDescent += max(6.0, fontLineSpacing / 2.0)
            }
            
            if !minimizeWidth && !hadIndexOffset && lineCharacterCount > 1 && lineWidth > currentMaxWidth + 5.0 {
                if let imageItem = lineImageItems.last {
                    indexOffset = -(lastIndex + lineCharacterCount - imageItem.range.lowerBound)
                    continue
                }
                if let formulaItem = lineFormulaItems.last {
                    indexOffset = -(lastIndex + lineCharacterCount - formulaItem.range.lowerBound)
                    continue
                }
            }
            
            var strikethroughItems: [InstantPageTextStrikethroughItem] = []
            var underlineItems: [InstantPageTextUnderlineItem] = []
            var markedItems: [InstantPageTextMarkedItem] = []
            var anchorItems: [InstantPageTextAnchorItem] = []

            string.enumerateAttributes(in: lineRange, options: []) { attributes, range, _ in
                if let _ = attributes[NSAttributedString.Key.strikethroughStyle] {
                    let lowerX = floor(CTLineGetOffsetForStringIndex(line, range.location, nil))
                    let upperX = ceil(CTLineGetOffsetForStringIndex(line, range.location + range.length, nil))
                    let x = lowerX < upperX ? lowerX : upperX
                    strikethroughItems.append(InstantPageTextStrikethroughItem(frame: CGRect(x: workingLineOrigin.x + x, y: workingLineOrigin.y, width: abs(upperX - lowerX), height: fontLineHeight)))
                }
                if let _ = attributes[NSAttributedString.Key.underlineStyle] {
                    let lowerX = floor(CTLineGetOffsetForStringIndex(line, range.location, nil))
                    let upperX = ceil(CTLineGetOffsetForStringIndex(line, range.location + range.length, nil))
                    let x = lowerX < upperX ? lowerX : upperX
                    underlineItems.append(InstantPageTextUnderlineItem(
                        frame: CGRect(x: workingLineOrigin.x + x, y: workingLineOrigin.y, width: abs(upperX - lowerX), height: fontLineHeight),
                        range: range,
                        color: attributes[NSAttributedString.Key.underlineColor] as? UIColor
                    ))
                }
                if let color = attributes[NSAttributedString.Key.init(rawValue: InstantPageMarkerColorAttribute)] as? UIColor {
                    var lineHeight = fontLineHeight
                    var delta: CGFloat = 0.0
                    
                    if let offset = attributes[NSAttributedString.Key.baselineOffset] as? CGFloat {
                        lineHeight = floorToScreenPixels(lineHeight * 0.85)
                        delta = offset * 0.6
                    }
                    let lowerX = floor(CTLineGetOffsetForStringIndex(line, range.location, nil))
                    let upperX = ceil(CTLineGetOffsetForStringIndex(line, range.location + range.length, nil))
                    let x = lowerX < upperX ? lowerX : upperX
                    markedItems.append(InstantPageTextMarkedItem(frame: CGRect(x: workingLineOrigin.x + x, y: workingLineOrigin.y + delta, width: abs(upperX - lowerX), height: lineHeight), color: color, range: range))
                }
                if let item = attributes[NSAttributedString.Key.init(rawValue: InstantPageAnchorAttribute)] as? Dictionary<String, Any>, let name = item["name"] as? String, let empty = item["empty"] as? Bool {
                    anchorItems.append(InstantPageTextAnchorItem(name: name, anchorText: item["text"] as? NSAttributedString, empty: empty))
                }
            }
            
            if !anchorItems.isEmpty {
                hasAnchors = true
            }
            
            if hadExtraDescent && extraDescent > 0 {
                workingLineOrigin.y += fontLineSpacing
            }
            
            let height = !fontLineHeight.isZero ? max(fontLineHeight, lineMaxAttachmentHeight) : lineMaxAttachmentHeight
            if !lineFormulaItems.isEmpty {
                let baselineAdjustment = height - fontLineHeight
                if !baselineAdjustment.isZero {
                    lineFormulaItems = lineFormulaItems.map { item in
                        InstantPageTextFormulaRun(
                            frame: item.frame.offsetBy(dx: 0.0, dy: baselineAdjustment),
                            range: item.range,
                            attachment: item.attachment
                        )
                    }
                }
            }
            if !markedItems.isEmpty {
                markedItems = markedItems.map { item in
                    if let attachmentBounds = localAttachmentBoundsForRange(item.range, imageItems: lineImageItems, formulaItems: lineFormulaItems) {
                        return InstantPageTextMarkedItem(frame: attachmentBounds, color: item.color, range: item.range)
                    } else {
                        return item
                    }
                }
            }
            let textLine = InstantPageTextLine(line: line, range: lineRange, frame: CGRect(x: workingLineOrigin.x, y: workingLineOrigin.y, width: lineWidth, height: height), strikethroughItems: strikethroughItems, underlineItems: underlineItems, markedItems: markedItems, imageItems: lineImageItems, formulaItems: lineFormulaItems, anchorItems: anchorItems, isRTL: isRTL)
            
            lines.append(textLine)
            imageItems.append(contentsOf: lineImageItems)
            for formulaItem in lineFormulaItems {
                formulaItems.append(InstantPageTextFormulaItem(frame: formulaItem.frame, attachment: formulaItem.attachment))
            }
            
            if lineWidth > maxLineWidth {
                maxLineWidth = lineWidth
            }
            
            workingLineOrigin.x = 0.0
            workingLineOrigin.y += fontLineHeight + fontLineSpacing + extraDescent
            currentLineOrigin = workingLineOrigin
            
            lastIndex += lineCharacterCount
            
            if stop {
                break
            }
        } else {
            break
        }
    }
    
    var height: CGFloat = 0.0
    if !lines.isEmpty && !(string.string == "\u{200b}" && hasAnchors) {
        height = lines.last!.frame.maxY + extraDescent
    }
    
    var textWidth = boundingWidth
    if fitToWidth {
        textWidth = maxLineWidth
    }
    var requiresScroll = false
    if (!imageItems.isEmpty || !formulaItems.isEmpty) && maxLineWidth > boundingWidth + 10.0 {
        textWidth = maxLineWidth
        requiresScroll = true
    }
    
    let textItem = InstantPageTextItem(frame: CGRect(x: 0.0, y: 0.0, width: textWidth, height: height), attributedString: string, alignment: alignment, opaqueBackground: opaqueBackground, lines: lines)
    if !requiresScroll {
        textItem.frame = textItem.frame.offsetBy(dx: offset.x, dy: offset.y)
    }
    var items: [InstantPageItem] = []
    if !requiresScroll && (imageItems.isEmpty || string.length > 1) {
        items.append(textItem)
    }
    
    var topInset: CGFloat = 0.0
    var bottomInset: CGFloat = 0.0
    var additionalItems: [InstantPageItem] = []
    let effectiveOffset = requiresScroll ? CGPoint() : offset
    for line in textItem.lines {
        let lineFrame = frameForLine(line, boundingWidth: boundingWidth, alignment: alignment)
        if let webpage = webpage {
            for imageItem in line.imageItems {
                if let media = media[imageItem.id] {
                    let item = InstantPageImageItem(frame: imageItem.frame.offsetBy(dx: lineFrame.minX + effectiveOffset.x, dy: effectiveOffset.y), webPage: webpage, media: InstantPageMedia(index: -1, media: media, url: nil, caption: nil, credit: nil), interactive: false, roundCorners: false, fit: false)
                    additionalItems.append(item)
                    
                    if item.frame.minY < topInset {
                        topInset = item.frame.minY
                    }
                    if item.frame.maxY > height {
                        bottomInset = max(bottomInset, item.frame.maxY - height)
                    }
                }
            }
        }
        for formulaItem in line.formulaItems {
            let item = InstantPageTextFormulaItem(frame: formulaItem.frame.offsetBy(dx: lineFrame.minX + effectiveOffset.x, dy: effectiveOffset.y), attachment: formulaItem.attachment)
            additionalItems.append(item)

            if item.frame.minY < topInset {
                topInset = item.frame.minY
            }
            if item.frame.maxY > height {
                bottomInset = max(bottomInset, item.frame.maxY - height)
            }
        }
    }
    
    if requiresScroll {
        textItem.frame = textItem.frame.offsetBy(dx: 0.0, dy: abs(topInset))
        for var item in additionalItems {
            item.frame = item.frame.offsetBy(dx: 0.0, dy: abs(topInset))
        }
        let scrollableItem = InstantPageScrollableTextItem(frame: CGRect(origin: offset, size: CGSize(width: boundingWidth + horizontalInset * 2.0, height: height + abs(topInset) + bottomInset)), item: textItem, additionalItems: additionalItems, totalWidth: textWidth, horizontalInset: horizontalInset, rtl: textItem.containsRTL)
        items.append(scrollableItem)
    } else {
        items.append(contentsOf: additionalItems)
    }

    return (requiresScroll ? nil : textItem, items, textItem.frame.size)
}
