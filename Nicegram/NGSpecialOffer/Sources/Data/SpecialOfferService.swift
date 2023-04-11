import Foundation
import NGCore
import NGRemoteConfig

public protocol SpecialOfferService {
    func fetchMainSpecialOffer(completion: ((SpecialOffer?) -> ())?)
    func getMainSpecialOffer() -> SpecialOffer?
    func getSpecialOfferWith(id: String) -> SpecialOffer?
    func wasSpecialOfferSeen(id: String) -> Bool
    func markAsSeen(offerId: String)
}

public class SpecialOfferServiceMock: SpecialOfferService {
    public init() {}
    
    public func fetchMainSpecialOffer(completion: ((SpecialOffer?) -> ())?) {}
    public func getMainSpecialOffer() -> SpecialOffer? { nil }
    public func getSpecialOfferWith(id: String) -> SpecialOffer? { nil }
    public func wasSpecialOfferSeen(id: String) -> Bool { false }
    public func markAsSeen(offerId: String) {}
}

@available(iOS 13.0, *)
public class SpecialOfferServiceImpl {
    
    //  MARK: - Dependencies
    
    private let remoteConfig: RemoteConfigService
    
    //  MARK: - Logic
    
    @UserDefaultsValue(key: "ng_seen_special_offers", defaultValue: [])
    private var seenSpecialOfferIds: Set<String>
    
    //  MARK: - Lifecycle
    
    public init(remoteConfig: RemoteConfigService) {
        self.remoteConfig = remoteConfig
    }
}

@available(iOS 13.0, *)
extension SpecialOfferServiceImpl: SpecialOfferService {
    public func fetchMainSpecialOffer(completion: ((SpecialOffer?) -> ())?) {
        remoteConfig.fetch(SpecialOfferDto.self, byKey: Constants.specialOfferKey) { [weak self] dto in
            guard let self = self else { return }
            
            let specialOffer = self.mapDto(dto)
            completion?(specialOffer)
        }
    }
    
    public func getMainSpecialOffer() -> SpecialOffer? {
        let dto = remoteConfig.get(SpecialOfferDto.self, byKey: Constants.specialOfferKey)
        return self.mapDto(dto)
    }
    
    public func getSpecialOfferWith(id: String) -> SpecialOffer? {
        let allSpecialOffers = remoteConfig.get(
            [SpecialOfferDto].self,
            byKey: Constants.allSpecialOffersKey
        )?.compactMap { self.mapDto($0) } ?? []
        return allSpecialOffers.first(where: { $0.id == id })
    }
    
    public func wasSpecialOfferSeen(id: String) -> Bool {
        return seenSpecialOfferIds.contains(id)
    }
    
    public func markAsSeen(offerId: String) {
        seenSpecialOfferIds.insert(offerId)
    }
}

//  MARK: - Mapping

@available(iOS 13.0, *)
private extension SpecialOfferServiceImpl {
    func mapDto(_ dto: SpecialOfferDto?) -> SpecialOffer? {
        guard let dto = dto,
              let id = dto.offerId,
              let url = dto.url else {
            return nil
        }
        
        let autoshowMode: SpecialOffer.AutoshowMode
        if let timeInterval = dto.timeInterval {
            if timeInterval < 0 {
                autoshowMode = .no
            } else if timeInterval.isZero {
                autoshowMode = .immediately
            } else {
                autoshowMode = .delay(timeInterval)
            }
        } else {
            autoshowMode = .immediately
        }
        
        return SpecialOffer(
            id: String(id),
            url: url,
            shouldAutoshowToPremiumUser: dto.showToPremium ?? true,
            autoshowMode: autoshowMode
        )
    }
}

//  MARK: - DTO

private struct SpecialOfferDto: Decodable {
    let offerId: Int?
    let url: URL?
    let showToPremium: Bool?
    let timeInterval: Double?
}

//  MARK: - Constants

@available(iOS 13.0, *)
private extension SpecialOfferServiceImpl {
    struct Constants {
        static let specialOfferKey = "specialOffer"
        static let allSpecialOffersKey = "allSpecialOffers"
    }
}
