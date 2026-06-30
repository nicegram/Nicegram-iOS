import Foundation
import UIKit
import TelegramCore

enum BlockSequenceKind {
    case topLevel
    case detail
    case cell
    case list
}

func spacingBetweenBlocks(upper: InstantPageBlock?, lower: InstantPageBlock?, fitToWidth: Bool, kind: BlockSequenceKind) -> CGFloat {
    if let upper, let lower {
        switch (upper, lower) {
        case (_, .cover), (_, .channelBanner), (.details, .details), (.relatedArticles, _), (_, .anchor):
            return 0.0
        case (.divider, _), (_, .divider):
            if fitToWidth {
                return 21.0
            } else {
                return 25.0
            }
        case (_, .blockQuote), (.blockQuote, _):
            if fitToWidth {
                return 11.0
            } else {
                return 27.0
            }
        case (_, .pullQuote), (.pullQuote, _):
            if fitToWidth {
                return 14.0
            } else {
                return 27.0
            }
        case (.kicker, .title), (.cover, .title):
            return 16.0
        case (_, .title):
            return 20.0
        case (.title, .authorDate), (.subtitle, .authorDate):
            return 18.0
        case (_, .authorDate):
            return 20.0
        case (.title, .paragraph), (.authorDate, .paragraph):
            return 34.0
        case (.header, .paragraph), (.subheader, .paragraph), (.heading, .paragraph):
            if fitToWidth {
                return 14.0
            } else {
                return 25.0
            }
        case (.list, .paragraph):
            if fitToWidth {
                return 14.0
            } else {
                return 31.0
            }
        case (.paragraph, .list):
            if fitToWidth {
                return 14.0
            } else {
                return 31.0
            }
        case (.formula, .paragraph):
            return 19.0
        case (.paragraph, .paragraph):
            if fitToWidth {
                return 2.0
            } else {
                return 25.0
            }
        case (.title, .formula), (.authorDate, .formula):
            return 34.0
        case (.header, .formula), (.subheader, .formula), (.heading, .formula):
            if fitToWidth {
                return 10.0
            } else {
                return 25.0
            }
        case (.list, .formula):
            return 31.0
        case (.paragraph, .formula):
            return 19.0
        case (_, .formula):
            return 20.0
        case (.title, .list), (.authorDate, .list):
            return 34.0
        case (.header, .list), (.subheader, .list), (.heading, .list):
            return 31.0
        case (.preformatted, _), (_, .preformatted):
            if fitToWidth {
                return 12.0
            } else {
                return 19.0
            }
        case (.formula, .list):
            if fitToWidth {
                return 10.0
            } else {
                return 25.0
            }
        case (_, .list):
            if fitToWidth {
                return 10.0
            } else {
                return 25.0
            }
        case (_, .header), (_, .subheader), (_, .heading):
            return 32.0
        default:
            return 20.0
        }
    } else if let lower {
        switch lower {
        case .cover, .channelBanner, .details, .anchor:
            return 0.0
        default:
            if fitToWidth {
                switch kind {
                case .topLevel:
                    switch lower {
                    case .heading:
                        return 6.0
                    case .table:
                        return 10.0
                    default:
                        return 5.0
                    }
                case .cell:
                    return 0.0
                case .detail, .list:
                    return 4.0
                }
            } else {
                return 25.0
            }
        }
    } else if let upper {
        switch kind {
        case .topLevel:
            if case .relatedArticles = upper {
                return 0.0
            } else if case .thinking = upper {
                return 2.0
            } else {
                if fitToWidth {
                    return 5.0
                } else {
                    return 25.0
                }
            }
        case .detail, .list:
            return 16.0
        case .cell:
            return 0.0
        }
    } else {
        return 0.0
    }
}
