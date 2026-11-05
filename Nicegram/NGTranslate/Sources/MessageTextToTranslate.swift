import TelegramCore

public extension EngineRawMessage {
    func textToTranslate() -> String {
        (transcribedText() ?? "")
            .appending("\n")
            .appending(text)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private extension EngineRawMessage {
    func transcribedText() -> String? {
        for attribute in attributes {
            if let attribute = attribute as? AudioTranscriptionMessageAttribute {
                return attribute.text.isEmpty ? nil : attribute.text
            }
        }
        return nil
    }
}
