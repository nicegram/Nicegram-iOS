import FeatDataSharing
import NaturalLanguage

func getLanguageCode(messages: [Message]) -> String? {
    let messages = messages
        .sorted { $0.date > $1.date }
        .compactMap { $0.message }
    
    let message = messages.first { $0.count >= 16 } ?? messages.first { !$0.isEmpty }
    guard let message else { return nil }
    
    return NLLanguageRecognizer.dominantLanguage(for: message)?.rawValue
}
