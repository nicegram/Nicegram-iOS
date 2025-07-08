import FeatDataSharing
import NGCore
import TelegramApi
import TelegramCore

//  MARK: - Local

extension GeoLocation {
    init(_ location: PeerGeoLocation) {
        self.init(
            address: location.address,
            latitude: location.latitude,
            longitude: location.longitude
        )
    }
    
    init?(_ location: PeerGeoLocation?) {
        guard let location else { return nil }
        self.init(location)
    }
}

//  MARK: - Api

extension GeoLocation {
    init?(_ location: Api.ChannelLocation?) {
        guard let location else { return nil }
        self.init(PeerGeoLocation(apiLocation: location))
    }
}
