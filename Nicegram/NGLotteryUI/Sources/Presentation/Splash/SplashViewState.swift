import NGCore
import NGCoreUI
import Foundation

enum SplashViewState: ViewState {
    case loading
    case loaded(SplashViewLoadedState)
    case placeholder(PlaceholderState)
    
    init() {
        self = .loading
    }
}

struct SplashViewLoadedState {
    var tab: Tab = .info
    var nextDraw: NextDraw = NextDraw()
    var lastDraw: PastDraw? = nil
    var pastDraws: [PastDraw] = []
    var userActiveTickets: [UserActiveTicket] = []
    var availableUserTicketsCount: Int = 0
    var premiumSection: PremiumSectionViewState = .subscribe
    var userPastTickets: [MyTicketsViewState.PastTicket] = []
    var isLoading: Bool = false
    
    var forceShowHowToGetTicket: Bool = false
    
    enum Tab: Int {
        case info
        case myTickets
    }
    
    struct NextDraw: Identifiable {
        let id: Date
        let jackpot: Money
        let date: Date
        
        init(id: Date = Date(), jackpot: Money = Money(amount: 0, currency: .usd), date: Date = .distantFuture) {
            self.id = id
            self.jackpot = jackpot
            self.date = date
        }
    }
    
    struct PastDraw {
        let date: Date
        let winningNumbers: [Int]
        
        init(date: Date = Date(), winningNumbers: [Int] = []) {
            self.date = date
            self.winningNumbers = winningNumbers
        }
    }
    
    struct UserActiveTicket {
        let numbers: [Int]
        let date: Date
    }
}
