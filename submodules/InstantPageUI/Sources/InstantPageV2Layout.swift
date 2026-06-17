import Foundation
import UIKit
import TelegramCore
import Display
import TelegramPresentationData
import TelegramUIPreferences
import TextFormat
import TelegramStringFormatting
import MosaicLayout

// MARK: - Public layout data types

public struct InstantPageV2Layout {
    public let contentSize: CGSize
    public let items: [InstantPageV2LaidOutItem]
    /// Snapshot of the `index` values of every `.details` item present in `items`, captured at layout time.
    public let detailsIndices: [Int]
    /// Media dictionary inherited from the page's `LayoutContext.media`. Used by
    /// `InstantPageV2View.updateInlineImages()` to resolve each text view's
    /// `line.imageItems` MediaIds at update time. Nested layouts (details body,
    /// table cells, table title) carry the parent's same map.
    public let media: [EngineMedia.Id: EngineMedia]
    /// Webpage carried for the same reason — `updateInlineImages()` needs it to
    /// form the `WebpageReference` for `ImageMediaReference.webPage(...)`. May
    /// be nil for non-webpage-anchored layouts; in that case the lookup proceeds
    /// but no fetch signal can be bound (image view simply isn't created).
    public let webpage: TelegramMediaWebpage?

    /// Set by `layoutInstantPageV2` when the page contains at least one `.relative` `textDate`.
    /// The minimum refresh period (seconds, >=10) across all relative dates; the rich-data bubble
    /// schedules a timer on it to keep "N minutes ago" fresh. nil => no relative date => no timer.
    public var formattedDateUpdatePeriod: Int32? = nil

    public init(contentSize: CGSize, items: [InstantPageV2LaidOutItem], detailsIndices: [Int], media: [EngineMedia.Id: EngineMedia] = [:], webpage: TelegramMediaWebpage? = nil) {
        self.contentSize = contentSize
        self.items = items
        self.detailsIndices = detailsIndices
        self.media = media
        self.webpage = webpage
    }

    /// Returns every `InstantPageMedia` produced by this layout (or its nested sub-layouts)
    /// in laid-out order. Used by the gallery helper to enumerate sibling medias and find
    /// central index, mirroring V1's `mediasFromItems(_:)`.
    public func allMedias() -> [InstantPageMedia] {
        var result: [InstantPageMedia] = []
        InstantPageV2Layout.collectMedias(in: self.items, into: &result)
        return result
    }

    private static func collectMedias(in items: [InstantPageV2LaidOutItem], into result: inout [InstantPageMedia]) {
        for item in items {
            switch item {
            case let .mediaImage(m):       result.append(m.media)
            case let .mediaVideo(m):       result.append(m.media)
            case let .mediaMap(m):         result.append(m.media)
            case let .mediaCoverImage(m):  result.append(m.media)
            case let .mediaAudio(m):       result.append(m.media)
            case let .slideshow(s):        result.append(contentsOf: s.medias)
            case let .details(d):
                if let inner = d.innerLayout {
                    collectMedias(in: inner.items, into: &result)
                }
            case let .table(t):
                if let title = t.titleSubLayout {
                    collectMedias(in: title.items, into: &result)
                }
                for cell in t.cells {
                    if let sub = cell.subLayout {
                        collectMedias(in: sub.items, into: &result)
                    }
                }
            default:
                continue
            }
        }
    }
}

public enum InstantPageV2LaidOutItem {
    case text(InstantPageV2TextItem)
    case codeBlock(InstantPageV2CodeBlockItem)
    case divider(InstantPageV2DividerItem)
    case listMarker(InstantPageV2ListMarkerItem)
    case blockQuoteBar(InstantPageV2BarItem)
    case shape(InstantPageV2ShapeItem)
    case mediaPlaceholder(InstantPageV2MediaPlaceholderItem)
    case details(InstantPageV2DetailsItem)
    case table(InstantPageV2TableItem)
    case anchor(InstantPageV2AnchorItem)
    case mediaImage(InstantPageV2MediaImageItem)
    case mediaVideo(InstantPageV2MediaVideoItem)
    case mediaMap(InstantPageV2MediaMapItem)
    case mediaCoverImage(InstantPageV2MediaCoverImageItem)
    case mediaAudio(InstantPageV2MediaAudioItem)
    case formula(InstantPageV2FormulaItem)
    case thinking(InstantPageV2ThinkingItem)
    case slideshow(InstantPageV2SlideshowItem)

    public var frame: CGRect {
        switch self {
        case let .text(item):              return item.frame
        case let .codeBlock(item):         return item.frame
        case let .divider(item):           return item.frame
        case let .listMarker(item):        return item.frame
        case let .blockQuoteBar(item):     return item.frame
        case let .shape(item):             return item.frame
        case let .mediaPlaceholder(item):  return item.frame
        case let .details(item):           return item.frame
        case let .table(item):             return item.frame
        case let .anchor(item):            return item.frame
        case let .mediaImage(item):        return item.frame
        case let .mediaVideo(item):        return item.frame
        case let .mediaMap(item):          return item.frame
        case let .mediaCoverImage(item):   return item.frame
        case let .mediaAudio(item):        return item.frame
        case let .formula(item):           return item.frame
        case let .thinking(item):          return item.frame
        case let .slideshow(item):         return item.frame
        }
    }

    /// Returns a copy of `self` with its top-level frame translated by `delta`.
    /// Sub-layouts inside details/table cells are not re-translated — they're already
    /// expressed in their parent's local coordinates.
    public func offsetBy(_ delta: CGPoint) -> InstantPageV2LaidOutItem {
        switch self {
        case var .text(item):             item.frame = item.frame.offsetBy(dx: delta.x, dy: delta.y); return .text(item)
        case var .codeBlock(item):        item.frame = item.frame.offsetBy(dx: delta.x, dy: delta.y); return .codeBlock(item)
        case var .divider(item):          item.frame = item.frame.offsetBy(dx: delta.x, dy: delta.y); return .divider(item)
        case var .listMarker(item):       item.frame = item.frame.offsetBy(dx: delta.x, dy: delta.y); return .listMarker(item)
        case var .blockQuoteBar(item):    item.frame = item.frame.offsetBy(dx: delta.x, dy: delta.y); return .blockQuoteBar(item)
        case var .shape(item):            item.frame = item.frame.offsetBy(dx: delta.x, dy: delta.y); return .shape(item)
        case var .mediaPlaceholder(item): item.frame = item.frame.offsetBy(dx: delta.x, dy: delta.y); return .mediaPlaceholder(item)
        case var .details(item):          item.frame = item.frame.offsetBy(dx: delta.x, dy: delta.y); return .details(item)
        case var .table(item):            item.frame = item.frame.offsetBy(dx: delta.x, dy: delta.y); return .table(item)
        case var .anchor(item):           item.frame = item.frame.offsetBy(dx: delta.x, dy: delta.y); return .anchor(item)
        case var .mediaImage(item):        item.frame = item.frame.offsetBy(dx: delta.x, dy: delta.y); return .mediaImage(item)
        case var .mediaVideo(item):        item.frame = item.frame.offsetBy(dx: delta.x, dy: delta.y); return .mediaVideo(item)
        case var .mediaMap(item):          item.frame = item.frame.offsetBy(dx: delta.x, dy: delta.y); return .mediaMap(item)
        case var .mediaCoverImage(item):   item.frame = item.frame.offsetBy(dx: delta.x, dy: delta.y); return .mediaCoverImage(item)
        case var .mediaAudio(item):        item.frame = item.frame.offsetBy(dx: delta.x, dy: delta.y); return .mediaAudio(item)
        case var .formula(item):          item.frame = item.frame.offsetBy(dx: delta.x, dy: delta.y); return .formula(item)
        case var .thinking(item):         item.frame = item.frame.offsetBy(dx: delta.x, dy: delta.y); return .thinking(item)
        case var .slideshow(item):        item.frame = item.frame.offsetBy(dx: delta.x, dy: delta.y); return .slideshow(item)
        }
    }
}

public struct InstantPageV2TextItem {
    public var frame: CGRect
    public let textItem: InstantPageTextItem   // V1 type reused as payload
}

public struct InstantPageV2CodeBlockItem {
    public var frame: CGRect
    public let backgroundColor: UIColor
    public let cornerRadius: CGFloat
    public let textItem: InstantPageTextItem
    public let inset: UIEdgeInsets
}

public struct InstantPageV2ThinkingItem {
    public var frame: CGRect
    /// The dimmed thinking text, laid out in block-local coordinates. Drawn fully (never
    /// char-reveal-masked); the shimmer + whole-block fade are the only animations.
    public let textItem: InstantPageTextItem
}

public struct InstantPageV2DividerItem {
    public var frame: CGRect
    public let color: UIColor
}

public struct InstantPageV2CheckboxColors {
    public let background: UIColor
    public let stroke: UIColor
    public let border: UIColor

    public init(background: UIColor, stroke: UIColor, border: UIColor) {
        self.background = background
        self.stroke = stroke
        self.border = border
    }
}

public enum InstantPageV2ListMarkerKind {
    case bullet
    case number(String)
    case checklist(checked: Bool, colors: InstantPageV2CheckboxColors)
}

public struct InstantPageV2ListMarkerItem {
    public var frame: CGRect
    public let kind: InstantPageV2ListMarkerKind
    public let color: UIColor
}

public struct InstantPageV2BarItem {
    public var frame: CGRect
    public let color: UIColor
    public let cornerRadius: CGFloat
}

public enum InstantPageV2ShapeKind {
    case roundedRect(cornerRadius: CGFloat)
    case line(thickness: CGFloat)
}

public struct InstantPageV2ShapeItem {
    public var frame: CGRect
    public let kind: InstantPageV2ShapeKind
    public let color: UIColor
}

public struct InstantPageV2FormulaItem {
    public var frame: CGRect                          // outer frame in parent coords
    public let attachment: InstantPageMathAttachment  // rendered image + dimensions (theme-baked)
    public let isScrollable: Bool                     // true only for block formulas wider than bounds
    public let imageFrame: CGRect                     // image rect in this item's local coords; size must equal attachment.rendered.size for pixel-perfect rendering
    public let scrollContentSize: CGSize              // == frame.size unless isScrollable
}

public enum InstantPageV2MediaPlaceholderKind {
    case image
    case video
    case audio
    case webEmbed
    case postEmbed
    case collage
    case slideshow
    case channelBanner
    case map
    case relatedArticles
}

public struct InstantPageV2MediaImageItem {
    public var frame: CGRect
    public let cornerRadius: CGFloat
    public let media: InstantPageMedia
    public let webPage: TelegramMediaWebpage
    public let attributes: [InstantPageImageAttribute]   // always empty for image; kept for symmetry

    public init(frame: CGRect, cornerRadius: CGFloat, media: InstantPageMedia, webPage: TelegramMediaWebpage, attributes: [InstantPageImageAttribute]) {
        self.frame = frame
        self.cornerRadius = cornerRadius
        self.media = media
        self.webPage = webPage
        self.attributes = attributes
    }
}

public struct InstantPageV2MediaAudioItem {
    public var frame: CGRect
    public let media: InstantPageMedia
    public let webPage: TelegramMediaWebpage

    public init(frame: CGRect, media: InstantPageMedia, webPage: TelegramMediaWebpage) {
        self.frame = frame
        self.media = media
        self.webPage = webPage
    }
}

public struct InstantPageV2MediaVideoItem {
    public var frame: CGRect
    public let cornerRadius: CGFloat
    public let media: InstantPageMedia
    public let webPage: TelegramMediaWebpage
    public let attributes: [InstantPageImageAttribute]   // always empty

    public init(frame: CGRect, cornerRadius: CGFloat, media: InstantPageMedia, webPage: TelegramMediaWebpage, attributes: [InstantPageImageAttribute]) {
        self.frame = frame
        self.cornerRadius = cornerRadius
        self.media = media
        self.webPage = webPage
        self.attributes = attributes
    }
}

public struct InstantPageV2MediaMapItem {
    public var frame: CGRect
    public let cornerRadius: CGFloat
    public let media: InstantPageMedia
    public let webPage: TelegramMediaWebpage
    public let attributes: [InstantPageImageAttribute]   // [InstantPageMapAttribute] with zoom + dimensions

    public init(frame: CGRect, cornerRadius: CGFloat, media: InstantPageMedia, webPage: TelegramMediaWebpage, attributes: [InstantPageImageAttribute]) {
        self.frame = frame
        self.cornerRadius = cornerRadius
        self.media = media
        self.webPage = webPage
        self.attributes = attributes
    }
}

public struct InstantPageV2MediaCoverImageItem {
    public var frame: CGRect
    public let cornerRadius: CGFloat
    public let media: InstantPageMedia                   // media.media == .webpage(synthesized fake webpage with cover image)
    public let webPage: TelegramMediaWebpage             // the parent IV's webpage (for WebpageReference)
    public let attributes: [InstantPageImageAttribute]   // always empty

    public init(frame: CGRect, cornerRadius: CGFloat, media: InstantPageMedia, webPage: TelegramMediaWebpage, attributes: [InstantPageImageAttribute]) {
        self.frame = frame
        self.cornerRadius = cornerRadius
        self.media = media
        self.webPage = webPage
        self.attributes = attributes
    }
}

public struct InstantPageV2MediaPlaceholderItem {
    public var frame: CGRect
    public let kind: InstantPageV2MediaPlaceholderKind
    public let cornerRadius: CGFloat
}

public struct InstantPageV2SlideshowItem {
    public var frame: CGRect
    public let medias: [InstantPageMedia]
    public let webPage: TelegramMediaWebpage

    public init(frame: CGRect, medias: [InstantPageMedia], webPage: TelegramMediaWebpage) {
        self.frame = frame
        self.medias = medias
        self.webPage = webPage
    }
}

public struct InstantPageV2DetailsItem {
    public var frame: CGRect
    public let index: Int
    public let sideInset: CGFloat
    public let titleTextItem: InstantPageTextItem
    public let titleFrame: CGRect            // local to this item's frame
    public let separatorColor: UIColor
    public let isExpanded: Bool
    public let innerLayout: InstantPageV2Layout?
    public let defaultExpanded: Bool         // from the InstantPageBlock model
    public let rtl: Bool                      // mirror chevron + title onto the trailing edge
}

public enum InstantPageV2TableVerticalAlignment {
    case top, middle, bottom
}

public struct InstantPageV2TableCell {
    public let frame: CGRect                 // local to the table's content area
    public let isHeader: Bool
    public let horizontalAlignment: NSTextAlignment
    public let verticalAlignment: InstantPageV2TableVerticalAlignment
    public let backgroundColor: UIColor?
    public let subLayout: InstantPageV2Layout?
}

public struct InstantPageV2TableItem {
    public var frame: CGRect
    public let titleSubLayout: InstantPageV2Layout?
    public let titleFrame: CGRect?
    public let contentSize: CGSize           // grid intrinsic size; may exceed frame.width → scroll
    public let contentInset: CGFloat         // page horizontalInset; the renderer shifts the grid right by it and pads the scroll content by it on BOTH sides
    public let cells: [InstantPageV2TableCell]
    public let horizontalLines: [CGRect]
    public let verticalLines: [CGRect]
    public let bordered: Bool
    public let striped: Bool
    public let borderColor: UIColor
}

public struct InstantPageV2AnchorItem {
    public var frame: CGRect                 // zero-height
    public let name: String
}

// MARK: - Public entry points

public func layoutInstantPageV2(
    webpage: TelegramMediaWebpage,
    instantPage: InstantPage,
    userLocation: MediaResourceUserLocation,
    boundingWidth: CGFloat,
    horizontalInset: CGFloat,
    theme: InstantPageTheme,
    strings: PresentationStrings,
    dateTimeFormat: PresentationDateTimeFormat,
    cachedMessageSyntaxHighlight: CachedMessageSyntaxHighlight?,
    expandedDetails: [Int: Bool],
    fitToWidth: Bool,
    computeRevealCharacterRects: Bool = false
) -> InstantPageV2Layout {
    guard case let .Loaded(loadedContent) = webpage.content else {
        return InstantPageV2Layout(contentSize: .zero, items: [], detailsIndices: [])
    }

    var media = instantPage.media.mapValues(EngineMedia.init)
    if let image = loadedContent.image, let id = image.id {
        media[id] = .image(image)
    }
    if let video = loadedContent.file, let id = video.id {
        media[id] = .file(video)
    }

    let dateAccumulator = DateUpdateAccumulator()
    let formatDate: (Int32, MessageTextEntityType.DateTimeFormat) -> String = { timestamp, format in
        if case .relative = format {
            let now = Int32(CFAbsoluteTimeGetCurrent() + NSTimeIntervalSince1970)
            let age = abs(now - timestamp)
            // Cap the fastest bucket at 10s (the message-entity reference uses 1s for <120s).
            let period: Int32 = age < 120 ? 10 : (age <= 60 * 60 ? 60 : 30 * 60)
            dateAccumulator.period = dateAccumulator.period.map { min($0, period) } ?? period
        }
        return stringForEntityFormattedDate(timestamp: timestamp, format: format, strings: strings, dateTimeFormat: dateTimeFormat)
    }

    var context = LayoutContext(
        theme: theme,
        strings: strings,
        dateTimeFormat: dateTimeFormat,
        formatDate: formatDate,
        userLocation: userLocation,
        webpage: webpage,
        media: media,
        cachedMessageSyntaxHighlight: cachedMessageSyntaxHighlight,
        rtl: instantPage.rtl,
        fitToWidth: fitToWidth,
        computeRevealCharacterRects: computeRevealCharacterRects,
        pageHorizontalInset: horizontalInset,
        mediaIndexCounter: 0,
        detailsIndexCounter: 0,
        expandedDetails: expandedDetails
    )

    var result = layoutBlockSequence(
        instantPage.blocks,
        boundingWidth: boundingWidth,
        horizontalInset: horizontalInset,
        kind: .topLevel,
        context: &context
    )
    result.formattedDateUpdatePeriod = dateAccumulator.period
    return result
}

