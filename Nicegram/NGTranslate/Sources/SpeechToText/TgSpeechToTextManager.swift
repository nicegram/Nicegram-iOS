import FeatSpeechToText
import Speech
import Foundation
import Postbox
import SwiftSignalKit
import TelegramCore
import ConvertOpusToAAC
import NaturalLanguage
import AccountContext

@available(iOS 13.0, *)
public class TgSpeechToTextManager {
    
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
        message: Message?,
        useOpenAI: Bool
    ) async -> ConvertSpeechToTextResult {
        await withCheckedContinuation { continuation in
            let _ = (
                mediaBox.resourceData(mediaFile.resource)
                |> take(1)
                |> mapToSignal { [weak self] data -> Signal<(String?, String?), NoError> in
                    guard let self,
                          !useOpenAI,
                          let message else { return .single((data.path, nil)) }

                    return combineLatest(
                        convertOpusToAAC(sourcePath: data.path, allocateTempFile: {
                            return TempBox.shared.tempFile(fileName: "audio.m4a").path
                        }),
                        self.languageCode(from: message)
                    )
                }
            ).start { result in
                guard let path = result.0 else { return }

                let url = URL(
                    fileURLWithPath: path
                )
                                
                Task {
                    let result = await self.convertSpeechToTextUseCase(
                        url: url,
                        languageCode: result.1
                    )
                    continuation.resume(returning: result)
                }
            }
        }
    }
    
    private func languageCode(from message: Message) -> Signal<String?, NoError> {
        let messageId: MessageId
        let authorId: PeerId?
        
        if let source = message.attributes.first(where: { $0 is SourceReferenceMessageAttribute }) as? SourceReferenceMessageAttribute {
            messageId = source.messageId
            authorId = message.forwardInfo?.author?.id
        } else {
            messageId = message.id
            authorId = message.author?.id
        }
        
        return accountContext.account.postbox.transaction { transaction -> String? in
            let languageRecognizer = NLLanguageRecognizer()
            var authorProcessedTextCount = 0
            var nonAuthorStrings: [String] = []
            var nonAuthorTextCount = 0
            
            transaction.scanTopMessages(peerId: messageId.peerId, namespace: messageId.namespace, limit: 100) { message in
                let messageText = message.text
                if !messageText.isEmpty {
                    if let authorId,
                       let messageAuthorId = message.forwardInfo?.author?.id ?? message.author?.id,
                       authorId == messageAuthorId {
                        if authorProcessedTextCount < 200 {
                            languageRecognizer.processString(messageText)
                            authorProcessedTextCount += messageText.count
                            if authorProcessedTextCount >= 50 {
                                let hypotheses = languageRecognizer.languageHypotheses(withMaximum: 1)
                                if let dominant = hypotheses.first, dominant.value >= 0.95 {
                                    return false
                                }
                            }
                        }
                    } else if message.forwardInfo == nil {
                        if nonAuthorTextCount < 200 {
                            nonAuthorStrings.append(messageText)
                            nonAuthorTextCount += messageText.count
                        }
                    }
                    if authorProcessedTextCount >= 200 && nonAuthorTextCount >= 200 {
                        return false
                    }
                }
                return true
            }
            
            var hypotheses = languageRecognizer.languageHypotheses(withMaximum: 1)
            if let dominant = hypotheses.first, dominant.value >= 0.8 {
                return dominant.key.rawValue
            }

            languageRecognizer.reset()
            for string in nonAuthorStrings {
                languageRecognizer.processString(string)
            }
            
            hypotheses = languageRecognizer.languageHypotheses(withMaximum: 1)
            if let dominant = hypotheses.first, dominant.value >= 0.8 {
                return dominant.key.rawValue
            }
            
            return Bundle.main.preferredLocalizations.first ?? "en"
        }
    }

    private func speechRecognitionSupported(languageCode: String) -> Bool {
        SFSpeechRecognizer.supportedLocales().contains(where: { $0.languageCode == languageCode })
    }
}
