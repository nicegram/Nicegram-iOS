import Foundation

public struct SpecialOffer {
    public let id: String
    public let url: URL
    public let shouldAutoshowToPremiumUser: Bool
    public let autoshowMode: AutoshowMode
    
    public init(id: String, url: URL, shouldAutoshowToPremiumUser: Bool, autoshowMode: AutoshowMode) {
        self.id = id
        self.url = url
        self.shouldAutoshowToPremiumUser = shouldAutoshowToPremiumUser
        self.autoshowMode = autoshowMode
    }
    
    public enum AutoshowMode {
        case no
        case immediately
        case delay(TimeInterval)
    }
}