/// Used by `ChatMessageRichDataBubbleContentNode` to anchor the date/checks status node at the
/// bottom-right of the last text line in the bubble.
public func lastTextLineFrame(in layout: InstantPageV2Layout) -> CGRect? {
    // Walk items in reverse; descend into the LAST sub-layout when the last container has one.
    for item in layout.items.reversed() {
        switch item {
        case let .text(text):
            if let last = text.textItem.lines.last {
                return last.frame.offsetBy(dx: text.frame.minX, dy: text.frame.minY)
            }
        case let .codeBlock(block):
            if let last = block.textItem.lines.last {
                return last.frame
                    .offsetBy(dx: block.textItem.frame.minX, dy: block.textItem.frame.minY)
                    .offsetBy(dx: block.frame.minX, dy: block.frame.minY)
            }
        case let .details(details):
            if let inner = details.innerLayout, let innerFrame = lastTextLineFrame(in: inner) {
                return innerFrame.offsetBy(dx: details.frame.minX, dy: details.frame.minY + details.titleFrame.maxY)
            }
            // Title fallback
            if let last = details.titleTextItem.lines.last {
                return last.frame
                    .offsetBy(dx: details.titleTextItem.frame.minX, dy: details.titleTextItem.frame.minY)
                    .offsetBy(dx: details.frame.minX, dy: details.frame.minY)
            }
        case let .table(table):
            // Walk cells in reverse row-major order (last cell of last row first).
            // The renderer shifts cells down by gridOffsetY (title height) — match that here.
            let gridOffsetY = table.titleFrame?.height ?? 0.0
            for cell in table.cells.reversed() {
                if let subLayout = cell.subLayout, let frame = lastTextLineFrame(in: subLayout) {
                    return frame
                        .offsetBy(dx: cell.frame.minX, dy: cell.frame.minY + gridOffsetY)
                        .offsetBy(dx: table.frame.minX, dy: table.frame.minY)
                }
            }
        default:
            continue
        }
    }
    return nil
}

/// Variant of `lastTextLineFrame(in:)` that returns the last text line frame only when the
/// bottom-most top-level item in the layout is itself a text item. When the layout ends in a
/// non-text item (table, image, divider, list marker, details, …) it returns nil, so callers
/// place the trailing status below all content rather than beside text buried above the final
/// item.
///
/// Also returns `trailingBottomPadding`: the renderer draws the baseline at the line frame's maxY,
/// so the visible text of a plain line sits ~5pt below it. A status that *trails on the line* should
/// anchor at `maxY + trailingBottomPadding` to align with where the text actually renders. The pad
/// is 0 when the line is taller than its font line height (a tall inline attachment, e.g. a formula,
/// already pushes maxY down to the right spot). Callers should NOT apply the pad when the status
/// wraps onto its own line below the text — there it should sit at the bare maxY.
public func lastTextLineFrameIfLastItemIsText(in layout: InstantPageV2Layout) -> (frame: CGRect, trailingBottomPadding: CGFloat)? {
    guard let bottomItem = layout.items.max(by: { $0.frame.maxY < $1.frame.maxY }),
          case let .text(text) = bottomItem,
          let last = text.textItem.lines.last
    else {
        return nil
    }
    // The stored line frame always has minX = 0 — alignment (center / right / natural-RTL) is
    // applied at render time by `v2FrameForLine`. Apply the same correction here so the returned
    // frame's `maxX` reflects the line's actual on-screen right edge, not just its width anchored
    // at the textItem's left. Without this, a right-aligned or RTL last line — whose visible right
    // edge sits at `textItem.width`, all the way at the right text inset — would feed the status
    // node a `contentWidth` equal to just `lineWidth`. The trail/wrap decision would then think
    // the date fits trailing the line, and place it directly on top of the line at the right text
    // inset where the line itself ends. The width is unchanged; only `origin.x` shifts.
    let displayedLineFrame = v2FrameForLine(last, boundingWidth: text.textItem.frame.width, alignment: text.textItem.alignment)
    let lineFrame = displayedLineFrame.offsetBy(dx: text.frame.minX, dy: text.frame.minY)
    var ascent: CGFloat = 0.0
    var descent: CGFloat = 0.0
    var leading: CGFloat = 0.0
    _ = CTLineGetTypographicBounds(last.line, &ascent, &descent, &leading)
    let isInflatedByAttachment = lineFrame.height > ascent + descent + 1.0
    return (lineFrame, isInflatedByAttachment ? 0.0 : 5.0)
}

// MARK: - Layout context

private final class DateUpdateAccumulator {
    var period: Int32?
}

private struct LayoutContext {
    let theme: InstantPageTheme
    let strings: PresentationStrings
    let dateTimeFormat: PresentationDateTimeFormat
    let formatDate: (Int32, MessageTextEntityType.DateTimeFormat) -> String
    let userLocation: MediaResourceUserLocation
    let webpage: TelegramMediaWebpage
    let media: [EngineMedia.Id: EngineMedia]
    let cachedMessageSyntaxHighlight: CachedMessageSyntaxHighlight?
    let rtl: Bool
    let fitToWidth: Bool
    let computeRevealCharacterRects: Bool
    let pageHorizontalInset: CGFloat

    var mediaIndexCounter: Int = 0
    var detailsIndexCounter: Int = 0

    let expandedDetails: [Int: Bool]
}

// MARK: - Driver

private func layoutBlockSequence(
    _ blocks: [InstantPageBlock],
    boundingWidth: CGFloat,
    horizontalInset: CGFloat,
    kind: BlockSequenceKind,
    context: inout LayoutContext
) -> InstantPageV2Layout {
    var items: [InstantPageV2LaidOutItem] = []
    var detailsIndices: [Int] = []
    var contentHeight: CGFloat = 0.0
    var previousBlock: InstantPageBlock?

    for (i, block) in blocks.enumerated() {
        let spacing = spacingBetweenBlocks(upper: previousBlock, lower: block, fitToWidth: context.fitToWidth, kind: kind)
        let localItems = layoutBlock(
            block,
            boundingWidth: boundingWidth,
            horizontalInset: horizontalInset,
            kind: kind,
            isCover: false,
            previousItems: items,
            isLast: i == blocks.count - 1,
            context: &context
        )

        // Translate local items by (0, contentHeight + spacing) and append.
        let dy = contentHeight + spacing
        var blockMaxY: CGFloat = 0.0
        for var item in localItems {
            item = item.offsetBy(CGPoint(x: 0.0, y: dy))
            if case let .details(d) = item {
                detailsIndices.append(d.index)
            }
            let f = item.frame
            if f.maxY > blockMaxY {
                blockMaxY = f.maxY
            }
            items.append(item)
        }

        if blockMaxY > contentHeight {
            contentHeight = blockMaxY
            previousBlock = block
        }
    }

    let closingSpacing = spacingBetweenBlocks(upper: previousBlock, lower: nil, fitToWidth: context.fitToWidth, kind: kind)
    contentHeight += closingSpacing

    var contentSize = CGSize(width: boundingWidth, height: contentHeight)
    if context.fitToWidth {
        // Match V1 InstantPageLayout.swift:1114 — include `+ horizontalInset` so the contentSize
        // reserves a right margin equal to the left inset. Without this, the longest text item's
        // right edge equals contentSize.width, and the bubble's containerNode (sized to
        // boundingSize.width - 2) clips the last 2pt of text.
        var maxX: CGFloat = 0.0
        for item in items {
            maxX = max(maxX, ceil(item.frame.maxX) + horizontalInset)
        }
        contentSize.width = min(maxX, boundingWidth)
    }

    return InstantPageV2Layout(contentSize: contentSize, items: items, detailsIndices: detailsIndices, media: context.media, webpage: context.webpage)
}

// MARK: - Markdown block context stamping helpers

private func stampMarkdownContext(_ items: [InstantPageV2LaidOutItem], kind: InstantPageMarkdownBlockContext.Kind) {
    for item in items {
        switch item {
        case let .text(textItem):
            if textItem.textItem.markdownContext == nil {
                textItem.textItem.markdownContext = InstantPageMarkdownBlockContext(kind: kind)
            }
        case let .codeBlock(block):
            if block.textItem.markdownContext == nil {
                block.textItem.markdownContext = InstantPageMarkdownBlockContext(kind: kind)
            }
        default:
            break
        }
    }
}

/// Marks every text item produced by a blockquote's children as quoted (depth + 1),
/// preserving each child's own kind (heading/list/paragraph/…).
private func bumpQuoteDepth(_ items: [InstantPageV2LaidOutItem]) {
    for item in items {
        let target: InstantPageTextItem?
        switch item {
        case let .text(textItem): target = textItem.textItem
        case let .codeBlock(block): target = block.textItem
        default: target = nil
        }
        guard let target else { continue }
        if var ctx = target.markdownContext {
            ctx.quoteDepth += 1
            target.markdownContext = ctx
        } else {
            target.markdownContext = InstantPageMarkdownBlockContext(kind: .paragraph, quoteDepth: 1)
        }
    }
}

private func layoutBlock(
    _ block: InstantPageBlock,
    boundingWidth: CGFloat,
    horizontalInset: CGFloat,
    kind: BlockSequenceKind,
    isCover: Bool,
    previousItems: [InstantPageV2LaidOutItem],
    isLast: Bool,
    context: inout LayoutContext
) -> [InstantPageV2LaidOutItem] {
    let _ = isLast  // reserved for Tasks 7–9
    switch block {
    case let .cover(inner):
        return layoutBlock(inner, boundingWidth: boundingWidth, horizontalInset: horizontalInset, kind: kind,
                           isCover: true, previousItems: previousItems, isLast: isLast, context: &context)
    case let .title(text):
        let titleItems = layoutSimpleText(text, category: .header, boundingWidth: boundingWidth,
                                          horizontalInset: horizontalInset, context: &context)
        stampMarkdownContext(titleItems, kind: .title)
        return titleItems
    case let .subtitle(text):
        return layoutSimpleText(text, category: .subheader, boundingWidth: boundingWidth,
                                horizontalInset: horizontalInset, context: &context)
    case let .kicker(text):
        return layoutSimpleText(text, category: .kicker, boundingWidth: boundingWidth,
                                horizontalInset: horizontalInset, context: &context)
    case let .header(text):
        return layoutSimpleText(text, category: .header, boundingWidth: boundingWidth,
                                horizontalInset: horizontalInset, context: &context)
    case let .subheader(text):
        return layoutSimpleText(text, category: .subheader, boundingWidth: boundingWidth,
                                horizontalInset: horizontalInset, context: &context)
    case let .heading(text, level):
        return layoutHeading(text, level: level, boundingWidth: boundingWidth,
                             horizontalInset: horizontalInset, context: &context)
    case let .footer(text):
        return layoutSimpleText(text, category: .caption, boundingWidth: boundingWidth,
                                horizontalInset: horizontalInset, context: &context)
    case let .paragraph(text):
        return layoutParagraph(text, boundingWidth: boundingWidth, horizontalInset: horizontalInset, kind: kind,
                               previousItems: previousItems, context: &context)
    case let .authorDate(author, date):
        return layoutAuthorDate(author: author, date: date, boundingWidth: boundingWidth,
                                horizontalInset: horizontalInset, previousItems: previousItems, context: &context)
    case .divider:
        return layoutDivider(boundingWidth: boundingWidth, context: context)
    case let .anchor(name):
        return [.anchor(InstantPageV2AnchorItem(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 0.0), name: name))]

    case let .list(items, ordered):
        return layoutList(items, ordered: ordered, boundingWidth: boundingWidth,
                          horizontalInset: horizontalInset, kind: kind, context: &context)

    case let .preformatted(text, language):
        return layoutCodeBlock(text, language: language, boundingWidth: boundingWidth,
                               horizontalInset: horizontalInset, context: &context)

    case let .blockQuote(blocks, caption):
        return layoutBlockQuote(blocks: blocks, caption: caption,
                                boundingWidth: boundingWidth, horizontalInset: horizontalInset, kind: kind,
                                isLast: isLast, context: &context)
    case let .pullQuote(text, caption):
        return layoutQuoteText(text: text, caption: caption, isPull: true,
                               boundingWidth: boundingWidth, horizontalInset: horizontalInset,
                               context: &context)

    case let .image(id, caption, url, webpageId):
        if case let .image(image) = context.media[id], let largest = largestImageRepresentation(image.representations) {
            let naturalSize = CGSize(width: CGFloat(largest.dimensions.width), height: CGFloat(largest.dimensions.height))
            let mediaUrl: InstantPageUrlItem? = url.flatMap { InstantPageUrlItem(url: $0, webpageId: webpageId) }
            let mediaIndex = context.mediaIndexCounter
            context.mediaIndexCounter += 1
            let instantPageMedia = InstantPageMedia(
                index: mediaIndex,
                media: .image(image),
                url: mediaUrl,
                caption: caption.text,
                credit: caption.credit
            )
            let webpage = context.webpage
            return layoutTypedMediaWithCaption(
                produceItem: { frame, cornerRadius in
                    .mediaImage(InstantPageV2MediaImageItem(
                        frame: frame,
                        cornerRadius: cornerRadius,
                        media: instantPageMedia,
                        webPage: webpage,
                        attributes: []
                    ))
                },
                naturalSize: naturalSize,
                caption: caption,
                isCover: isCover,
                cornerRadius: 8.0,
                flush: true,
                boundingWidth: boundingWidth,
                horizontalInset: horizontalInset,
                context: &context
            )
        } else {
            // Fallback when the image is not present in the page's media dict — preserve V1
            // behavior, which returns an empty layout for unknown image IDs (V1
            // InstantPageLayout.swift:623). The existing layoutMediaWithCaption would emit a
            // grey rectangle; matching V1 instead.
            return []
        }

    case let .video(id, caption, _, _):
        if case let .file(file) = context.media[id], let dimensions = file.dimensions {
            let naturalSize = CGSize(width: CGFloat(dimensions.width), height: CGFloat(dimensions.height))
            let mediaIndex = context.mediaIndexCounter
            context.mediaIndexCounter += 1
            let instantPageMedia = InstantPageMedia(
                index: mediaIndex,
                media: .file(file),
                url: nil,
                caption: caption.text,
                credit: caption.credit
            )
            let webpage = context.webpage
            return layoutTypedMediaWithCaption(
                produceItem: { frame, cornerRadius in
                    .mediaVideo(InstantPageV2MediaVideoItem(
                        frame: frame,
                        cornerRadius: cornerRadius,
                        media: instantPageMedia,
                        webPage: webpage,
                        attributes: []
                    ))
                },
                naturalSize: naturalSize,
                caption: caption,
                isCover: isCover,
                cornerRadius: 8.0,
                flush: true,
                boundingWidth: boundingWidth,
                horizontalInset: horizontalInset,
                context: &context
            )
        } else {
            return []
        }

    case let .audio(audioId, caption):
        guard case let .file(file) = context.media[audioId] else {
            return []
        }
        let mediaIndex = context.mediaIndexCounter
        context.mediaIndexCounter += 1
        let instantPageMedia = InstantPageMedia(
            index: mediaIndex,
            media: .file(file),
            url: nil,
            caption: nil,
            credit: nil
        )
        let audioFrame = CGRect(x: 0.0, y: 0.0, width: boundingWidth, height: 44.0)
        var result: [InstantPageV2LaidOutItem] = [.mediaAudio(InstantPageV2MediaAudioItem(
            frame: audioFrame,
            media: instantPageMedia,
            webPage: context.webpage
        ))]
        let (captionItems, _) = layoutCaptionAndCredit(
            caption,
            offset: audioFrame.height,
            boundingWidth: boundingWidth,
            horizontalInset: horizontalInset,
            context: &context
        )
        result.append(contentsOf: captionItems)
        return result

    case let .webEmbed(url, _, dimensions, caption, _, _, coverId):
        // V1 (InstantPageLayout.swift:848): if the embed has a URL and a resolvable cover image,
        // V1 synthesizes a fake webpage holding the cover image and renders it as an image cell
        // with a play overlay. Otherwise V1 produces a WKWebView embed (out of scope for V2).
        if let url = url,
           let coverId = coverId,
           case let .image(coverImage) = context.media[coverId] {
            let embedHeight: CGFloat = CGFloat(dimensions?.height ?? 240)
            let naturalSize = CGSize(width: boundingWidth, height: embedHeight)
            let size = PixelDimensions(width: Int32(naturalSize.width), height: Int32(naturalSize.height))
            let loadedContent = TelegramMediaWebpageLoadedContent(
                url: url,
                displayUrl: url,
                hash: 0,
                type: "video",
                websiteName: nil,
                title: nil,
                text: nil,
                embedUrl: url,
                embedType: "video",
                embedSize: size,
                duration: nil,
                author: nil,
                isMediaLargeByDefault: nil,
                imageIsVideoCover: false,
                image: coverImage,
                file: nil,
                story: nil,
                attributes: [],
                instantPage: nil
            )
            let coverWebpage = TelegramMediaWebpage(
                webpageId: EngineMedia.Id(namespace: Namespaces.Media.LocalWebpage, id: -1),
                content: .Loaded(loadedContent)
            )
            let mediaIndex = context.mediaIndexCounter
            context.mediaIndexCounter += 1
            let instantPageMedia = InstantPageMedia(
                index: mediaIndex,
                media: .webpage(coverWebpage),
                url: nil,
                caption: caption.text,
                credit: caption.credit
            )
            let webpage = context.webpage
            return layoutTypedMediaWithCaption(
                produceItem: { frame, cornerRadius in
                    .mediaCoverImage(InstantPageV2MediaCoverImageItem(
                        frame: frame,
                        cornerRadius: cornerRadius,
                        media: instantPageMedia,
                        webPage: webpage,
                        attributes: []
                    ))
                },
                naturalSize: naturalSize,
                caption: caption,
                isCover: false,
                cornerRadius: 0.0,
                flush: true,
                boundingWidth: boundingWidth,
                horizontalInset: horizontalInset,
                context: &context
            )
        } else {
            // No cover image → keep the existing grey-placeholder path (plain web embed).
            let h: CGFloat = CGFloat(dimensions?.height ?? 240)
            return layoutMediaWithCaption(kind: .webEmbed,
                naturalSize: CGSize(width: boundingWidth, height: h), caption: caption,
                isCover: false, cornerRadius: 0.0, flush: true, boundingWidth: boundingWidth,
                horizontalInset: horizontalInset, context: &context)
        }

    case let .postEmbed(_, _, _, _, _, _, caption):
        return layoutMediaWithCaption(kind: .postEmbed,
            naturalSize: CGSize(width: boundingWidth, height: 140.0), caption: caption,
            isCover: false, cornerRadius: 8.0, flush: true, boundingWidth: boundingWidth,
            horizontalInset: horizontalInset, context: &context)

    case let .collage(items, caption):
        return layoutCollage(items: items, caption: caption, isCover: isCover,
                             boundingWidth: boundingWidth, horizontalInset: horizontalInset, context: &context)

    case let .slideshow(items, caption):
        return layoutSlideshow(items: items, caption: caption,
                               boundingWidth: boundingWidth, horizontalInset: horizontalInset, context: &context)

    case let .channelBanner(channel):
        if channel == nil { return [] }
        return layoutMediaWithCaption(kind: .channelBanner,
            naturalSize: CGSize(width: boundingWidth, height: 60.0),
            caption: InstantPageCaption(text: .empty, credit: .empty),
            isCover: false, cornerRadius: 0.0, flush: true, boundingWidth: boundingWidth,
            horizontalInset: horizontalInset, context: &context)

    case let .map(latitude, longitude, zoom, dimensions, caption):
        // AI/server-sent `.map` blocks can arrive with zero `dimensions` (the wire `w`/`h` are
        // required, but the sender may put 0). A zero `naturalSize.height` collapses the media
        // frame to height 0 (`instantPageV2MediaFrame`'s else branch) — the map takes no space,
        // the caption slides up into it, and the pin floats over the caption — and a zero-sized
        // `MapSnapshotMediaResource` makes `MKMapSnapshotter` render nothing. Substitute a sensible
        // default (a 2:1 map strip) for BOTH the layout size and the snapshot resource. Real web
        // articles (the V1 renderer) always carry real dimensions, so only the rich-message path
        // hits this; the fallback is scoped here rather than in V1 or the wire/parse layer.
        let effectiveDimensions: PixelDimensions
        if dimensions.width > 0 && dimensions.height > 0 {
            effectiveDimensions = dimensions
        } else {
            effectiveDimensions = PixelDimensions(width: 600, height: 300)
        }
        let naturalSize = CGSize(width: CGFloat(effectiveDimensions.width), height: CGFloat(effectiveDimensions.height))
        let map = TelegramMediaMap(
            latitude: latitude,
            longitude: longitude,
            heading: nil,
            accuracyRadius: nil,
            venue: nil,
            liveBroadcastingTimeout: nil,
            liveProximityNotificationRadius: nil
        )
        let mapAttributes: [InstantPageImageAttribute] = [InstantPageMapAttribute(zoom: zoom, dimensions: effectiveDimensions.cgSize)]
        let mediaIndex = context.mediaIndexCounter
        context.mediaIndexCounter += 1
        let instantPageMedia = InstantPageMedia(
            index: mediaIndex,
            media: .geo(map),
            url: nil,
            caption: caption.text,
            credit: caption.credit
        )
        let webpage = context.webpage
        return layoutTypedMediaWithCaption(
            produceItem: { frame, cornerRadius in
                .mediaMap(InstantPageV2MediaMapItem(
                    frame: frame,
                    cornerRadius: cornerRadius,
                    media: instantPageMedia,
                    webPage: webpage,
                    attributes: mapAttributes
                ))
            },
            naturalSize: naturalSize,
            caption: caption,
            isCover: false,
            cornerRadius: 8.0,
            flush: true,
            boundingWidth: boundingWidth,
            horizontalInset: horizontalInset,
            context: &context
        )

    case let .relatedArticles(_, articles):
        let h = min(CGFloat(articles.count) * 80.0, 320.0)
        return layoutMediaWithCaption(kind: .relatedArticles,
            naturalSize: CGSize(width: boundingWidth, height: max(h, 80.0)),
            caption: InstantPageCaption(text: .empty, credit: .empty),
            isCover: false, cornerRadius: 0.0, flush: true, boundingWidth: boundingWidth,
            horizontalInset: horizontalInset, context: &context)

    case let .formula(latex):
        return layoutFormulaBlock(latex: latex,
                                  boundingWidth: boundingWidth,
                                  horizontalInset: horizontalInset, kind: kind,
                                  context: &context)

    case let .details(title, blocks, expanded):
        return layoutDetails(title: title, blocks: blocks, defaultExpanded: expanded,
                             boundingWidth: boundingWidth, horizontalInset: horizontalInset,
                             context: &context)

    case let .table(title, rows, bordered, striped):
        return layoutTable(title: title, rows: rows, bordered: bordered, striped: striped,
                           boundingWidth: boundingWidth, horizontalInset: horizontalInset,
                           context: &context)

    case let .thinking(text):
        return layoutThinking(text, boundingWidth: boundingWidth,
                              horizontalInset: horizontalInset, context: &context)
    case .unsupported:
        return []
    }
}

