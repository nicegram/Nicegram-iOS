import NGCore
import PhoneNumberFormat

public class PhoneNumberFormatterImpl {
    public init() {}
}

extension PhoneNumberFormatterImpl: PhoneNumberFormatter {
    public func format(_ phone: String) -> String {
        formatPhoneNumber(phone)
    }
}
