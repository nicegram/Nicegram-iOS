import FeatSpeechToText
import Speech
import Foundation
import Postbox
import SwiftSignalKit
import TelegramCore
import ConvertOpusToAAC
import AccountContext

@available(iOS 13.0, *)
public class TgSpeechToTextManager {
    public enum Source {
        case apple(Locale), openAI
    }
    
    //  MARK: - Dependencies
    
    private let convertSpeechToTextUseCase: ConvertSpeechToTextUseCase
    private let mediaBox: MediaBox
    private let accountContext: AccountContext
    
    //  MARK: - Lifecycle
    
    public init(
        accountContext: AccountContext
    ) {
        self.convertSpeechToTextUseCase = SpeechToTextContainer.shared.convertSpeechToTextUseCase()
        self.mediaBox = accountContext.account.postbox.mediaBox
        self.accountContext = accountContext
    }
}

@available(iOS 13.0, *)
public extension TgSpeechToTextManager {
    func convertSpeechToText(
        mediaFile: TelegramMediaFile,
        source: Source
    ) async -> ConvertSpeechToTextResult {
        await withCheckedContinuation { continuation in
            let _ = (
                mediaBox.resourceData(mediaFile.resource)
                |> take(1)
                |> mapToSignal { [weak self] data -> Signal<String?, NoError> in
                    guard let self,
                          case .apple = source else { return .single(data.path) }

                    return convertOpusToAAC(sourcePath: data.path, allocateTempFile: {
                        return TempBox.shared.tempFile(fileName: "audio.m4a").path
                    })
                }
            ).start { result in
                guard let path = result else { return }

                let url = URL(
                    fileURLWithPath: path
                )
                                
                Task {
                    switch source {
                    case .openAI:
                        let result = await self.convertSpeechToTextUseCase.openAISpeechToText(url: url)
                        continuation.resume(returning: result)
                    case let .apple(locale):
                        let result = await self.convertSpeechToTextUseCase.appleSpeechToText(url: url, locale: locale)
                        continuation.resume(returning: result)
                    }
                }
            }
        }
    }
}