// MARK: - Formula block layout

/// Lays out a top-level `InstantPageBlock.formula(latex:)`. The latex is rendered synchronously
/// through `instantPageMathAttachment(...)` (SwiftMath → `MTMathRenderer`) using the current
/// paragraph theme's color and font size; the resulting pre-rendered `UIImage` is wrapped in
/// an `InstantPageV2FormulaItem`. Wide formulas set `isScrollable = true`; on render failure
/// the raw latex source is laid out as a regular paragraph (matches V1 fallback).
private func layoutFormulaBlock(
    latex: String,
    boundingWidth: CGFloat,
    horizontalInset: CGFloat,
    kind: BlockSequenceKind,
    context: inout LayoutContext
) -> [InstantPageV2LaidOutItem] {
    // Style stack matches V1's per-block formula (paragraph category, not header).
    let styleStack = InstantPageTextStyleStack()
    setupStyleStack(styleStack, theme: context.theme, category: .paragraph, link: false)
    let attributes = styleStack.textAttributes()
    let textColor = (attributes[.foregroundColor] as? UIColor)
                    ?? context.theme.textCategories.paragraph.color
    let fontSize = (attributes[.font] as? UIFont)?.pointSize
                    ?? context.theme.textCategories.paragraph.font.size

    guard let attachment = instantPageMathAttachment(latex: latex,
                                                     fontSize: fontSize,
                                                     textColor: textColor,
                                                     mode: .block) else {
        // Render failure: fall back to the raw latex source as a regular paragraph.
        return layoutParagraph(.plain(latex),
                               boundingWidth: boundingWidth,
                               horizontalInset: horizontalInset,
                               kind: kind,
                               previousItems: [],
                               context: &context)
    }

    let availableWidth = boundingWidth - horizontalInset * 2.0
    let renderedSize = attachment.rendered.size

    if renderedSize.width > availableWidth {
        // Wide formula: scroll view fills the bubble's available width so the image can pan inside.
        let frame = CGRect(x: 0.0, y: 0.0, width: boundingWidth, height: renderedSize.height)
        let item = InstantPageV2FormulaItem(
            frame: frame,
            attachment: attachment,
            isScrollable: true,
            imageFrame: CGRect(x: horizontalInset, y: 0.0,
                               width: renderedSize.width, height: renderedSize.height),
            scrollContentSize: CGSize(width: renderedSize.width + horizontalInset * 2.0,
                                      height: renderedSize.height)
        )
        return [.formula(item)]
    } else {
        // Narrow formula: report the image's natural extent (left-inset + width) so the
        // bubble's `fitToWidth` contentSize shrinks instead of stretching to `boundingWidth`.
        // When the formula is the widest item, the bubble centers itself in the chat row.
        let frame = CGRect(x: horizontalInset, y: 0.0,
                           width: renderedSize.width, height: renderedSize.height)
        let item = InstantPageV2FormulaItem(
            frame: frame,
            attachment: attachment,
            isScrollable: false,
            imageFrame: CGRect(origin: .zero, size: renderedSize),
            scrollContentSize: renderedSize
        )
        return [.formula(item)]
    }
}

// MARK: - Details layout

private func layoutDetails(
    title: RichText,
    blocks: [InstantPageBlock],
    defaultExpanded: Bool,
    boundingWidth: CGFloat,
    horizontalInset: CGFloat,
    context: inout LayoutContext
) -> [InstantPageV2LaidOutItem] {
    let index = context.detailsIndexCounter
    context.detailsIndexCounter += 1

    // Title text item at top.
    // V1 (InstantPageDetailsItem.swift:98–101): boundingWidth - detailsInset*2 - titleInset, titleHeight = max(44, titleSize.height + 26).
    let titleStyleStack = InstantPageTextStyleStack()
    setupStyleStack(titleStyleStack, theme: context.theme, category: .paragraph, link: false)
    let (titleTextItem, _, _) = layoutTextItem(
        attributedStringForRichText(title, styleStack: titleStyleStack, formatDate: context.formatDate),
        boundingWidth: boundingWidth - horizontalInset * 2.0 - 32.0,   // reserve right edge for chevron
        offset: CGPoint(x: 0.0, y: 0.0),
        fitToWidth: context.fitToWidth,
        computeRevealCharacterRects: context.computeRevealCharacterRects
    )
    guard let titleTextItem = titleTextItem else { return [] }
    
    let titleHeight = max(44.0, titleTextItem.frame.height + 26.0)
    titleTextItem.frame.origin.x = context.rtl
        ? (boundingWidth - horizontalInset - 23.0 - titleTextItem.frame.width)
        : (horizontalInset + 23.0)
    titleTextItem.frame.origin.y = floorToScreenPixels((titleHeight - titleTextItem.frame.height) * 0.5)

    let isExpanded = context.expandedDetails[index] ?? defaultExpanded

    // V1 uses max(44.0, titleSize.height + 26.0); matched here.
    let titleFrame = CGRect(x: 0.0, y: 0.0, width: boundingWidth, height: titleHeight)

    var innerLayout: InstantPageV2Layout?
    var totalHeight = titleHeight
    if isExpanded {
        let layout = layoutBlockSequence(
            blocks,
            boundingWidth: boundingWidth,
            horizontalInset: horizontalInset,
            kind: .detail,
            context: &context
        )
        innerLayout = layout
        totalHeight += layout.contentSize.height
    }

    let item = InstantPageV2DetailsItem(
        frame: CGRect(x: 0.0, y: 0.0, width: boundingWidth, height: totalHeight),
        index: index,
        sideInset: horizontalInset,
        titleTextItem: titleTextItem,
        titleFrame: titleFrame,
        separatorColor: context.theme.separatorColor,
        isExpanded: isExpanded,
        innerLayout: innerLayout,
        defaultExpanded: defaultExpanded,
        rtl: context.rtl
    )
    return [.details(item)]
}

// MARK: - Table layout

private struct V2TableRow {
    var minColumnWidths: [Int: CGFloat]
    var maxColumnWidths: [Int: CGFloat]
}

let v2TableCellInsets: UIEdgeInsets = {
    return UIEdgeInsets(top: 15.0, left: 13.0, bottom: 15.0, right: 13.0)
}()
let v2TableBorderWidth: CGFloat = {
    return UIScreenPixel * 2.0
}()
let v2TableCornerRadius: CGFloat = 10.0

