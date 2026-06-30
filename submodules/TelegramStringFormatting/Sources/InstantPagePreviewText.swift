import Foundation
import Postbox
import TelegramCore
import TelegramPresentationData

extension RichText {
    public func previewText(strings: PresentationStrings) -> String {
        switch self {
        case .empty:
            return ""
        case let .plain(value):
            return value
        case let .bold(value):
            return value.previewText(strings: strings)
        case let .italic(value):
            return value.previewText(strings: strings)
        case let .underline(value):
            return value.previewText(strings: strings)
        case let .strikethrough(value):
            return value.previewText(strings: strings)
        case let .fixed(value):
            return value.previewText(strings: strings)
        case let .url(value, _, _):
            return value.previewText(strings: strings)
        case let .email(value, _):
            return value.previewText(strings: strings)
        case let .concat(values):
            var result = ""
            for value in values {
                result.append(value.previewText(strings: strings))
            }
            return result
        case let .`subscript`(value):
            return value.previewText(strings: strings)
        case let .superscript(value):
            return value.previewText(strings: strings)
        case let .marked(value):
            return value.previewText(strings: strings)
        case let .phone(value, _):
            return value.previewText(strings: strings)
        case .image:
            return strings.Message_Photo
        case let .anchor(value, _):
            return value.previewText(strings: strings)
        case .formula:
            return strings.RichTextPreview_Formula
        case let .textCustomEmoji(_, alt):
            return alt
        case let .textAutoEmail(value), let .textAutoPhone(value), let .textAutoUrl(value), let .textBankCard(value), let .textBotCommand(value), let .textCashtag(value), let .textHashtag(value), let .textMention(value), let .textMentionName(value, _), let .textSpoiler(value), let .textDate(value, _, _):
            return value.previewText(strings: strings)
        }
    }
}

extension InstantPageListItem {
    public func previewText(strings: PresentationStrings, media: [MediaId: Media]) -> String {
        switch self {
        case .unknown:
            return ""
        case let .text(text, num, checked):
            let body = text.previewText(strings: strings)
            if let checked {
                return "\(checked ? "☑︎" : "☐") \(body)"
            } else if let num, !num.isEmpty {
                return "\(num). \(body)"
            } else {
                return body
            }
        case let .blocks(blocks, num, checked):
            var blocksText = ""
            for block in blocks {
                if !blocksText.isEmpty {
                    blocksText.append("\n")
                }
                blocksText.append(block.previewText(strings: strings, media: media))
            }
            if let checked {
                return "\(checked ? "☑︎" : "☐") \(blocksText)"
            } else if let num {
                return "\(num). \(blocksText)"
            } else {
                return blocksText
            }
        }
    }
}

extension InstantPageBlock {
    public func previewText(strings: PresentationStrings, media: [MediaId: Media]) -> String {
        switch self {
        case .unsupported:
            return ""
        case let .title(text):
            return text.previewText(strings: strings)
        case let .subtitle(text):
            return text.previewText(strings: strings)
        case let .authorDate(author, _):
            return author.previewText(strings: strings)
        case let .header(text):
            return text.previewText(strings: strings)
        case let .subheader(text):
            return text.previewText(strings: strings)
        case let .heading(text, _):
            return text.previewText(strings: strings)
        case .formula:
            return strings.RichTextPreview_Formula
        case let .paragraph(text):
            return text.previewText(strings: strings)
        case let .preformatted(text, _):
            return text.previewText(strings: strings)
        case let .footer(text):
            return text.previewText(strings: strings)
        case .divider:
            return "\n"
        case .anchor:
            return ""
        case let .list(items, _):
            var result = ""
            for item in items {
                if !result.isEmpty {
                    result.append("\n")
                }
                result.append(item.previewText(strings: strings, media: media))
            }
            return result
        case let .blockQuote(blocks, caption):
            let body = blocks.map { $0.previewText(strings: strings, media: media) }.joined(separator: " ")
            return body + caption.previewText(strings: strings)
        case let .pullQuote(text, caption):
            return text.previewText(strings: strings) + caption.previewText(strings: strings)
        case .image(_, _, _, _):
            return strings.Message_Photo
        case .video(_, _, _, _):
            return strings.Message_Video
        case let .audio(id, _):
            if let file = media[id] as? TelegramMediaFile, file.isVoice {
                return strings.Message_Audio
            } else {
                return strings.RichTextPreview_Music
            }
        case .cover:
            return ""
        case .webEmbed:
            return ""
        case .postEmbed:
            return ""
        case .collage:
            return ""
        case .slideshow:
            return ""
        case .channelBanner:
            return ""
        case .kicker:
            return ""
        case .thinking:
            return ""
        case .table:
            return strings.RichTextPreview_Table
        case .details:
            return ""
        case .relatedArticles:
            return ""
        case .map:
            return strings.Message_Location
        }
    }
}

extension InstantPage {
    public func previewText(strings: PresentationStrings) -> String {
        let maxLength: Int = 200
        var result = ""
        for block in self.blocks {
            if !result.isEmpty {
                result.append("\n")
            }
            result.append(block.previewText(strings: strings, media: self.media))
            if result.count > maxLength {
                break
            }
        }
        return result
    }
}
