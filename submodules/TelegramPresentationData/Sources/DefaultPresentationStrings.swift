import Foundation
import AppBundle

public let defaultPresentationStrings = PresentationStrings(primaryComponent: PresentationStringsComponent(languageCode: "zhcncc", localizedName: "简体中文", pluralizationRulesCode: nil, dict: NSDictionary(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "Localizable", ofType: "strings", inDirectory: nil, forLocalization: "zh-hans")!)) as! [String : String]), secondaryComponent: nil, groupingSeparator: "")

public let defaultCNPresentationStrings = PresentationStrings(primaryComponent: PresentationStringsComponent(languageCode: "zhcncc", localizedName: "简体中文", pluralizationRulesCode: nil, dict: NSDictionary(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "Localizable", ofType: "strings", inDirectory: nil, forLocalization: "zh-hans")!)) as! [String : String]), secondaryComponent: nil, groupingSeparator: "")