private func layoutTable(
    title: RichText,
    rows: [InstantPageTableRow],
    bordered: Bool,
    striped: Bool,
    boundingWidth: CGFloat,
    horizontalInset: CGFloat,
    context: inout LayoutContext
) -> [InstantPageV2LaidOutItem] {
    if rows.isEmpty {
        return []
    }

    // Style stack shared across all cell text measurements.
    let styleStack = InstantPageTextStyleStack()
    setupStyleStack(styleStack, theme: context.theme, category: .table, link: false)

    let borderWidth = bordered ? v2TableBorderWidth : 0.0
    // Size columns against the inset content width (mirrors V1's `boundingWidth - horizontalInset*2`),
    // so a fitting table aligns with body text on both sides. The item frame stays full-width (flush)
    // and the renderer bakes the inset back in as a left margin on the scroll content.
    let contentBoundingWidth = boundingWidth - horizontalInset * 2.0
    let totalCellPadding = v2TableCellInsets.left + v2TableCellInsets.right
    let cellWidthLimit = contentBoundingWidth - totalCellPadding

    var tableRows: [V2TableRow] = []
    var columnCount: Int = 0

    var columnSpans: [Range<Int>: (CGFloat, CGFloat)] = [:]
    var rowSpans: [Int: [(Int, Int)]] = [:]

    // Pass 1: measure min/max intrinsic width per cell.
    var r: Int = 0
    for row in rows {
        var minColumnWidths: [Int: CGFloat] = [:]
        var maxColumnWidths: [Int: CGFloat] = [:]
        var i: Int = 0

        for cell in row.cells {
            // Advance i past any rowspan-inherited columns (matches V1 lines 311–319).
            if let rowSpan = rowSpans[r] {
                for columnAndSpan in rowSpan {
                    if columnAndSpan.0 == i {
                        i += columnAndSpan.1
                    } else {
                        break
                    }
                }
            }

            var minCellWidth: CGFloat = 1.0
            var maxCellWidth: CGFloat = 1.0
            if let text = cell.text {
                // Mirror V1 (`InstantPageTableItem.layoutTableItem`): `attributedStringForRichText`'s
                // boundingWidth sizes inline attachments to `cellWidthLimit - totalCellPadding`, while
                // the line-break budget passed to `layoutTextItem` is the full `cellWidthLimit`. (V1
                // subtracts `totalCellPadding` only on the attribute-string arg, not the layout arg.)
                let attrStr = attributedStringForRichText(text, styleStack: styleStack, boundingWidth: cellWidthLimit - totalCellPadding, formatDate: context.formatDate)
                if let shortestItem = layoutTextItem(
                    attrStr,
                    boundingWidth: cellWidthLimit,
                    offset: CGPoint(),
                    minimizeWidth: true,
                    fitToWidth: context.fitToWidth,
                    computeRevealCharacterRects: context.computeRevealCharacterRects
                ).0 {
                    minCellWidth = shortestItem.effectiveWidth() + totalCellPadding
                }
                if let longestItem = layoutTextItem(
                    attrStr,
                    boundingWidth: cellWidthLimit,
                    offset: CGPoint(),
                    fitToWidth: context.fitToWidth,
                    computeRevealCharacterRects: context.computeRevealCharacterRects
                ).0 {
                    maxCellWidth = max(minCellWidth, longestItem.effectiveWidth() + totalCellPadding)
                }
            }

            if cell.colspan > 1 {
                minColumnWidths[i] = 1.0
                maxColumnWidths[i] = 1.0
                let spanRange = i ..< i + Int(cell.colspan)
                if let (minSW, maxSW) = columnSpans[spanRange] {
                    columnSpans[spanRange] = (max(minSW, minCellWidth), max(maxSW, maxCellWidth))
                } else {
                    columnSpans[spanRange] = (minCellWidth, maxCellWidth)
                }
            } else {
                minColumnWidths[i] = minCellWidth
                maxColumnWidths[i] = maxCellWidth
            }

            let colspan = cell.colspan > 1 ? Int(clamping: cell.colspan) : 1
            if cell.rowspan > 1 {
                for j in r ..< r + Int(cell.rowspan) {
                    if rowSpans[j] == nil {
                        rowSpans[j] = [(i, colspan)]
                    } else {
                        rowSpans[j]!.append((i, colspan))
                    }
                }
            }

            i += colspan
        }
        tableRows.append(V2TableRow(minColumnWidths: minColumnWidths, maxColumnWidths: maxColumnWidths))
        columnCount = max(columnCount, i)
        r += 1
    }

    // Aggregate column min/max across all rows.
    let maxContentWidth = contentBoundingWidth - borderWidth
    var availableWidth = maxContentWidth
    var minColumnWidths: [Int: CGFloat] = [:]
    var maxColumnWidths: [Int: CGFloat] = [:]
    var maxTotalWidth: CGFloat = 0.0
    for i in 0 ..< columnCount {
        var minWidth: CGFloat = 1.0
        var maxWidth: CGFloat = 1.0
        for row in tableRows {
            if let w = row.minColumnWidths[i] { minWidth = max(minWidth, w) }
            if let w = row.maxColumnWidths[i] { maxWidth = max(maxWidth, w) }
        }
        minColumnWidths[i] = minWidth
        maxColumnWidths[i] = maxWidth
        availableWidth -= minWidth
        maxTotalWidth += maxWidth
    }

    // Apply colspan constraints.
    for (range, span) in columnSpans {
        let (minSpanWidth, maxSpanWidth) = span
        var minWidth: CGFloat = 0.0
        var maxWidth: CGFloat = 0.0
        for i in range {
            if let w = minColumnWidths[i] { minWidth += w }
            if let w = maxColumnWidths[i] { maxWidth += w }
        }
        if minWidth < minSpanWidth {
            let delta = minSpanWidth - minWidth
            for i in range {
                if let w = minColumnWidths[i] {
                    let growth = floor(delta / CGFloat(range.count))
                    minColumnWidths[i] = w + growth
                    availableWidth -= growth
                }
            }
        }
        if maxWidth < maxSpanWidth {
            let delta = maxSpanWidth - maxWidth
            for i in range {
                if let w = maxColumnWidths[i] {
                    let growth = round(delta / CGFloat(range.count))
                    maxColumnWidths[i] = w + growth
                    maxTotalWidth += growth
                }
            }
        }
    }

    // Width allocation: distribute available width across columns.
    var totalWidth = maxTotalWidth
    var finalColumnWidths: [Int: CGFloat]
    let widthToDistribute: CGFloat
    if availableWidth > 0 {
        widthToDistribute = availableWidth
        finalColumnWidths = minColumnWidths
    } else {
        widthToDistribute = maxContentWidth - maxTotalWidth
        finalColumnWidths = maxColumnWidths
    }

    if widthToDistribute > 0.0 {
        var distributedWidth = widthToDistribute
        for i in 0 ..< finalColumnWidths.count {
            var width = finalColumnWidths[i]!
            let maxWidth = maxColumnWidths[i]!
            let growth = min(round(widthToDistribute * maxWidth / maxTotalWidth), distributedWidth)
            width += growth
            distributedWidth -= growth
            finalColumnWidths[i] = width
        }
        totalWidth = contentBoundingWidth
    } else {
        totalWidth += borderWidth
    }

    // Pass 2 & 3: produce per-cell frames + sub-layouts.
    // Private struct to hold an in-progress cell before row height is known.
    struct PendingCell {
        let rowIndex: Int
        let column: Int
        let colspan: Int
        let rowspan: Int
        let cell: InstantPageTableCell
        var frame: CGRect          // height is tentative until row height resolved
        let isHeader: Bool
        let isFilled: Bool         // background fill (header or stripe)
        let subLayout: InstantPageV2Layout?
        let subLayoutContentHeight: CGFloat  // height of cell content (before padding)
    }

    var finalizedCells: [InstantPageV2TableCell] = []
    var origin = CGPoint(x: borderWidth / 2.0, y: borderWidth / 2.0)
    var totalHeight: CGFloat = 0.0
    var rowHeights: [Int: CGFloat] = [:]

    var awaitingSpanCells: [Int: [(Int, PendingCell)]] = [:]

    for i in 0 ..< rows.count {
        let row = rows[i]
        var maxRowHeight: CGFloat = 0.0
        var isEmptyRow = true
        origin.x = borderWidth / 2.0

        var k: Int = 0
        var rowCells: [PendingCell] = []

        for cell in row.cells {
            // Skip columns occupied by row spans.
            if let cells = awaitingSpanCells[i] {
                for colAndCell in cells {
                    if colAndCell.1.column == k {
                        for j in 0 ..< colAndCell.1.colspan {
                            if let width = finalColumnWidths[k + j] {
                                origin.x += width
                            }
                        }
                        k += colAndCell.1.colspan
                    } else {
                        break
                    }
                }
            }

            let colspan: Int = cell.colspan > 1 ? Int(clamping: cell.colspan) : 1
            let rowspan: Int = cell.rowspan > 1 ? Int(clamping: cell.rowspan) : 1

            var cellWidth: CGFloat = 0.0
            for j in 0 ..< colspan {
                if let width = finalColumnWidths[k + j] {
                    cellWidth += width
                }
            }

            // Build cell sub-layout via recursive layoutBlockSequence.
            var subLayout: InstantPageV2Layout?
            var subLayoutHeight: CGFloat = 0.0
            if let cellText = cell.text {
                let cellContentWidth = cellWidth - totalCellPadding
                if cellContentWidth > 0.0 {
                    let cellLayout = layoutBlockSequence(
                        [.paragraph(cellText)],
                        boundingWidth: cellContentWidth,
                        horizontalInset: 0.0,
                        kind: .cell,
                        context: &context
                    )
                    stampMarkdownContext(cellLayout.items, kind: .tableCell(row: i, column: k, isHeader: cell.header))
                    subLayout = cellLayout
                    subLayoutHeight = cellLayout.contentSize.height
                    isEmptyRow = false
                }
            }

            var cellHeight: CGFloat?
            if subLayout != nil {
                cellHeight = ceil(subLayoutHeight) + v2TableCellInsets.top + v2TableCellInsets.bottom
            }

            var isFilled = cell.header
            if !isFilled && striped {
                isFilled = i % 2 == 0
            }

            let pendingCell = PendingCell(
                rowIndex: i,
                column: k,
                colspan: colspan,
                rowspan: rowspan,
                cell: cell,
                frame: CGRect(x: origin.x, y: origin.y, width: cellWidth, height: cellHeight ?? 20.0),
                isHeader: cell.header,
                isFilled: isFilled,
                subLayout: subLayout,
                subLayoutContentHeight: subLayoutHeight
            )

            if rowspan == 1 {
                rowCells.append(pendingCell)
                if let ch = cellHeight {
                    maxRowHeight = max(maxRowHeight, ch)
                }
            } else {
                for j in i ..< i + rowspan {
                    if awaitingSpanCells[j] == nil {
                        awaitingSpanCells[j] = [(k, pendingCell)]
                    } else {
                        awaitingSpanCells[j]!.append((k, pendingCell))
                    }
                }
            }

            k += colspan
            origin.x += cellWidth
        }

        // Capture theme color value before the closure to avoid capturing `inout context`.
        let tableHeaderColor = context.theme.tableHeaderColor

        // Helper: finalize a pending cell with known row height → produce InstantPageV2TableCell.
        let finalizeCell: (PendingCell, CGFloat) -> InstantPageV2TableCell = { pending, height in
            let finalFrame = CGRect(x: pending.frame.minX, y: pending.frame.minY,
                                    width: pending.frame.width, height: height)

            // Compute sub-layout frame within the cell (horizontal inset + vertical alignment).
            var subLayout = pending.subLayout
            if var sl = subLayout {
                let textHeight = pending.subLayoutContentHeight
                let vertOffset: CGFloat
                switch pending.cell.verticalAlignment {
                case .top:
                    vertOffset = v2TableCellInsets.top
                case .middle:
                    vertOffset = max(v2TableCellInsets.top, (height - textHeight) / 2.0)
                case .bottom:
                    vertOffset = max(v2TableCellInsets.top, height - textHeight - v2TableCellInsets.bottom)
                }
                let horizOffset: CGFloat
                switch pending.cell.alignment {
                case .left:
                    horizOffset = v2TableCellInsets.left
                case .center:
                    horizOffset = (pending.frame.width - sl.contentSize.width) / 2.0
                case .right:
                    horizOffset = pending.frame.width - sl.contentSize.width - v2TableCellInsets.right
                }
                // Translate all items in the sub-layout by the inset.
                let delta = CGPoint(x: horizOffset, y: vertOffset)
                let translatedItems = sl.items.map { $0.offsetBy(delta) }
                sl = InstantPageV2Layout(contentSize: sl.contentSize, items: translatedItems, detailsIndices: sl.detailsIndices, media: sl.media, webpage: sl.webpage)
                subLayout = sl
            }

            let bgColor: UIColor? = pending.isFilled ? tableHeaderColor : nil
            let hAlign: NSTextAlignment
            switch pending.cell.alignment {
            case .left: hAlign = .left
            case .center: hAlign = .center
            case .right: hAlign = .right
            }
            let vAlign: InstantPageV2TableVerticalAlignment
            switch pending.cell.verticalAlignment {
            case .top: vAlign = .top
            case .middle: vAlign = .middle
            case .bottom: vAlign = .bottom
            }

            return InstantPageV2TableCell(
                frame: finalFrame,
                isHeader: pending.isHeader,
                horizontalAlignment: hAlign,
                verticalAlignment: vAlign,
                backgroundColor: bgColor,
                subLayout: subLayout
            )
        }

        if !isEmptyRow {
            rowHeights[i] = maxRowHeight
        } else {
            rowHeights[i] = 0.0
            maxRowHeight = 0.0
        }

        // Resolve any row-spanning cells whose bottom row is now known.
        var completedSpans = [Int: Set<Int>]()
        if let cells = awaitingSpanCells[i] {
            isEmptyRow = false
            for colAndCell in cells {
                let pending = colAndCell.1
                let utmostRow = pending.rowIndex + pending.rowspan - 1
                if rowHeights[utmostRow] == nil {
                    continue
                }

                var cellHeight: CGFloat = 0.0
                for k in pending.rowIndex ..< utmostRow + 1 {
                    if let h = rowHeights[k] { cellHeight += h }
                    if completedSpans[k] == nil {
                        completedSpans[k] = Set([colAndCell.0])
                    } else {
                        completedSpans[k]!.insert(colAndCell.0)
                    }
                }

                if pending.frame.height > cellHeight {
                    let delta = pending.frame.height - cellHeight
                    cellHeight = pending.frame.height
                    maxRowHeight += delta
                    rowHeights[i] = maxRowHeight
                }

                finalizedCells.append(finalizeCell(pending, cellHeight))
            }
        }

        for pending in rowCells {
            finalizedCells.append(finalizeCell(pending, maxRowHeight))
        }

        // Remove completed span cells from awaitingSpanCells.
        if !completedSpans.isEmpty {
            awaitingSpanCells = awaitingSpanCells.reduce([Int: [(Int, PendingCell)]]()) { current, rowAndValue in
                var result = current
                let cells = rowAndValue.value.filter { column, _ in
                    if let completedSet = completedSpans[rowAndValue.key] {
                        return !completedSet.contains(column)
                    }
                    return true
                }
                if !cells.isEmpty { result[rowAndValue.key] = cells }
                return result
            }
        }

        if !isEmptyRow {
            totalHeight += maxRowHeight
            origin.y += maxRowHeight
        }
    }
    totalHeight += borderWidth

    // RTL: flip all cell frames horizontally within totalWidth.
    if context.rtl {
        finalizedCells = finalizedCells.map { cell in
            let flippedX = totalWidth - cell.frame.minX - cell.frame.width
            let flippedFrame = CGRect(x: flippedX, y: cell.frame.minY,
                                      width: cell.frame.width, height: cell.frame.height)
            return InstantPageV2TableCell(
                frame: flippedFrame,
                isHeader: cell.isHeader,
                horizontalAlignment: cell.horizontalAlignment,
                verticalAlignment: cell.verticalAlignment,
                backgroundColor: cell.backgroundColor,
                subLayout: cell.subLayout
            )
        }
    }

    // Build border lines (table-local coords).
    var horizontalLines: [CGRect] = []
    var verticalLines: [CGRect] = []
    if bordered {
        // Interior lines: for each cell, emit a top line if not in the first row,
        // and a left line if not in the first column.
        for cell in finalizedCells {
            let isFirstRow = cell.frame.minY <= borderWidth / 2.0 + 0.5
            let isFirstCol = cell.frame.minX <= borderWidth / 2.0 + 0.5
            if !isFirstRow {
                horizontalLines.append(CGRect(x: cell.frame.minX, y: cell.frame.minY,
                                              width: cell.frame.width, height: borderWidth))
            }
            if !isFirstCol {
                verticalLines.append(CGRect(x: cell.frame.minX, y: cell.frame.minY,
                                            width: borderWidth, height: cell.frame.height))
            }
        }
    }

    // Title sub-layout (above the grid).
    var titleSubLayout: InstantPageV2Layout?
    var titleFrame: CGRect?
    if case .empty = title {
        // no title
    } else {
        let titleLayout = layoutBlockSequence(
            [.paragraph(title)],
            boundingWidth: totalWidth - v2TableCellInsets.left * 2.0,
            horizontalInset: 0.0,
            kind: .cell,
            context: &context
        )
        titleSubLayout = titleLayout
        let titleHeight = titleLayout.contentSize.height + v2TableCellInsets.top + v2TableCellInsets.bottom
        titleFrame = CGRect(x: 0.0, y: 0.0, width: totalWidth, height: titleHeight)
    }

    // The table item frame spans the full visible bubble interior (`boundingWidth`); the scroll
    // viewport equals what is actually visible. contentSize.width is the intrinsic grid width
    // (may exceed frame.width → horizontal scroll); the renderer adds the inset on both sides.
    let tableFrame = CGRect(x: 0.0, y: 0.0,
                            width: boundingWidth,
                            height: totalHeight + (titleFrame?.height ?? 0.0))
    let contentSize = CGSize(
        width: totalWidth,
        height: totalHeight + (titleFrame?.height ?? 0.0)
    )

    let tableItem = InstantPageV2TableItem(
        frame: tableFrame,
        titleSubLayout: titleSubLayout,
        titleFrame: titleFrame,
        contentSize: contentSize,
        contentInset: horizontalInset,
        cells: finalizedCells,
        horizontalLines: horizontalLines,
        verticalLines: verticalLines,
        bordered: bordered,
        striped: striped,
        borderColor: context.theme.tableBorderColor
    )
    return [.table(tableItem)]
}

// MARK: - Media placeholder layout

/// Caption+credit sub-helper. Items are positioned in block-global coordinates (y measured from the
/// top of the media block); `offset` is the y-position of the bottom of the placeholder, so
/// caption items start at `offset + topPadding`. The caller uses the returned total height to
/// compute block size. Returns (items, totalHeight).
private func layoutCaptionAndCredit(
    _ caption: InstantPageCaption,
    offset: CGFloat,
    boundingWidth: CGFloat,
    horizontalInset: CGFloat,
    context: inout LayoutContext
) -> ([InstantPageV2LaidOutItem], CGFloat) {
    var items: [InstantPageV2LaidOutItem] = []
    var y = offset
    var totalHeight: CGFloat = 0.0
    var rtl = context.rtl
    var captionIsEmpty = true

    if case .empty = caption.text {
        // no caption text
    } else {
        captionIsEmpty = false
        totalHeight += 14.0
        y += 14.0
        let styleStack = InstantPageTextStyleStack()
        setupStyleStack(styleStack, theme: context.theme, category: .caption, link: false)
        let attributedString = attributedStringForRichText(caption.text, styleStack: styleStack, formatDate: context.formatDate)
        let (textItem, captionItems, captionSize) = layoutTextItem(
            attributedString,
            boundingWidth: boundingWidth - horizontalInset * 2.0,
            offset: CGPoint(x: horizontalInset, y: y),
            fitToWidth: context.fitToWidth,
            computeRevealCharacterRects: context.computeRevealCharacterRects
        )
        totalHeight += captionSize.height
        y += captionSize.height
        items.append(contentsOf: captionItems)
        rtl = textItem?.containsRTL ?? rtl
    }

    if case .empty = caption.credit {
        // no credit text
    } else {
        if captionIsEmpty {
            totalHeight += 14.0
            y += 14.0
        } else {
            totalHeight += 10.0
            y += 10.0
        }
        let styleStack = InstantPageTextStyleStack()
        setupStyleStack(styleStack, theme: context.theme, category: .credit, link: false)
        let attributedString = attributedStringForRichText(caption.credit, styleStack: styleStack, formatDate: context.formatDate)
        let (_, creditItems, creditSize) = layoutTextItem(
            attributedString,
            boundingWidth: boundingWidth - horizontalInset * 2.0,
            alignment: rtl ? .right : .natural,
            offset: CGPoint(x: horizontalInset, y: y),
            fitToWidth: context.fitToWidth,
            computeRevealCharacterRects: context.computeRevealCharacterRects
        )
        totalHeight += creditSize.height
        items.append(contentsOf: creditItems)
    }

    return (items, totalHeight)
}

// How many points a full-width flush media item bleeds past the bubble interior on the
// trailing edge so the rounded `containerNode` clip (see ChatMessageRichDataBubbleContentNode) rounds
// the trailing corners with no 1px background sliver. Harmless: the
// `contentSize.width = min(maxX, boundingWidth)` clamp keeps it from widening the bubble.
private let instantPageV2MediaEdgeBleed: CGFloat = 4.0

// Computes the laid-out frame for a block-media item.
//
// `flush == true` (every current caller): the media is edge-to-edge (x = 0, full
// `boundingWidth`) with corner radius forced to 0, relying on the bubble's rounded clipping
// container to round media that meets the bubble's top/bottom edge. A media item that fills the
// full width is widened by `instantPageV2MediaEdgeBleed` on the trailing edge (see the constant).
// A media item narrower than the full width (a small image — NOT upscaled, the `min(_, 1.0)`
// scale cap is kept) stays at its natural size, flush-left at x = 0, with no bleed.
// (The `cornerRadius` argument is ignored when `flush == true` — flush media is always
// un-rounded; callers may still pass their legacy radius, it has no effect.)
//
// `flush == false`: DEAD as of the V2 audio port — audio was its last caller and now has its
// own `layoutAudio` arm (in `layoutBlock`), so this branch is currently unreachable (follow-up:
// drop the `flush` parameter and this branch). Legacy behavior was: inset by `horizontalInset`
// on each side with the caller-supplied corner radius.
//
// Returns the frame, the un-bled scaled content size (the caption is offset by
// `scaledSize.height`), and the effective corner radius to stamp on the item.
private func instantPageV2MediaFrame(
    naturalSize: CGSize,
    flush: Bool,
    cornerRadius: CGFloat,
    boundingWidth: CGFloat,
    horizontalInset: CGFloat
) -> (frame: CGRect, scaledSize: CGSize, cornerRadius: CGFloat) {
    let availableWidth = flush ? boundingWidth : (boundingWidth - horizontalInset * 2.0)
    let scaledSize: CGSize
    if naturalSize.width > 0.0 && naturalSize.height > 0.0 {
        let scale = min(availableWidth / naturalSize.width, 1.0)
        scaledSize = CGSize(width: floor(naturalSize.width * scale), height: floor(naturalSize.height * scale))
    } else {
        scaledSize = CGSize(width: availableWidth, height: naturalSize.height)
    }

    if flush {
        // `floor(x) > x - 1` always, so a full-width item (scaledSize.width == floor(availableWidth))
        // always trips this; a genuinely smaller image does not. (availableWidth == boundingWidth
        // in the flush branch, so the bleed below extends past the full bounding width.)
        let fillsWidth = scaledSize.width >= availableWidth - 1.0
        let frameWidth = fillsWidth ? boundingWidth + instantPageV2MediaEdgeBleed : scaledSize.width
        let frame = CGRect(x: 0.0, y: 0.0, width: frameWidth, height: scaledSize.height)
        return (frame, scaledSize, 0.0)
    } else {
        let frame = CGRect(x: horizontalInset, y: 0.0, width: scaledSize.width, height: scaledSize.height)
        return (frame, scaledSize, cornerRadius)
    }
}

