import Foundation
import NGLocalization

public func l(_ key: String) -> String {
    let code = ng_getTgLangCode()
    let table = "NiceLocalizable"
    
    let bundle = localizationBundle(code: code)
    
    let enBundle = localizationBundle(code: "en")
    let enString = enBundle?.localizedString(
        forKey: key,
        value: key,
        table: table
    ) ?? key
    
    return bundle?.localizedString(
        forKey: key,
        value: enString,
        table: table
    ) ?? enString
}

public func l(_ key: String, with args: CVarArg...) -> String {
    return String(format: l(key), args)
}

private func localizationBundle(
    code: String
) -> Bundle? {
    if let path = Bundle.main.path(forResource: code, ofType: "lproj") {
        Bundle(path: path)
    } else {
        nil
    }
}
