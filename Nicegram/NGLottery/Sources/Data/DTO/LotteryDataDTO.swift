import EsimApiClientDefinition
import Foundation
import NGCore

struct LotteryDataDTO: Decodable {
    private let info: InfoDTO
    
    func mapToLotteryData() -> LotteryNetworkData {
        return info.mapToLotteryData()
    }
}

private struct InfoDTO: Decodable {
    @EsimApiDate var currentDrawDate: Date
    @EsimApiDate var nextDrawDate: Date
    @EsimApiDate var currentDrawBlockedAtDate: Date
    let lastWinningTickets: [PastDrawDTO]
    let lottoPrize: Double
    let availableToGenerateCount: Int?
    let ticketsForCurrentDraw: [UserTicketDTO]?
    let ticketsDrawHistory: [UserTicketDTO]?
    @EsimApiOptionalDate var dateReceiveTicketViaSubscription: Date?
    
    struct PastDrawDTO: Decodable {
        @EsimApiDate var date: Date
        let number: TicketNumbersDTO
    }
    
    struct UserTicketDTO: Decodable {
        @EsimApiDate var date: Date
        let number: TicketNumbersDTO
    }
    
    func mapToLotteryData() -> LotteryNetworkData {
        return LotteryNetworkData(
            currentDraw: CurrentDraw(
                blockDate: currentDrawBlockedAtDate,
                date: currentDrawDate,
                jackpot: Money(amount: lottoPrize, currency: .usd)
            ),
            nextDrawDate: self.nextDrawDate,
            pastDraws: lastWinningTickets.map { dto in
                return .init(date: dto.date, winningNumbers: dto.number.numbers)
            },
            userActiveTickets: ticketsForCurrentDraw?.map { dto in
                return .init(drawDate: dto.date, numbers: dto.number.numbers)
            } ?? [],
            userAvailableTicketsCount: self.availableToGenerateCount ?? 0,
            userPastTickets: ticketsDrawHistory?.map { dto in
                return .init(drawDate: dto.date, numbers: dto.number.numbers)
            } ?? [],
            nextTicketForPremiumDate: dateReceiveTicketViaSubscription
        )
    }
}


