import Foundation
import EsimPropertyWrappers
import NGRemoteConfig

public protocol SpecialOfferService {
    func fetchSpecialOffer(completion: ((SpecialOffer?) -> ())?)
    func getSpecialOffer() -> SpecialOffer?
    func wasSpecialOfferSeen(id: String) -> Bool
    func markAsSeen(offerId: String)
}

public class SpecialOfferServiceImpl {
    
    //  MARK: - Dependencies
    
    private let remoteConfig: RemoteConfigService
    
    //  MARK: - Logic
    
    @UserDefaultsWrapper(key: "ng_seen_special_offers", defaultValue: [])
    private var seenSpecialOfferIds: Set<String>
    
    //  MARK: - Lifecycle
    
    public init(remoteConfig: RemoteConfigService) {
        self.remoteConfig = remoteConfig
    }
}

extension SpecialOfferServiceImpl: SpecialOfferService {
    public func fetchSpecialOffer(completion: ((SpecialOffer?) -> ())?) {
        remoteConfig.fetch(SpecialOfferDto.self, byKey: Constants.specialOfferKey) { [weak self] dto in
            guard let self = self else { return }
            
            let specialOffer = self.mapDto(dto)
            completion?(specialOffer)
        }
    }
    
    public func getSpecialOffer() -> SpecialOffer? {
        let dto = remoteConfig.get(SpecialOfferDto.self, byKey: Constants.specialOfferKey)
        return self.mapDto(dto)
    }
    
    public func wasSpecialOfferSeen(id: String) -> Bool {
        return seenSpecialOfferIds.contains(id)
    }
    
    public func markAsSeen(offerId: String) {
        seenSpecialOfferIds.insert(offerId)
    }
}

//  MARK: - Mapping

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

private extension SpecialOfferServiceImpl {
    struct Constants {
        static let specialOfferKey = "specialOffer"
    }
}
