import Foundation

func baseLanguageCode(_ code: String) -> String {
    normalizedLanguageCode(code)
        .components(separatedBy: "-")[0]
        .components(separatedBy: "_")[0]
}

func normalizedLanguageCode(_ code: String) -> String {
    let rawSuffix = "-raw"
    let unsuffixed = code.hasSuffix(rawSuffix) ? String(code.dropLast(rawSuffix.count)) : code
    return unsuffixed.lowercased()
}

// Base codes only: upstream's service matches a request to its session by base code. Apple reads the
// base code `zh` as Simplified Chinese, so a Chinese code that does not say Simplified gets none.
func onDeviceLanguageCode(_ code: String) -> String? {
    let baseCode = baseLanguageCode(code)
    guard baseCode == "zh" else {
        return baseCode
    }
    return ["zh", "zh-hans"].contains(normalizedLanguageCode(code)) ? baseCode : nil
}