/// Variant of `layoutMediaWithCaption` that emits a caller-produced typed media item
/// instead of a `.mediaPlaceholder`. The frame-fitting logic + caption/credit text item
/// layout is otherwise identical.
private func layoutTypedMediaWithCaption(
    produceItem: (CGRect, CGFloat) -> InstantPageV2LaidOutItem,
    naturalSize: CGSize,
    caption: InstantPageCaption,
    isCover: Bool,
    cornerRadius: CGFloat,
    flush: Bool,
    boundingWidth: CGFloat,
    horizontalInset: CGFloat,
    context: inout LayoutContext
) -> [InstantPageV2LaidOutItem] {
    let (mediaFrame, scaledSize, effectiveCornerRadius) = instantPageV2MediaFrame(
        naturalSize: naturalSize,
        flush: flush,
        cornerRadius: cornerRadius,
        boundingWidth: boundingWidth,
        horizontalInset: horizontalInset
    )
    var result: [InstantPageV2LaidOutItem] = [produceItem(mediaFrame, effectiveCornerRadius)]

    let (captionItems, captionHeight) = layoutCaptionAndCredit(
        caption,
        offset: scaledSize.height,
        boundingWidth: boundingWidth,
        horizontalInset: horizontalInset,
        context: &context
    )
    result.append(contentsOf: captionItems)

    // Same cover-padding logic as layoutMediaWithCaption: extend the last text item's frame by
    // 14pt when isCover && captionHeight > 0.0.
    if isCover && captionHeight > 0.0 {
        if let lastIndex = result.lastIndex(where: { if case .text = $0 { return true } else { return false } }) {
            if case var .text(lastText) = result[lastIndex] {
                lastText.frame = CGRect(
                    origin: lastText.frame.origin,
                    size: CGSize(width: lastText.frame.width, height: lastText.frame.height + 14.0)
                )
                result[lastIndex] = .text(lastText)
            }
        }
    }

    return result
}

/// Lays out an `InstantPageBlock.collage(items:caption:)`. Mirrors V1
/// (InstantPageLayout.swift:692-727): compute a mosaic over the inner image/video sizes, then emit
/// one existing typed media item per cell at its mosaic frame, flush (cornerRadius 0) so the bubble's
/// rounded clip handles the outer corners and the 1pt mosaic spacing handles the interior gaps. A
/// single caption renders below the whole mosaic. Cells are top-level `.mediaImage`/`.mediaVideo`
/// items, so gallery / reveal / registry / hidden-media all work with no extra code.
private func layoutCollage(
    items innerBlocks: [InstantPageBlock],
    caption: InstantPageCaption,
    isCover: Bool,
    boundingWidth: CGFloat,
    horizontalInset: CGFloat,
    context: inout LayoutContext
) -> [InstantPageV2LaidOutItem] {
    // 1. One size per inner block (zero for unresolved — V1 still reserves a mosaic slot).
    var itemSizes: [CGSize] = []
    for block in innerBlocks {
        switch block {
        case let .image(id, _, _, _):
            if case let .image(image) = context.media[id], let largest = largestImageRepresentation(image.representations) {
                itemSizes.append(CGSize(width: CGFloat(largest.dimensions.width), height: CGFloat(largest.dimensions.height)))
            } else {
                itemSizes.append(CGSize())
            }
        case let .video(id, _, _, _):
            if case let .file(file) = context.media[id], let dimensions = file.dimensions {
                itemSizes.append(CGSize(width: CGFloat(dimensions.width), height: CGFloat(dimensions.height)))
            } else {
                itemSizes.append(CGSize())
            }
        default:
            itemSizes.append(CGSize())
        }
    }

    // 2. Mosaic geometry — the same engine V1 uses.
    let (mosaic, mosaicSize) = chatMessageBubbleMosaicLayout(maxSize: CGSize(width: boundingWidth, height: boundingWidth), itemSizes: itemSizes)

    // 3. One typed media item per resolvable cell, at its mosaic frame.
    var result: [InstantPageV2LaidOutItem] = []
    let webpage = context.webpage
    for (i, block) in innerBlocks.enumerated() {
        guard i < mosaic.count else { break }
        let (cellFrame, position) = mosaic[i]
        // Right-edge cells bleed 4pt so the bubble's rounded clip leaves no trailing sliver.
        var frame = cellFrame
        if position.contains(.right) {
            frame.size.width += instantPageV2MediaEdgeBleed
        }
        switch block {
        case let .image(id, blockCaption, url, webpageId):
            guard case let .image(image) = context.media[id] else { continue }
            let mediaIndex = context.mediaIndexCounter
            context.mediaIndexCounter += 1
            let mediaUrl: InstantPageUrlItem? = url.flatMap { InstantPageUrlItem(url: $0, webpageId: webpageId) }
            let media = InstantPageMedia(index: mediaIndex, media: .image(image), url: mediaUrl, caption: blockCaption.text, credit: blockCaption.credit)
            result.append(.mediaImage(InstantPageV2MediaImageItem(frame: frame, cornerRadius: 0.0, media: media, webPage: webpage, attributes: [])))
        case let .video(id, blockCaption, _, _):
            guard case let .file(file) = context.media[id] else { continue }
            let mediaIndex = context.mediaIndexCounter
            context.mediaIndexCounter += 1
            let media = InstantPageMedia(index: mediaIndex, media: .file(file), url: nil, caption: blockCaption.text, credit: blockCaption.credit)
            result.append(.mediaVideo(InstantPageV2MediaVideoItem(frame: frame, cornerRadius: 0.0, media: media, webPage: webpage, attributes: [])))
        default:
            continue
        }
    }

    // 4. Caption below the mosaic.
    let (captionItems, captionHeight) = layoutCaptionAndCredit(caption, offset: mosaicSize.height, boundingWidth: boundingWidth, horizontalInset: horizontalInset, context: &context)
    result.append(contentsOf: captionItems)

    // Cover-caption padding parity with layoutTypedMediaWithCaption.
    if isCover && captionHeight > 0.0 {
        if let lastIndex = result.lastIndex(where: { if case .text = $0 { return true } else { return false } }) {
            if case var .text(lastText) = result[lastIndex] {
                lastText.frame = CGRect(origin: lastText.frame.origin, size: CGSize(width: lastText.frame.width, height: lastText.frame.height + 14.0))
                result[lastIndex] = .text(lastText)
            }
        }
    }

    return result
}

/// Lays out an `InstantPageBlock.slideshow(items:caption:)`. Mirrors V1
/// (InstantPageLayout.swift:809-843): collect the inner image medias, size the block to the tallest
/// image fitted into the bounding width (cap 1200), emit a single full-width slideshow carousel item,
/// caption below. Only `.image` inner blocks contribute (matches V1).
private func layoutSlideshow(
    items innerBlocks: [InstantPageBlock],
    caption: InstantPageCaption,
    boundingWidth: CGFloat,
    horizontalInset: CGFloat,
    context: inout LayoutContext
) -> [InstantPageV2LaidOutItem] {
    var medias: [InstantPageMedia] = []
    var height: CGFloat = 0.0
    for block in innerBlocks {
        switch block {
        case let .image(id, blockCaption, url, webpageId):
            if case let .image(image) = context.media[id], let imageSize = largestImageRepresentation(image.representations)?.dimensions {
                let mediaIndex = context.mediaIndexCounter
                context.mediaIndexCounter += 1
                let filledSize = imageSize.cgSize.fitted(CGSize(width: boundingWidth, height: 1200.0))
                height = max(height, filledSize.height)
                let mediaUrl: InstantPageUrlItem? = url.flatMap { InstantPageUrlItem(url: $0, webpageId: webpageId) }
                medias.append(InstantPageMedia(index: mediaIndex, media: .image(image), url: mediaUrl, caption: blockCaption.text, credit: blockCaption.credit))
            }
        default:
            break
        }
    }

    var result: [InstantPageV2LaidOutItem] = []
    result.append(.slideshow(InstantPageV2SlideshowItem(
        frame: CGRect(x: 0.0, y: 0.0, width: boundingWidth, height: height),
        medias: medias,
        webPage: context.webpage
    )))

    let (captionItems, _) = layoutCaptionAndCredit(caption, offset: height, boundingWidth: boundingWidth, horizontalInset: horizontalInset, context: &context)
    result.append(contentsOf: captionItems)
    return result
}

private func layoutMediaWithCaption(
    kind: InstantPageV2MediaPlaceholderKind,
    naturalSize: CGSize,
    caption: InstantPageCaption,
    isCover: Bool,
    cornerRadius: CGFloat,
    flush: Bool,
    boundingWidth: CGFloat,
    horizontalInset: CGFloat,
    context: inout LayoutContext
) -> [InstantPageV2LaidOutItem] {
    let (placeholderFrame, scaledSize, effectiveCornerRadius) = instantPageV2MediaFrame(
        naturalSize: naturalSize,
        flush: flush,
        cornerRadius: cornerRadius,
        boundingWidth: boundingWidth,
        horizontalInset: horizontalInset
    )
    let placeholderItem = InstantPageV2MediaPlaceholderItem(
        frame: placeholderFrame,
        kind: kind,
        cornerRadius: effectiveCornerRadius
    )

    var result: [InstantPageV2LaidOutItem] = [.mediaPlaceholder(placeholderItem)]

    let (captionItems, captionHeight) = layoutCaptionAndCredit(
        caption,
        offset: scaledSize.height,
        boundingWidth: boundingWidth,
        horizontalInset: horizontalInset,
        context: &context
    )
    result.append(contentsOf: captionItems)

    // isCover adds extra 14pt bottom padding — but only when caption/credit text was actually
    // rendered (matches V1 lines 204-206: `contentSize.height > 0 && isCover`). For an
    // empty-caption cover image no padding is added.
    // Implemented by extending the last text item's frame rather than emitting an invisible shape
    // view that would silently consume tap area.
    if isCover && captionHeight > 0.0 {
        if let lastIndex = result.lastIndex(where: { if case .text = $0 { return true } else { return false } }) {
            if case var .text(lastText) = result[lastIndex] {
                lastText.frame = CGRect(
                    origin: lastText.frame.origin,
                    size: CGSize(width: lastText.frame.width, height: lastText.frame.height + 14.0)
                )
                result[lastIndex] = .text(lastText)
            }
        }
    }

    return result
}

// MARK: - Simple-block layout functions

private func layoutSimpleText(
    _ text: RichText,
    category: InstantPageTextCategoryType,
    boundingWidth: CGFloat,
    horizontalInset: CGFloat,
    context: inout LayoutContext
) -> [InstantPageV2LaidOutItem] {
    let styleStack = InstantPageTextStyleStack()
    setupStyleStack(styleStack, theme: context.theme, category: category, link: false)
    let attributedString = attributedStringForRichText(text, styleStack: styleStack, formatDate: context.formatDate)
    let (_, items, _) = layoutTextItem(
        attributedString,
        boundingWidth: boundingWidth - horizontalInset * 2.0,
        alignment: context.rtl ? .right : .natural,
        offset: CGPoint(x: horizontalInset, y: 0.0),
        fitToWidth: context.fitToWidth,
        computeRevealCharacterRects: context.computeRevealCharacterRects
    )
    return items
}

private func layoutHeading(
    _ text: RichText,
    level: Int32,
    boundingWidth: CGFloat,
    horizontalInset: CGFloat,
    context: inout LayoutContext
) -> [InstantPageV2LaidOutItem] {
    let styleStack = InstantPageTextStyleStack()
    setupStyleStack(styleStack, theme: context.theme, attributes: context.theme.headingTextAttributes(level: level, link: false))
    let attributedString = attributedStringForRichText(text, styleStack: styleStack, formatDate: context.formatDate)
    let (_, items, _) = layoutTextItem(
        attributedString,
        boundingWidth: boundingWidth - horizontalInset * 2.0,
        alignment: context.rtl ? .right : .natural,
        offset: CGPoint(x: horizontalInset, y: 0.0),
        fitToWidth: context.fitToWidth,
        computeRevealCharacterRects: context.computeRevealCharacterRects
    )
    stampMarkdownContext(items, kind: .heading(level: max(1, min(6, Int(level)))))
    return items
}

private func layoutParagraph(
    _ text: RichText,
    boundingWidth: CGFloat,
    horizontalInset: CGFloat,
    kind: BlockSequenceKind,
    previousItems: [InstantPageV2LaidOutItem],
    context: inout LayoutContext
) -> [InstantPageV2LaidOutItem] {
    let _ = previousItems

    let styleStack = InstantPageTextStyleStack()
    setupStyleStack(styleStack, theme: context.theme, category: kind == .cell ? .table : .paragraph, link: false)
    let attributedString = attributedStringForRichText(text, styleStack: styleStack, formatDate: context.formatDate)

    let (_, items, _) = layoutTextItem(
        attributedString,
        boundingWidth: boundingWidth - horizontalInset * 2.0,
        alignment: context.rtl ? .right : .natural,
        offset: CGPoint(x: horizontalInset, y: 0.0),
        fitToWidth: context.fitToWidth,
        computeRevealCharacterRects: context.computeRevealCharacterRects
    )
    return items
}

private func layoutAuthorDate(
    author: RichText,
    date: Int32,
    boundingWidth: CGFloat,
    horizontalInset: CGFloat,
    previousItems: [InstantPageV2LaidOutItem],
    context: inout LayoutContext
) -> [InstantPageV2LaidOutItem] {
    // Literal port of V1 InstantPageLayout.swift case .authorDate (lines 231–272).
    // Reads context.strings, formats date via DateFormatter with locale from localeWithStrings,
    // splices author and date into InstantPage_AuthorAndDateTitle format string.
    let styleStack = InstantPageTextStyleStack()
    setupStyleStack(styleStack, theme: context.theme, category: .caption, link: false)

    // Capture strings by value to avoid capturing inout context in an escaping closure.
    let strings = context.strings
    let stringForDate: (Int32) -> String = { d in
        let formatter = DateFormatter()
        formatter.locale = localeWithStrings(strings)
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: Date(timeIntervalSince1970: Double(d)))
    }

    var text: RichText?
    if case .empty = author {
        if date != 0 {
            text = .plain(stringForDate(date))
        }
    } else {
        if date != 0 {
            let dateText = RichText.plain(stringForDate(date))
            let formatString = context.strings.InstantPage_AuthorAndDateTitle("%1$@", "%2$@").string
            let authorRange = formatString.range(of: "%1$@")!
            let dateRange = formatString.range(of: "%2$@")!
            if authorRange.lowerBound < dateRange.lowerBound {
                let byPart = String(formatString[formatString.startIndex ..< authorRange.lowerBound])
                let middlePart = String(formatString[authorRange.upperBound ..< dateRange.lowerBound])
                let endPart = String(formatString[dateRange.upperBound...])
                text = .concat([.plain(byPart), author, .plain(middlePart), dateText, .plain(endPart)])
            } else {
                let beforePart = String(formatString[formatString.startIndex ..< dateRange.lowerBound])
                let middlePart = String(formatString[dateRange.upperBound ..< authorRange.lowerBound])
                let endPart = String(formatString[authorRange.upperBound...])
                text = .concat([.plain(beforePart), dateText, .plain(middlePart), author, .plain(endPart)])
            }
        } else {
            text = author
        }
    }

    guard let resolvedText = text else { return [] }

    var previousItemHasRTL = false
    if case let .text(prev) = previousItems.last, prev.textItem.containsRTL {
        previousItemHasRTL = true
    }
    let alignment: NSTextAlignment = (context.rtl || previousItemHasRTL) ? .right : .natural

    let (_, items, _) = layoutTextItem(
        attributedStringForRichText(resolvedText, styleStack: styleStack, formatDate: context.formatDate),
        boundingWidth: boundingWidth - horizontalInset * 2.0,
        alignment: alignment,
        offset: CGPoint(x: horizontalInset, y: 0.0),
        fitToWidth: context.fitToWidth,
        computeRevealCharacterRects: context.computeRevealCharacterRects
    )
    return items
}

private func layoutDivider(
    boundingWidth: CGFloat,
    context: LayoutContext
) -> [InstantPageV2LaidOutItem] {
    let lineWidth = floor(boundingWidth / 2.0)
    let frame = CGRect(
        x: floor((boundingWidth - lineWidth) / 2.0),
        y: 0.0,
        width: lineWidth,
        height: UIScreenPixel
    )
    return [.divider(InstantPageV2DividerItem(frame: frame, color: context.theme.separatorColor))]
}

// MARK: - Code block layout (ported from V1 InstantPageLayout.swift lines 329–351)

private func layoutCodeBlock(
    _ text: RichText,
    language: String?,
    boundingWidth: CGFloat,
    horizontalInset: CGFloat,
    context: inout LayoutContext
) -> [InstantPageV2LaidOutItem] {
    let backgroundInset: CGFloat = 15.0
    let textXOffset: CGFloat = 11.0

    let attributedString: NSAttributedString
    if let language, !language.isEmpty {
        // V1 line 333: call attributedStringForPreformattedText with language.
        attributedString = attributedStringForPreformattedText(
            text,
            language: language,
            theme: context.theme,
            cachedMessageSyntaxHighlight: context.cachedMessageSyntaxHighlight
        )
    } else {
        // V1 lines 335–338: fall back to plain paragraph style when no language.
        let styleStack = InstantPageTextStyleStack()
        setupStyleStack(styleStack, theme: context.theme, category: .codeBlock, link: false)
        attributedString = attributedStringForRichText(text, styleStack: styleStack, formatDate: context.formatDate)
    }

    // V1 line 341: text bounding width excludes horizontalInset×2 and backgroundInset×2.
    let innerWidth = boundingWidth - horizontalInset * 2.0 - backgroundInset * 2.0
    // V1 line 342: offset is (17.0, backgroundInset); V2 lays the text in block-local coords.
    let (textItem, _, textSize) = layoutTextItem(
        attributedString,
        boundingWidth: innerWidth,
        offset: CGPoint(x: 0.0, y: 0.0),
        fitToWidth: context.fitToWidth,
        opaqueBackground: true,
        computeRevealCharacterRects: context.computeRevealCharacterRects
    )
    guard let textItem = textItem else { return [] }
    textItem.markdownContext = InstantPageMarkdownBlockContext(kind: .code(language: language))

    // Position text within the block's content area.
    // V1 line 342: x=17.0, y=backgroundInset (block-local).
    textItem.frame = CGRect(
        x: textXOffset,
        y: backgroundInset,
        width: textItem.frame.width,
        height: textItem.frame.height
    )

    // Top-level (and <details>) code blocks span the full boundingWidth flush (x=0), matching V1
    // (line 348). Inside a blockquote the child inset is raised above the page inset (by
    // lineInset), so honor it here — otherwise the full-width background bleeds out under the
    // quote bar instead of insetting to the quote's content gutter like the quote's text does.
    let blockHeight = textSize.height + backgroundInset * 2.0
    let isNestedInQuote = horizontalInset > context.pageHorizontalInset
    // Inset (quote-nested) code blocks get an 8pt rounded background; flush (top-level / details)
    // ones stay square — the bubble's own rounded clip handles their edges.
    let cornerRadius: CGFloat = isNestedInQuote ? 8.0 : 0.0
    let blockFrame = CGRect(
        x: isNestedInQuote ? horizontalInset : 0.0,
        y: 0.0,
        width: isNestedInQuote ? (boundingWidth - horizontalInset * 2.0) : boundingWidth,
        height: blockHeight
    )

    return [.codeBlock(InstantPageV2CodeBlockItem(
        frame: blockFrame,
        backgroundColor: context.theme.codeBlockBackgroundColor,
        cornerRadius: cornerRadius,
        textItem: textItem,
        inset: UIEdgeInsets(top: backgroundInset, left: textXOffset, bottom: backgroundInset, right: backgroundInset)
    ))]
}

