import FeatSpeechToText
import Foundation
import Postbox
import SwiftSignalKit
import TelegramCore

@available(iOS 13.0, *)
public class TgSpeechToTextManager {
    
    //  MARK: - Dependencies
    
    private let convertSpeechToTextUseCase: ConvertSpeechToTextUseCase
    private let mediaBox: MediaBox
    
    //  MARK: - Lifecycle
    
    public init(mediaBox: MediaBox) {
        self.convertSpeechToTextUseCase = SpeechToTextContainer.shared.convertSpeechToTextUseCase()
        self.mediaBox = mediaBox
    }
}

@available(iOS 13.0, *)
public extension TgSpeechToTextManager {
    func convertSpeechToText(
        mediaFile: TelegramMediaFile
    ) async -> ConvertSpeechToTextResult {
        await withCheckedContinuation { continuation in
            let _ = (mediaBox.resourceData(mediaFile.resource)
            |> take(1)).start { data in
                let url = URL(
                    fileURLWithPath: data.path
                )
                
                Task {
                    let result = await self.convertSpeechToTextUseCase(
                        url: url
                    )
                    continuation.resume(returning: result)
                }
            }
        }
    }
}
