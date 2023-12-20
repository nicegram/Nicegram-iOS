import CoreMedia
import NGAppCache
import NGStrings
import UIKit

public struct NGRoundedVideos {
    public struct Constants {
        public static let trimSeconds = 60.0
        public static let videoSize = CGSize(
            width: 384,
            height: 384
        )
    }
}

public extension NGRoundedVideos {
    // Workaround to reduce changes in telegram code
    static var sendAsRoundedVideo = false
    
    static func calcCropRectAndScale(
        originalCropRect: CGRect
    ) -> (CGRect, CGFloat) {
        let targetSize = NGRoundedVideos.Constants.videoSize
        
        let originalAspectRatio = originalCropRect.width / originalCropRect.height
        let targetAspectRatio = targetSize.width / targetSize.height
        
        let trimmingSize: CGSize
        if originalAspectRatio < targetAspectRatio {
            trimmingSize = CGSize(
                width: originalCropRect.width,
                height: originalCropRect.width / targetAspectRatio
            )
        } else {
            trimmingSize = CGSize(
                width: originalCropRect.height * targetAspectRatio,
                height: originalCropRect.height
            )
        }
        
        let extraWidth = originalCropRect.width - trimmingSize.width
        let extraHeight = originalCropRect.height - trimmingSize.height
        
        let cropRect = CGRect(
            origin: originalCropRect.origin.applying(
                CGAffineTransform(
                    translationX: extraWidth / 2,
                    y: extraHeight / 2
                )
            ),
            size: trimmingSize
        )
        let cropScale = targetSize.width / cropRect.width
        
        return (cropRect, cropScale)
    }
    
    static func trim(range: CMTimeRange) -> [CMTimeRange] {
        let length = CMTime(
            seconds: Constants.trimSeconds,
            preferredTimescale: 60
        )
        
        var chunks: [CMTimeRange] = []
        var from = range.start
        while from < range.end {
            chunks.append(
                CMTimeRange(
                    start: from,
                    duration: length
                ).intersection(range)
            )
            from = from + length
        }
        
        return chunks
    }
}

public extension NGRoundedVideos {
    @UserDefaultsBacked(
        key: "sawRoundedVideoMoreButtonTooltip",
        defaultValue: false
    )
    static var sawMoreButtonTooltip
    
    @UserDefaultsBacked(
        key: "sawRoundedVideoSendButtonTooltip",
        defaultValue: false
    )
    static var sawSendButtonTooltip
}

public extension NGRoundedVideos {
    struct Resources {}
}
public extension NGRoundedVideos.Resources {
    static func buttonTitle() -> String {
        l("RoundedVideos.ButtonTitle")
    }
    
    static func buttonIcon() -> UIImage? {
        if #available(iOS 13.0, *) {
            UIImage(systemName: "video.circle")
        } else {
            nil
        }
    }
    
    static func moreButtonTooltip() -> String {
        l("RoundedVideos.MoreButtonTooltip")
    }
    
    static func sendButtonTooltip() -> String {
        l("RoundedVideos.SendButtonTooltip")
    }
}