private func layoutThinking(
    _ text: RichText,
    boundingWidth: CGFloat,
    horizontalInset: CGFloat,
    context: inout LayoutContext
) -> [InstantPageV2LaidOutItem] {
    // Dimmed/secondary base color: the paragraph body color at reduced alpha. RichText keeps
    // its own bold/italic/link/inline-emoji formatting on top of this base (mirrors the old
    // hardcoded "Thinking…" header, which used the message theme's dimmed description color).
    let base = context.theme.textCategories.paragraph
    let dimmedAttributes = InstantPageTextAttributes(
        font: base.font,
        color: base.color.withAlphaComponent(0.55),
        underline: false
    )
    let styleStack = InstantPageTextStyleStack()
    setupStyleStack(styleStack, theme: context.theme, attributes: dimmedAttributes)
    let attributedString = attributedStringForRichText(text, styleStack: styleStack, formatDate: context.formatDate)

    // Mirror a normal `.text` item's sizing: lay the text out flush (offset .zero) and put the page
    // inset onto the BLOCK frame, so the `.thinking` item's frame == a `.text` item's frame
    // (`(horizontalInset, 0, textWidth, height)`) instead of a full-bleed `(0, 0, boundingWidth, …)`
    // box. The shimmer (sized to `item.frame.size`) then hugs the text rather than the whole page
    // width; the rendered text stays at the same place (`horizontalInset`) since the block carries
    // the inset.
    let (textItem, _, textSize) = layoutTextItem(
        attributedString,
        boundingWidth: boundingWidth - horizontalInset * 2.0,
        offset: CGPoint(x: 0.0, y: 0.0),
        fitToWidth: context.fitToWidth,
        computeRevealCharacterRects: context.computeRevealCharacterRects
    )
    guard let textItem = textItem else { return [] }

    let blockFrame = CGRect(x: horizontalInset, y: 0.0, width: textSize.width, height: textSize.height)
    return [.thinking(InstantPageV2ThinkingItem(frame: blockFrame, textItem: textItem))]
}

// MARK: - Block quote / pull quote layout (ported from V1 InstantPageLayout.swift lines 517–586)

private func layoutBlockQuote(
    blocks: [InstantPageBlock],
    caption: RichText,
    boundingWidth: CGFloat,
    horizontalInset: CGFloat,
    kind: BlockSequenceKind,
    isLast: Bool,
    context: inout LayoutContext
) -> [InstantPageV2LaidOutItem] {
    // Legacy single-paragraph fast path: preserve today's italicized body styling.
    if blocks.count == 1, case let .paragraph(text) = blocks[0] {
        return layoutQuoteText(text: text, caption: caption, isPull: false,
                               boundingWidth: boundingWidth, horizontalInset: horizontalInset,
                               context: &context)
    }

    let verticalInset: CGFloat = 4.0
    let lineInset: CGFloat = context.fitToWidth ? 12.0 : 20.0
    let barWidth: CGFloat = 3.0

    let innerBoundingWidth = boundingWidth - horizontalInset * 2.0 - lineInset
    let innerHorizontalInset = horizontalInset + lineInset
    // RTL: rigid-translate the child band so its gutter (lineInset) lands on the trailing edge,
    // faithfully mirroring the existing (intentionally preserved) LTR band. Width is preserved,
    // so a single x-delta moves the whole band correctly.
    let bandOffsetX: CGFloat = context.rtl ? (2.0 * horizontalInset + lineInset) : 0.0

    var result: [InstantPageV2LaidOutItem] = []
    var contentHeight: CGFloat = verticalInset

    // Fixed, compact gap between a quote's child blocks. The full page-flow spacing
    // (spacingBetweenBlocks ~27pt around quotes) is too airy when nested; the first
    // child hugs the top (only verticalInset above it).
    let childSpacing: CGFloat = 10.0
    for (i, child) in blocks.enumerated() {
        let spacing: CGFloat = i == 0 ? 0.0 : childSpacing
        let childItems = layoutBlock(
            child,
            boundingWidth: innerBoundingWidth,
            horizontalInset: innerHorizontalInset,
            kind: kind,
            isCover: false,
            previousItems: result,
            isLast: i == blocks.count - 1 && isLast,
            context: &context
        )
        let dy = contentHeight + spacing
        let offsetItems = childItems.map { $0.offsetBy(CGPoint(x: bandOffsetX, y: dy)) }
        let childMaxY = offsetItems.map { $0.frame.maxY }.max() ?? dy
        contentHeight = max(contentHeight, childMaxY)
        result.append(contentsOf: offsetItems)
    }

    // Optional caption (mirrors layoutQuoteText's caption branch).
    if case .empty = caption {
        // no caption
    } else {
        contentHeight += 14.0
        let captionStyleStack = InstantPageTextStyleStack()
        setupStyleStack(captionStyleStack, theme: context.theme, category: .caption, link: false)
        let attributedCaption = attributedStringForRichText(caption, styleStack: captionStyleStack, formatDate: context.formatDate)
        let (_, captionItems, captionSize) = layoutTextItem(
            attributedCaption,
            boundingWidth: innerBoundingWidth,
            alignment: context.rtl ? .right : .natural,
            // The caption is single-inset (band [H+lineInset, B-H]), unlike the double-inset
            // child band, so it needs its own RTL mirror delta of -lineInset (→ [H, B-H-lineInset],
            // tucked under the trailing bar) — NOT the children's bandOffsetX.
            offset: CGPoint(x: innerHorizontalInset + (context.rtl ? -lineInset : 0.0), y: contentHeight),
            fitToWidth: context.fitToWidth,
            computeRevealCharacterRects: context.computeRevealCharacterRects
        )
        result.append(contentsOf: captionItems)
        contentHeight += captionSize.height
    }

    contentHeight += verticalInset

    // Vertical bar on the leading edge (matches the blockQuote branch of layoutQuoteText).
    let bar = InstantPageV2BarItem(
        frame: CGRect(x: instantPageV2LeadingEdgeX(boundingWidth: boundingWidth, horizontalInset: horizontalInset, elementWidth: barWidth, rtl: context.rtl), y: 0.0, width: barWidth, height: contentHeight),
        color: context.theme.textCategories.paragraph.color,
        cornerRadius: barWidth / 2.0
    )
    result.append(.blockQuoteBar(bar))

    // Caption items (appended above) are also bumped to quoteDepth 1 and will render with a
    // `>` prefix. The whole-message markdown converter drops blockquote captions entirely, and
    // markdown-sent quotes carry empty captions, so this is benign.
    bumpQuoteDepth(result)
    return result
}

private func layoutQuoteText(
    text: RichText,
    caption: RichText,
    isPull: Bool,
    boundingWidth: CGFloat,
    horizontalInset: CGFloat,
    context: inout LayoutContext
) -> [InstantPageV2LaidOutItem] {
    // V1 line 518/553: verticalInset = 4.0 for both variants.
    let verticalInset: CGFloat = 4.0
    // V1 line 518: lineInset = 20.0 (blockQuote only; pullQuote uses full width).
    let lineInset: CGFloat = isPull ? 0.0 : (context.fitToWidth ? 12.0 : 20.0)

    var result: [InstantPageV2LaidOutItem] = []
    var contentHeight: CGFloat = verticalInset   // V1 line 520/554: starts at verticalInset

    // Body text style: paragraph + italic (V1 lines 524–526 / 558–560).
    let styleStack = InstantPageTextStyleStack()
    setupStyleStack(styleStack, theme: context.theme, category: .paragraph, link: false)
    styleStack.push(.italic)

    if isPull {
        // pullQuote: top horizontal rule (plan-specified; matches V1 divider geometry for caption color).
        // V1 doesn't emit shape ornaments for pullQuote, but the plan calls for them.
        // Geometry mirrors V1 divider (InstantPageLayout.swift line 362):
        //   lineWidth = boundingWidth - horizontalInset * 2.0, x = horizontalInset, h = 1.0.
        let lineWidth = boundingWidth - horizontalInset * 2.0
        let topLine = InstantPageV2ShapeItem(
            frame: CGRect(x: horizontalInset, y: contentHeight, width: lineWidth, height: 1.0),
            kind: .line(thickness: UIScreenPixel),
            color: context.theme.separatorColor
        )
        result.append(.shape(topLine))
        contentHeight += 1.0 + verticalInset   // rule + small gap before body text
    }

    // Body text (V1 line 528 / 562).
    let textBoundingWidth = boundingWidth - horizontalInset * 2.0 - lineInset
    let textX: CGFloat = instantPageV2ContentColumnX(horizontalInset: horizontalInset, gutter: lineInset, rtl: context.rtl)
    let textAlignment: NSTextAlignment = isPull ? .center : (context.rtl ? .right : .natural)

    let attributedBody = attributedStringForRichText(text, styleStack: styleStack, formatDate: context.formatDate)
    let (_, bodyItems, bodySize) = layoutTextItem(
        attributedBody,
        boundingWidth: textBoundingWidth,
        alignment: textAlignment,
        offset: CGPoint(x: textX, y: contentHeight),
        fitToWidth: context.fitToWidth,
        computeRevealCharacterRects: context.computeRevealCharacterRects
    )
    result.append(contentsOf: bodyItems)
    contentHeight += bodySize.height   // V1 line 530/567

    // Optional caption (V1 lines 533–544 / 570–583).
    if case .empty = caption {
        // no caption
    } else {
        contentHeight += 14.0   // V1 lines 535/572: 14pt gap before caption

        let captionStyleStack = InstantPageTextStyleStack()
        setupStyleStack(captionStyleStack, theme: context.theme, category: .caption, link: false)

        let attributedCaption = attributedStringForRichText(caption, styleStack: captionStyleStack, formatDate: context.formatDate)
        let (_, captionItems, captionSize) = layoutTextItem(
            attributedCaption,
            boundingWidth: textBoundingWidth,
            alignment: textAlignment,
            offset: CGPoint(x: textX, y: contentHeight),
            fitToWidth: context.fitToWidth,
            computeRevealCharacterRects: context.computeRevealCharacterRects
        )
        result.append(contentsOf: captionItems)
        contentHeight += captionSize.height   // V1 lines 542/582
    }

    contentHeight += verticalInset   // V1 lines 545/585

    if isPull {
        // pullQuote: bottom horizontal rule (plan-specified; mirrors top rule).
        let lineWidth = boundingWidth - horizontalInset * 2.0
        let bottomLine = InstantPageV2ShapeItem(
            frame: CGRect(x: horizontalInset, y: contentHeight - 1.0, width: lineWidth, height: 1.0),
            kind: .line(thickness: 1.0),
            color: context.theme.textCategories.caption.color
        )
        // Insert bottom rule before caption trailing space is consumed — append after final verticalInset.
        result.append(.shape(bottomLine))
    } else {
        // blockQuote: vertical bar on the leading edge (V1 lines 547–549).
        // V1: frame = CGRect(x: horizontalInset, y: 0.0, width: 3.0, height: contentSize.height)
        // V1 shape: .roundLine (rounded caps) → cornerRadius = barWidth / 2 = 1.5.
        let barWidth: CGFloat = 3.0   // V1 line 547
        let bar = InstantPageV2BarItem(
            frame: CGRect(x: instantPageV2LeadingEdgeX(boundingWidth: boundingWidth, horizontalInset: horizontalInset, elementWidth: barWidth, rtl: context.rtl), y: 0.0, width: barWidth, height: contentHeight),
            color: context.theme.textCategories.paragraph.color,   // V1 line 547
            cornerRadius: barWidth / 2.0   // V1 .roundLine ≈ half-width rounded caps
        )
        result.append(.blockQuoteBar(bar))
    }

    // Tag this quote's produced text items at quote depth 1 so the markdown
    // converter renders them with a `> ` prefix. Applies to BOTH block quotes
    // (single-paragraph fast path) and pull quotes — the whole-message markdown
    // converter renders both flavors as `> `. Nested quotes are lifted further
    // by the outer multi-block path's own bumpQuoteDepth(result) call.
    bumpQuoteDepth(result)

    return result
}

// MARK: - List layout (ported from V1 InstantPageLayout.swift lines 365–516)

