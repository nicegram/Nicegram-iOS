import NGEnv
import Foundation

struct AppReviewLogin {
    static let codeURL = NGENV.app_review_login_code_url
    static let phone = NGENV.app_review_login_phone
    
    static var sendCodeDate: Date?
    static var isActive: Bool {
        sendCodeDate != nil
    }
}