private func layoutList(
    _ listItems: [InstantPageListItem],
    ordered: Bool,
    boundingWidth: CGFloat,
    horizontalInset: CGFloat,
    kind: BlockSequenceKind,
    context: inout LayoutContext
) -> [InstantPageV2LaidOutItem] {
    // Determine marker characteristics.
    var maxIndexWidth: CGFloat = 0.0
    // hasNums: at least one ordered item carries an explicit `num` — in which case items
    // without one fall back to a blank " " (preserves the source's numbering gaps) rather
    // than auto-generated `(i + 1).`. Unordered lists never auto-generate numbers, so this
    // flag is only meaningful when `ordered` is true. (`hasTaskMarkers` is no longer derived
    // — the uniform 8pt gap below replaced the per-list `indexSpacing` ternary that consumed
    // it; column right-alignment handles mixed bullet/checkbox lists without flagging.)
    var hasNums = false
    if ordered {
        for item in listItems {
            if item.checked == nil, let num = item.num, !num.isEmpty {
                hasNums = true
                break
            }
        }
    }

    // Build per-item marker descriptors and measure their natural widths.
    struct MarkerInfo {
        let kind: InstantPageV2ListMarkerKind
        let naturalWidth: CGFloat   // for right-aligning number markers
    }
    let checklistMarkerSize = CGSize(width: 18.0, height: 18.0)

    let checkboxColors = InstantPageV2CheckboxColors(
        background: context.theme.panelAccentColor,
        stroke: context.theme.pageBackgroundColor,
        border: context.theme.controlColor
    )
    // Track maxIndexWidth for ALL marker kinds (ordered + unordered, all three shapes), not
    // just ordered as V1/older V2 did. With every kind contributing to the marker column width
    // we can right-align every marker to a single shared column edge — so in a mixed unordered
    // list (bullets + checkboxes) both right-align flush to the same x, and the same uniform
    // gap separates them from the text. The column width simply equals the widest marker; for
    // a pure bullet list `maxIndexWidth == 6` and the bullet sits at `horizontalInset` (visually
    // identical to the pre-change formula), and for a pure checkbox list `maxIndexWidth == 18`
    // matches the previous left-aligned placement too.
    var markerInfos: [MarkerInfo] = []
    for (i, item) in listItems.enumerated() {
        if let checked = item.checked {
            maxIndexWidth = max(maxIndexWidth, checklistMarkerSize.width)
            markerInfos.append(MarkerInfo(kind: .checklist(checked: checked, colors: checkboxColors), naturalWidth: checklistMarkerSize.width))
        } else if ordered {
            let value: String
            if hasNums {
                if let num = item.num {
                    value = "\(num)."
                } else {
                    value = " "
                }
            } else {
                value = "\(i + 1)."
            }
            // Measure using a UILabel to get the expected label width.
            let styleStack = InstantPageTextStyleStack()
            setupStyleStack(styleStack, theme: context.theme, category: .paragraph, link: false)
            let attrStr = attributedStringForRichText(.plain(value), styleStack: styleStack, formatDate: context.formatDate)
            let (textItem, _, _) = layoutTextItem(
                attrStr,
                boundingWidth: boundingWidth - horizontalInset * 2.0,
                offset: .zero,
                fitToWidth: context.fitToWidth,
                computeRevealCharacterRects: context.computeRevealCharacterRects
            )
            let w: CGFloat
            if let textItem = textItem, let firstLine = textItem.lines.first {
                w = firstLine.frame.width
            } else {
                w = 0.0
            }
            maxIndexWidth = max(maxIndexWidth, w)
            markerInfos.append(MarkerInfo(kind: .number(value), naturalWidth: w))
        } else {
            // Bullet: 6×6 ellipse (matches V1 InstantPageShapeItem dimensions).
            maxIndexWidth = max(maxIndexWidth, 6.0)
            markerInfos.append(MarkerInfo(kind: .bullet, naturalWidth: 6.0))
        }
    }

    // Uniform 8pt marker→text gap across all four cases (ordered/unordered × bullet/number/
    // checkbox). With markers right-aligned to a shared column of width `maxIndexWidth`, text
    // starts at `horizontalInset + maxIndexWidth + indexSpacing` — so `indexSpacing` IS the
    // gap, regardless of marker shape. V1 used 12/16/20/24 (a mix of marker-area-width and
    // gap-after-marker, depending on alignment); the four gaps came out to 12/16/14/6 — far
    // from uniform, and a 14pt bullet gap looked especially loose. 8pt is a standard iOS list
    // gap; it tightens bullets (14→8), numbers (12→8) and ordered-checkbox (16→8), and only
    // loosens unordered-checkbox very slightly (6→8) so all four kinds match.
    let indexSpacing: CGFloat = 8.0

    // Layout each item.
    var result: [InstantPageV2LaidOutItem] = []
    var contentHeight: CGFloat = 0.0

    for (i, item) in listItems.enumerated() {
        // Inter-item spacing (matches V1: 18pt normal, 12pt fitToWidth).
        if i != 0 {
            contentHeight += context.fitToWidth ? 12.0 : 18.0
        }

        let markerInfo = markerInfos[i]

        // Effective item: if a .blocks item is empty, treat as a single space.
        var effectiveItem = item
        if case let .blocks(blocks, num, checked) = effectiveItem, blocks.isEmpty {
            effectiveItem = .text(.plain(" "), num, checked)
        }

        // Derive the markdown marker string and checked state from the original item.
        let markdownMarker: String
        switch markerInfo.kind {
        case let .number(value): markdownMarker = value
        default: markdownMarker = "-"
        }
        let markdownChecked: Bool? = item.checked

        switch effectiveItem {
        case let .text(text, _, _):
            // Layout text content.
            let styleStack = InstantPageTextStyleStack()
            setupStyleStack(styleStack, theme: context.theme, category: .paragraph, link: false)
            let attrStr = attributedStringForRichText(text, styleStack: styleStack, formatDate: context.formatDate)
            let textX = instantPageV2ContentColumnX(horizontalInset: horizontalInset, gutter: indexSpacing + maxIndexWidth, rtl: context.rtl)
            let textWidth = boundingWidth - horizontalInset * 2.0 - indexSpacing - maxIndexWidth
            let (textItem, textLaidOutItems, textSize) = layoutTextItem(
                attrStr,
                boundingWidth: textWidth,
                alignment: context.rtl ? .right : .natural,
                offset: CGPoint(x: textX, y: contentHeight),
                fitToWidth: context.fitToWidth,
                computeRevealCharacterRects: context.computeRevealCharacterRects
            )

            // Compute marker vertical position: align to mid of first text line.
            var lineMidY: CGFloat = contentHeight
            if let textItem = textItem {
                if let firstLine = textItem.lines.first {
                    lineMidY = textItem.frame.minY + firstLine.frame.midY
                } else {
                    lineMidY = textItem.frame.midY
                }
            }

            // Compute marker frame.
            let markerFrame = markerFrameFor(
                kind: markerInfo.kind,
                naturalWidth: markerInfo.naturalWidth,
                maxIndexWidth: maxIndexWidth,
                horizontalInset: horizontalInset,
                checklistMarkerSize: checklistMarkerSize,
                lineMidY: lineMidY,
                rtl: context.rtl,
                boundingWidth: boundingWidth
            )

            result.append(.listMarker(InstantPageV2ListMarkerItem(
                frame: markerFrame,
                kind: markerInfo.kind,
                color: context.theme.textCategories.paragraph.color
            )))
            stampMarkdownContext(textLaidOutItems, kind: .listItem(ordered: ordered, marker: markdownMarker, checked: markdownChecked))
            result.append(contentsOf: textLaidOutItems)
            contentHeight += textSize.height

        case let .blocks(blocks, _, _):
            // Nested block content (e.g. sub-list, paragraphs).
            var previousBlock: InstantPageBlock?
            let originY = contentHeight
            var firstBlockLineMidY: CGFloat?

            for (j, subBlock) in blocks.enumerated() {
                let subItems = layoutBlock(
                    subBlock,
                    boundingWidth: boundingWidth - horizontalInset * 2.0 - indexSpacing - maxIndexWidth,
                    horizontalInset: 0.0,
                    kind: kind,
                    isCover: false,
                    previousItems: result,
                    isLast: j == blocks.count - 1,
                    context: &context
                )
                let subLocalMaxY: CGFloat = subItems.map { $0.frame.maxY }.max() ?? 0.0
                let spacing: CGFloat = (previousBlock != nil && subLocalMaxY > 0.0) ? spacingBetweenBlocks(upper: previousBlock, lower: subBlock, fitToWidth: context.fitToWidth, kind: .list) : 0.0
                let offsetX = instantPageV2ContentColumnX(horizontalInset: horizontalInset, gutter: indexSpacing + maxIndexWidth, rtl: context.rtl)
                let offsetY = contentHeight + spacing
                let translatedItems = subItems.map { $0.offsetBy(CGPoint(x: offsetX, y: offsetY)) }

                if firstBlockLineMidY == nil {
                    // Find the mid-Y of the first text line in the first block.
                    for translated in translatedItems {
                        if case let .text(tv) = translated {
                            if let firstLine = tv.textItem.lines.first {
                                firstBlockLineMidY = tv.frame.minY + firstLine.frame.midY
                            } else {
                                firstBlockLineMidY = tv.frame.midY
                            }
                            break
                        }
                    }
                }

                // Compute block height contribution.
                // offsetY = contentHeight + spacing, so blockMaxY already accounts for spacing.
                var blockMaxY: CGFloat = offsetY
                for ti in translatedItems {
                    blockMaxY = max(blockMaxY, ti.frame.maxY)
                }

                // Nil-guard in stampMarkdownContext preserves any richer kind (e.g. .heading)
                // already stamped by a child block's own layout. So a heading nested inside a
                // .blocks list item keeps .heading, not .listItem — multi-block list items are
                // a documented best-effort case for markdown reconstruction.
                stampMarkdownContext(translatedItems, kind: .listItem(ordered: ordered, marker: markdownMarker, checked: markdownChecked))
                result.append(contentsOf: translatedItems)
                contentHeight = blockMaxY
                previousBlock = subBlock
            }

            // Mirror the .text case above (and what .checklist already does here): use the
            // first text line's midY for centering. `originY` is the sub-block's TOP, NOT a
            // line midpoint — `markerFrameFor` then subtracts `size.height / 2`, so feeding
            // `originY` placed the marker straddling the sub-block boundary, ½·marker-height
            // ABOVE the first text line. V1 hid the same arithmetic under a 6×12 shape with a
            // 3pt internal offset (matching ½·fontLineHeight for 17pt paragraph text), which
            // by coincidence equals `firstBlockLineMidY`. Using firstBlockLineMidY directly
            // makes the alignment explicit, unifies the three marker kinds, and matches the
            // .text case exactly. Fallback to `originY` when no text is in the first sub-block
            // (image-first lists are rare); mirrors the existing .checklist fallback.
            let markerLineMidY: CGFloat = firstBlockLineMidY ?? originY
            let markerFrame = markerFrameFor(
                kind: markerInfo.kind,
                naturalWidth: markerInfo.naturalWidth,
                maxIndexWidth: maxIndexWidth,
                horizontalInset: horizontalInset,
                checklistMarkerSize: checklistMarkerSize,
                lineMidY: markerLineMidY,
                rtl: context.rtl,
                boundingWidth: boundingWidth
            )

            result.append(.listMarker(InstantPageV2ListMarkerItem(
                frame: markerFrame,
                kind: markerInfo.kind,
                color: context.theme.textCategories.paragraph.color
            )))

        default:
            break
        }
    }

    return result
}

/// Computes the frame for a list marker, handling RTL and all three marker kinds.
///
/// All marker kinds are right-aligned within the shared `[horizontalInset, horizontalInset +
/// maxIndexWidth]` column (LTR) or left-aligned within the mirrored column on the right (RTL).
/// For a pure-kind list `maxIndexWidth == markerWidth`, so the marker lands at `horizontalInset`
/// exactly as before; for mixed unordered lists, bullets and checkboxes align flush at the
/// column's inner edge. Column right-alignment is the single rule across every marker shape
/// — no `ordered` / `indexSpacing` split — which is why those parameters dropped.
private func markerFrameFor(
    kind: InstantPageV2ListMarkerKind,
    naturalWidth: CGFloat,
    maxIndexWidth: CGFloat,
    horizontalInset: CGFloat,
    checklistMarkerSize: CGSize,
    lineMidY: CGFloat,
    rtl: Bool,
    boundingWidth: CGFloat
) -> CGRect {
    let size: CGSize
    switch kind {
    case .bullet:
        size = CGSize(width: 6.0, height: 6.0)
    case .number:
        size = CGSize(width: naturalWidth, height: 20.0)
    case .checklist:
        size = checklistMarkerSize
    }
    let x: CGFloat
    if rtl {
        x = boundingWidth - horizontalInset - maxIndexWidth
    } else {
        x = horizontalInset + maxIndexWidth - size.width
    }
    return CGRect(x: x, y: floorToScreenPixels(lineMidY - size.height / 2.0), width: size.width, height: size.height)
}

/// Leading/trailing geometry helpers — the single source of truth for "which side is the
/// block gutter on", gated on the page's explicit `rtl` flag. The `rtl == false` branch returns
/// the pre-existing literal so non-RTL pages are byte-identical.

/// X origin of a block's content column, given a leading gutter of width `gutter`
/// (the marker column, or the quote bar+inset band). Column width is unchanged either way.
///   LTR: content sits after the gutter        → horizontalInset + gutter
///   RTL: content sits at the inset; the gutter is mirrored onto the trailing edge → horizontalInset
func instantPageV2ContentColumnX(horizontalInset: CGFloat, gutter: CGFloat, rtl: Bool) -> CGFloat {
    return rtl ? horizontalInset : horizontalInset + gutter
}

/// X origin of a leading-edge element of width `elementWidth` (e.g. the quote bar), hugging the
/// trailing edge of the gutter band in RTL.
///   LTR: horizontalInset
///   RTL: boundingWidth - horizontalInset - elementWidth
func instantPageV2LeadingEdgeX(boundingWidth: CGFloat, horizontalInset: CGFloat, elementWidth: CGFloat, rtl: Bool) -> CGFloat {
    return rtl ? (boundingWidth - horizontalInset - elementWidth) : horizontalInset
}

// MARK: - Style helpers (ported from V1 InstantPageLayout.swift lines 32–88)

private func setupStyleStack(_ stack: InstantPageTextStyleStack, theme: InstantPageTheme, attributes: InstantPageTextAttributes) {
    stack.push(.textColor(attributes.color))
    stack.push(.markerColor(theme.markerColor))
    stack.push(.linkColor(theme.linkColor))
    stack.push(.linkMarkerColor(theme.linkHighlightColor))
    switch attributes.font.style {
    case .sans:
        stack.push(.fontSerif(false))
    case .serif:
        stack.push(.fontSerif(true))
    case .monospace:
        stack.push(.fontFixed(true))
    }
    stack.push(.fontSize(attributes.font.size))
    stack.push(.lineSpacingFactor(attributes.font.lineSpacingFactor))
    if attributes.underline {
        stack.push(.underline)
    }
}

private func setupStyleStack(_ stack: InstantPageTextStyleStack, theme: InstantPageTheme, category: InstantPageTextCategoryType, link: Bool) {
    setupStyleStack(stack, theme: theme, attributes: theme.textCategories.attributes(type: category, link: link))
}

private func instantPageFont(style: InstantPageTextAttributes, bold: Bool = false, italic: Bool = false, fixed: Bool = false) -> UIFont {
    let size = style.font.size
    if fixed {
        if bold && italic {
            return UIFont(name: "Menlo-BoldItalic", size: size) ?? Font.semiboldItalic(size)
        } else if bold {
            return UIFont(name: "Menlo-Bold", size: size) ?? Font.bold(size)
        } else if italic {
            return UIFont(name: "Menlo-Italic", size: size) ?? Font.italic(size)
        } else {
            return UIFont(name: "Menlo", size: size) ?? Font.regular(size)
        }
    }
    switch style.font.style {
    case .serif:
        if bold && italic {
            return UIFont(name: "Georgia-BoldItalic", size: size) ?? Font.semiboldItalic(size)
        } else if bold {
            return UIFont(name: "Georgia-Bold", size: size) ?? Font.bold(size)
        } else if italic {
            return UIFont(name: "Georgia-Italic", size: size) ?? Font.italic(size)
        } else {
            return UIFont(name: "Georgia", size: size) ?? Font.regular(size)
        }
    case .sans:
        if bold && italic {
            return Font.semiboldItalic(size)
        } else if bold {
            return Font.bold(size)
        } else if italic {
            return Font.italic(size)
        } else {
            return Font.regular(size)
        }
    case .monospace:
        if bold && italic {
            return Font.semiboldItalicMonospace(size)
        } else if bold {
            return Font.semiboldMonospace(size)
        } else if italic {
            return Font.italicMonospace(size)
        } else {
            return Font.monospace(size)
        }
    }
}

// MARK: - Preformatted text (ported from V1 InstantPageLayout.swift lines 91–132)

private func attributedStringForPreformattedText(_ text: RichText, language: String?, theme: InstantPageTheme, cachedMessageSyntaxHighlight: CachedMessageSyntaxHighlight?) -> NSAttributedString {
    let paragraphAttributes = theme.textCategories.attributes(type: .paragraph, link: false)
    let textValue = text.plainText
    guard !textValue.isEmpty else {
        return NSAttributedString(
            string: "",
            attributes: [
                .font: instantPageFont(style: paragraphAttributes, fixed: true),
                .foregroundColor: paragraphAttributes.color,
                NSAttributedString.Key(rawValue: InstantPageLineSpacingFactorAttribute): paragraphAttributes.font.lineSpacingFactor as NSNumber
            ]
        )
    }

    let attributedString = stringWithAppliedEntities(
        textValue,
        entities: [
            MessageTextEntity(range: 0 ..< (textValue as NSString).length, type: .Pre(language: language))
        ],
        baseColor: paragraphAttributes.color,
        linkColor: theme.linkColor,
        codeBlockTitleColor: paragraphAttributes.color,
        codeBlockAccentColor: paragraphAttributes.color,
        codeBlockBackgroundColor: theme.codeBlockBackgroundColor,
        baseFont: instantPageFont(style: paragraphAttributes),
        linkFont: instantPageFont(style: paragraphAttributes),
        boldFont: instantPageFont(style: paragraphAttributes, bold: true),
        italicFont: instantPageFont(style: paragraphAttributes, italic: true),
        boldItalicFont: instantPageFont(style: paragraphAttributes, bold: true, italic: true),
        fixedFont: instantPageFont(style: paragraphAttributes, fixed: true),
        blockQuoteFont: instantPageFont(style: paragraphAttributes),
        underlineLinks: false,
        message: nil,
        cachedMessageSyntaxHighlight: cachedMessageSyntaxHighlight
    ).mutableCopy() as! NSMutableAttributedString
    attributedString.addAttribute(
        NSAttributedString.Key(rawValue: InstantPageLineSpacingFactorAttribute),
        value: paragraphAttributes.font.lineSpacingFactor as NSNumber,
        range: NSRange(location: 0, length: attributedString.length)
    )
    return attributedString
}

// MARK: - V2 text-item layout (ported from V1 InstantPageTextItem.swift layoutTextItemWithString)
//
// V0 difference from V1:
//   * Inline image runs are NOT emitted as items here. They are discovered at view-update time
//     by `InstantPageV2View.updateInlineImages()`, which walks each text view's `line.imageItems`
//     and creates `InstantPageV2InlineImageView`s attached to the text view's `imageContainerView`
//     (the pop-in animation mirrors the inline custom-emoji ownership model).
//   * Inline formula runs produce `.formula(InstantPageV2FormulaItem(...))` items carrying the
//     rendered math image (see `InstantPageV2FormulaView`); the line's `formulaItems` field
//     already provides the attachment + frame.
//   * No `InstantPageScrollableTextItem` wrapping: even if `requiresScroll` would be true in V1,
//     V2 takes the non-scroll path (text item kept flat; long preformatted lines simply clip
//     outside the bubble width). Deferred to a future iteration.

// Internal helpers ported from V1 InstantPageTextItem.swift (declared private there; copied here).
// `internal` (not private) so that InstantPageRenderer.swift can call them from the same module.
func v2FrameForLine(_ line: InstantPageTextLine, boundingWidth: CGFloat, alignment: NSTextAlignment) -> CGRect {
    var lineFrame = line.frame
    if alignment == .center {
        lineFrame.origin.x = floor((boundingWidth - lineFrame.size.width) / 2.0)
    } else if alignment == .right || (alignment == .natural && line.isRTL) {
        lineFrame.origin.x = boundingWidth - lineFrame.size.width
    }
    return lineFrame
}

// Returns the leading-edge x offset (line-origin-relative) for an inline-attachment's string
// `range`, correct for both LTR and RTL runs. `CTLineGetOffsetForStringIndex` at the start index
// gives the glyph's LEFT edge in LTR text, but its RIGHT edge in RTL text (increasing string index
// moves leftward) — so using the start-index offset alone as the left edge shoves an RTL attachment
// ~one advance too far right. Taking the min of the start- and end-index offsets yields the true
// leading (left) edge in both directions. Mirrors `Display.TextNode`'s `addEmbeddedItem`, including
// the directional-boundary secondary-offset handling. For a pure-LTR line this returns exactly the
// start-index offset (primary == secondary, and start-offset < end-offset), so LTR layout is
// byte-identical to the previous single-offset behavior.
private func v2LeadingOffsetForRange(_ line: CTLine, range: NSRange) -> CGFloat {
    var secondaryStartOffset: CGFloat = 0.0
    let rawStartOffset = CTLineGetOffsetForStringIndex(line, range.location, &secondaryStartOffset)
    var startOffset = rawStartOffset
    if !rawStartOffset.isEqual(to: secondaryStartOffset) {
        startOffset = secondaryStartOffset
    }

    var secondaryEndOffset: CGFloat = 0.0
    let rawEndOffset = CTLineGetOffsetForStringIndex(line, range.location + range.length, &secondaryEndOffset)
    var endOffset = rawEndOffset
    if !rawEndOffset.isEqual(to: secondaryEndOffset) {
        endOffset = secondaryEndOffset
    }

    return min(startOffset, endOffset)
}

private func v2LocalAttachmentBoundsForRange(_ range: NSRange, imageItems: [InstantPageTextImageItem], formulaItems: [InstantPageTextFormulaRun]) -> CGRect? {
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

private struct PendingV2ImageAttachment {
    let xOffset: CGFloat
    let range: NSRange
    let id: Int64
    let size: CGSize
}

private struct PendingV2FormulaAttachment {
    let xOffset: CGFloat
    let range: NSRange
    let attachment: InstantPageMathAttachment
    let baselineOffset: CGFloat
}

private struct PendingV2EmojiAttachment {
    let xOffset: CGFloat
    let range: NSRange
    let emoji: ChatTextInputTextCustomEmojiAttribute
    let size: CGFloat
}

func layoutTextItem(
    _ string: NSAttributedString,
    boundingWidth: CGFloat,
    horizontalInset: CGFloat = 0.0,
    alignment: NSTextAlignment = .natural,
    offset: CGPoint,
    minimizeWidth: Bool = false,
    fitToWidth: Bool = false,
    maxNumberOfLines: Int = 0,
    opaqueBackground: Bool = false,
    computeRevealCharacterRects: Bool = false
) -> (InstantPageTextItem?, [InstantPageV2LaidOutItem], CGSize) {
    if string.length == 0 {
        return (nil, [], CGSize())
    }

    var lines: [InstantPageTextLine] = []
    var imageItems: [InstantPageTextImageItem] = []
    var hasFormulaItems: Bool = false
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
    let fontDescentBelowBaseline = max(0.0, -fontDescent)
    // True font-height line box: shift the whole line stack down by the ascender headroom above
    // the cap line (A − L) and pad the final height by the descender (D) below the last baseline,
    // so a single-line item measures exactly A + D. Exact (not pixel-snapped): this is an
    // intra-item line offset; crispness rides on the item's own pixel-snapped frame origin, and
    // intra-item line positions may already be fractional (e.g. after a non-integral extraDescent).
    // Inter-line advance is unchanged. (Named `lineBoxTopInset` to avoid colliding with the
    // formula-bleed `topInset` local near the end of this function.)
    let lineBoxTopInset = max(0.0, fontAscent - fontLineHeight)
    let baselineToNextTopSlack = max(0.0, fontLineSpacing - 4.0)

    var lastIndex: CFIndex = 0
    var currentLineOrigin = CGPoint(x: 0.0, y: lineBoxTopInset)

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
            var pendingImages: [PendingV2ImageAttachment] = []
            var pendingFormulas: [PendingV2FormulaAttachment] = []
            var lineEmojiItems: [InstantPageTextEmojiItem] = []
            var pendingEmoji: [PendingV2EmojiAttachment] = []
            var isRTL = false
            if let glyphRuns = CTLineGetGlyphRuns(line) as? [CTRun], !glyphRuns.isEmpty {
                if let run = glyphRuns.first, CTRunGetStatus(run).contains(CTRunStatus.rightToLeft) {
                    isRTL = true
                }

                for run in glyphRuns {
                    let cfRunRange = CTRunGetStringRange(run)
                    let runRange = NSMakeRange(cfRunRange.location == kCFNotFound ? NSNotFound : cfRunRange.location, cfRunRange.length)
                    string.enumerateAttributes(in: runRange, options: []) { attributes, range, _ in
                        if let id = attributes[NSAttributedString.Key.init(rawValue: InstantPageMediaIdAttribute)] as? Int64, let dimensions = attributes[NSAttributedString.Key.init(rawValue: InstantPageMediaDimensionsAttribute)] as? PixelDimensions {
                            let imageSize = dimensions.cgSize.fitted(CGSize(width: boundingWidth, height: boundingWidth))
                            let xOffset = v2LeadingOffsetForRange(line, range: range)
                            pendingImages.append(PendingV2ImageAttachment(xOffset: xOffset, range: range, id: id, size: imageSize))
                        } else if let attachment = attributes[NSAttributedString.Key(rawValue: InstantPageFormulaAttribute)] as? InstantPageMathAttachment {
                            let xOffset = v2LeadingOffsetForRange(line, range: range)
                            let baselineOffset = (attributes[NSAttributedString.Key.baselineOffset] as? CGFloat) ?? 0.0
                            pendingFormulas.append(PendingV2FormulaAttachment(xOffset: xOffset, range: range, attachment: attachment, baselineOffset: baselineOffset))
                        } else if let emoji = attributes[ChatTextInputAttributes.customEmoji] as? ChatTextInputTextCustomEmojiAttribute {
                            let xOffset = v2LeadingOffsetForRange(line, range: range)
                            let font = (attributes[NSAttributedString.Key.font] as? UIFont) ?? UIFont.systemFont(ofSize: 17.0)
                            // Size the inline emoji to the font's line height (A + D = the true
                            // line-box height) plus a 4pt bump at the 17pt body font (scaled
                            // proportionally) so it reads a touch larger than the bare line box.
                            // The line is NOT inflated (lineAscent stays fontLineHeight). Must match
                            // the run-delegate width in attributedStringForRichText (InstantPageTextItem.swift).
                            let itemSize = font.ascender - font.descender + 4.0 * font.pointSize / 17.0
                            pendingEmoji.append(PendingV2EmojiAttachment(xOffset: xOffset, range: range, emoji: emoji, size: itemSize))
                        }
                    }
                }
            }

            // Inline emoji and images do NOT inflate the line: they are centered on the font
            // line box and allowed to bleed above/below (mirroring V1 `layoutTextItemWithString`
            // and the chat `InteractiveTextComponent`). Their run delegates already report the
            // font's own ascent/descent, so CoreText lays the line out at the normal height — the
            // old `lineAscent = emoji.size` inflation both doubled the line height and (because the
            // baseline sits at the bottom of the box) shoved the text baseline down. Only formulas,
            // which carry their own typographic metrics, are allowed to grow the line.
            var lineAscent: CGFloat = fontLineHeight
            var lineDescent: CGFloat = fontDescentBelowBaseline
            for formula in pendingFormulas {
                let formulaAscent = formula.attachment.rendered.size.height - formula.attachment.rendered.descent
                if formulaAscent > lineAscent {
                    lineAscent = formulaAscent
                }
                if formula.attachment.rendered.descent > lineDescent {
                    lineDescent = formula.attachment.rendered.descent
                }
            }
            let baselineY = workingLineOrigin.y + lineAscent

            for image in pendingImages {
                // Center on the font line box (baseline − fontLineHeight/2), matching V1's
                // `(fontLineHeight - imageHeight) / 2` offset, instead of bottom-aligning on the
                // baseline. Keeps the text baseline put and lets the image bleed symmetrically.
                let imageFrame = CGRect(
                    x: workingLineOrigin.x + image.xOffset,
                    y: floorToScreenPixels(baselineY - fontLineHeight / 2.0 - image.size.height / 2.0),
                    width: image.size.width,
                    height: image.size.height
                )
                lineImageItems.append(InstantPageTextImageItem(frame: imageFrame, range: image.range, id: EngineMedia.Id(namespace: Namespaces.Media.CloudFile, id: image.id)))
            }
            for formula in pendingFormulas {
                let attachment = formula.attachment
                let formulaAscent = attachment.rendered.size.height - attachment.rendered.descent
                let formulaFrame = CGRect(
                    x: workingLineOrigin.x + formula.xOffset,
                    y: baselineY - formulaAscent + formula.baselineOffset,
                    width: attachment.rendered.size.width,
                    height: attachment.rendered.size.height
                )
                lineFormulaItems.append(InstantPageTextFormulaRun(frame: formulaFrame, range: formula.range, attachment: attachment))
            }
            for emoji in pendingEmoji {
                // Center on the font line box (baseline − fontLineHeight/2) so a 24pt emoji on a
                // ~17pt line bleeds symmetrically rather than forcing the line taller and pushing
                // the text baseline down. Matches the chat `InteractiveTextComponent` placement.
                let emojiFrame = CGRect(
                    x: workingLineOrigin.x + emoji.xOffset,
                    y: floorToScreenPixels(baselineY - fontLineHeight / 2.0 - emoji.size / 2.0),
                    width: emoji.size,
                    height: emoji.size
                )
                lineEmojiItems.append(InstantPageTextEmojiItem(frame: emojiFrame, range: emoji.range, emoji: emoji.emoji))
            }

            extraDescent = max(0.0, lineDescent - baselineToNextTopSlack)
            // A centered attachment taller than the line bleeds below the baseline; grow the
            // descent so the following line isn't overlapped (mirrors V1's extraDescent handling).
            // Emoji sized to the font line height (A + D) fit the line box, so they contribute nothing.
            for imageItem in lineImageItems {
                extraDescent = max(extraDescent, imageItem.frame.maxY - (baselineY + baselineToNextTopSlack))
            }
            for emojiItem in lineEmojiItems {
                extraDescent = max(extraDescent, emojiItem.frame.maxY - (baselineY + baselineToNextTopSlack))
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
            var spoilerItems: [InstantPageTextSpoilerItem] = []
            var anchorItems: [InstantPageTextAnchorItem] = []

            string.enumerateAttributes(in: lineRange, options: []) { attributes, range, _ in
                if let _ = attributes[NSAttributedString.Key.strikethroughStyle] {
                    let lowerX = floor(CTLineGetOffsetForStringIndex(line, range.location, nil))
                    let upperX = ceil(CTLineGetOffsetForStringIndex(line, range.location + range.length, nil))
                    let x = lowerX < upperX ? lowerX : upperX
                    strikethroughItems.append(InstantPageTextStrikethroughItem(frame: CGRect(x: workingLineOrigin.x + x, y: workingLineOrigin.y + (lineAscent - fontLineHeight), width: abs(upperX - lowerX), height: fontLineHeight)))
                }
                if let _ = attributes[NSAttributedString.Key.underlineStyle] {
                    let lowerX = floor(CTLineGetOffsetForStringIndex(line, range.location, nil))
                    let upperX = ceil(CTLineGetOffsetForStringIndex(line, range.location + range.length, nil))
                    let x = lowerX < upperX ? lowerX : upperX
                    underlineItems.append(InstantPageTextUnderlineItem(
                        frame: CGRect(x: workingLineOrigin.x + x, y: workingLineOrigin.y + (lineAscent - fontLineHeight), width: abs(upperX - lowerX), height: fontLineHeight),
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
                    markedItems.append(InstantPageTextMarkedItem(frame: CGRect(x: workingLineOrigin.x + x, y: workingLineOrigin.y + (lineAscent - fontLineHeight) + delta, width: abs(upperX - lowerX), height: lineHeight), color: color, range: range))
                }
                if attributes[NSAttributedString.Key(rawValue: TelegramTextAttributes.Spoiler)] != nil {
                    let lowerX = floor(CTLineGetOffsetForStringIndex(line, range.location, nil))
                    let upperX = ceil(CTLineGetOffsetForStringIndex(line, range.location + range.length, nil))
                    let x = lowerX < upperX ? lowerX : upperX
                    spoilerItems.append(InstantPageTextSpoilerItem(frame: CGRect(x: workingLineOrigin.x + x, y: workingLineOrigin.y + (lineAscent - fontLineHeight), width: abs(upperX - lowerX), height: fontLineHeight), range: range))
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

            let height = lineAscent
            if !markedItems.isEmpty {
                markedItems = markedItems.map { item in
                    if let attachmentBounds = v2LocalAttachmentBoundsForRange(item.range, imageItems: lineImageItems, formulaItems: lineFormulaItems) {
                        return InstantPageTextMarkedItem(frame: attachmentBounds, color: item.color, range: item.range)
                    } else {
                        return item
                    }
                }
            }
            // Per-character rects use each glyph's actual ink bounds via
            // CTFontGetBoundingRectsForGlyphs — caret-position advance-width
            // math (CTLineGetOffsetForStringIndex) is too tight for italics,
            // accented marks, and any glyph with side bearings, which causes
            // the reveal mask to visibly clip the glyph edges. Mirrors
            // InteractiveTextComponent.computeCharacterRectsForLine.
            //
            // For ligatures (one glyph for multiple chars), only the first
            // char's slot is populated; the rest stay CGRect.zero and the
            // consumer's `rect.isEmpty` guard skips them.
            let lineCharacterRects: [CGRect]?
            if computeRevealCharacterRects {
                var rects = [CGRect](repeating: CGRect.zero, count: lineRange.length)
                let glyphRuns = CTLineGetGlyphRuns(line) as NSArray
                for run in glyphRuns {
                    let run = run as! CTRun
                    let glyphCount = CTRunGetGlyphCount(run)
                    if glyphCount == 0 {
                        continue
                    }

                    var glyphs = [CGGlyph](repeating: 0, count: glyphCount)
                    CTRunGetGlyphs(run, CFRangeMake(0, glyphCount), &glyphs)

                    var positions = [CGPoint](repeating: CGPoint.zero, count: glyphCount)
                    CTRunGetPositions(run, CFRangeMake(0, glyphCount), &positions)

                    var stringIndices = [CFIndex](repeating: 0, count: glyphCount)
                    CTRunGetStringIndices(run, CFRangeMake(0, glyphCount), &stringIndices)

                    let attributes = CTRunGetAttributes(run) as NSDictionary
                    guard let font = attributes[kCTFontAttributeName] as! CTFont? else {
                        continue
                    }

                    var boundingRects = [CGRect](repeating: CGRect.zero, count: glyphCount)
                    CTFontGetBoundingRectsForGlyphs(font, .default, &glyphs, &boundingRects, glyphCount)

                    for i in 0 ..< glyphCount {
                        let charIndex = stringIndices[i] - lineRange.location
                        if charIndex >= 0 && charIndex < lineRange.length {
                            let pos = positions[i]
                            let bbox = boundingRects[i]
                            rects[charIndex] = CGRect(
                                x: pos.x + bbox.origin.x,
                                y: pos.y + bbox.origin.y,
                                width: bbox.width,
                                height: bbox.height
                            )
                        }
                    }
                }
                for emoji in pendingEmoji {
                    let localIndex = emoji.range.location - lineRange.location
                    if localIndex >= 0 && localIndex < rects.count {
                        let x = v2LeadingOffsetForRange(line, range: emoji.range)
                        // characterRects are baseline-relative (positive-up). The emoji cell is now
                        // centered on the font line box (see frame loop), so in baseline-relative
                        // coords it spans [fontLineHeight/2 − size/2, fontLineHeight/2 + size/2].
                        // Width feeds the reveal cost map; maxY feeds the reveal-mask y conversion in
                        // the renderer (lineAscent − maxY), keeping the mask tracking the centered cell.
                        rects[localIndex] = CGRect(x: x, y: fontLineHeight / 2.0 - emoji.size / 2.0, width: emoji.size, height: emoji.size)
                    }
                }
                for image in pendingImages {
                    let localIndex = image.range.location - lineRange.location
                    if localIndex >= 0 && localIndex < rects.count {
                        let x = v2LeadingOffsetForRange(line, range: image.range)
                        // Image cell is centered on the font line box (see frame loop). Baseline-relative
                        // cell spans [fontLineHeight/2 − height/2, fontLineHeight/2 + height/2]; the full
                        // width feeds the reveal cost map so the streaming cursor is charged the image's
                        // width when crossing it — same as an emoji cell.
                        rects[localIndex] = CGRect(x: x, y: fontLineHeight / 2.0 - image.size.height / 2.0, width: image.size.width, height: image.size.height)
                    }
                }
                lineCharacterRects = rects
            } else {
                lineCharacterRects = nil
            }
            let textLine = InstantPageTextLine(line: line, range: lineRange, frame: CGRect(x: workingLineOrigin.x, y: workingLineOrigin.y, width: lineWidth, height: height), strikethroughItems: strikethroughItems, underlineItems: underlineItems, markedItems: markedItems, spoilerItems: spoilerItems, imageItems: lineImageItems, formulaItems: lineFormulaItems, emojiItems: lineEmojiItems, anchorItems: anchorItems, isRTL: isRTL, characterRects: lineCharacterRects)

            lines.append(textLine)
            imageItems.append(contentsOf: lineImageItems)
            if !lineFormulaItems.isEmpty {
                hasFormulaItems = true
            }

            if lineWidth > maxLineWidth {
                maxLineWidth = lineWidth
            }

            workingLineOrigin.x = 0.0
            workingLineOrigin.y += lineAscent + fontLineSpacing + extraDescent
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
        // + fontDescentBelowBaseline: contain the last line's descender below its baseline, so
        // (with the topInset shift) a single-line item measures exactly A + D = true font height.
        height = lines.last!.frame.maxY + extraDescent + fontDescentBelowBaseline
    }

    var textWidth = boundingWidth
    // Shrinking the box to content width anchors it at the leading `offset.x`, which makes any
    // non-leading display-time alignment a no-op (the block stays pinned to the leading edge and
    // only redistributes internally). Only `.natural` is leading-anchored; `.right` (RTL text)
    // and `.center` (pull quotes) must keep the full bounding width so `v2FrameForLine` lands
    // each line at the true trailing / centered position. `.right`/`.center` reach here only via
    // RTL text and pull quotes respectively, so plain LTR `.natural` body text is unaffected.
    if fitToWidth && alignment == .natural {
        textWidth = maxLineWidth
    }
    if (!imageItems.isEmpty || hasFormulaItems) && maxLineWidth > boundingWidth + 10.0 {
        textWidth = maxLineWidth
    }

    let textItem = InstantPageTextItem(frame: CGRect(x: 0.0, y: 0.0, width: textWidth, height: height), attributedString: string, alignment: alignment, opaqueBackground: opaqueBackground, lines: lines)
    textItem.frame = textItem.frame.offsetBy(dx: offset.x, dy: offset.y)
    var items: [InstantPageV2LaidOutItem] = []
    if imageItems.isEmpty || string.length > 1 {
        items.append(.text(InstantPageV2TextItem(frame: textItem.frame, textItem: textItem)))
    }

    var topInset: CGFloat = 0.0
    var bottomInset: CGFloat = 0.0
    var additionalItems: [InstantPageV2LaidOutItem] = []
    let effectiveOffset = offset
    for line in textItem.lines {
        let lineFrame = v2FrameForLine(line, boundingWidth: boundingWidth, alignment: alignment)
        // Inline images (RichText.image) are NOT emitted as top-level items here. They are
        // discovered at view-update time by InstantPageV2View.updateInlineImages(), which
        // walks each text view's `line.imageItems` and creates an InstantPageV2InlineImageView
        // attached to the text view's imageContainerView. The pop-in animation reuses the
        // emoji-style ownership model. See the inline-image design doc:
        // docs/superpowers/specs/2026-05-28-instantpage-v2-inline-image-design.md.
        for formulaItem in line.formulaItems {
            let formulaFrame = formulaItem.frame.offsetBy(dx: lineFrame.minX + effectiveOffset.x, dy: effectiveOffset.y)
            let item = InstantPageV2FormulaItem(
                frame: formulaFrame,
                attachment: formulaItem.attachment,
                isScrollable: false,
                imageFrame: CGRect(origin: .zero, size: formulaFrame.size),
                scrollContentSize: formulaFrame.size
            )
            additionalItems.append(.formula(item))
            if formulaFrame.minY < topInset { topInset = formulaFrame.minY }
            if formulaFrame.maxY > height { bottomInset = max(bottomInset, formulaFrame.maxY - height) }
        }
    }

    let _ = topInset
    let _ = bottomInset
    items.append(contentsOf: additionalItems)

    return (textItem, items, textItem.frame.size)
}
