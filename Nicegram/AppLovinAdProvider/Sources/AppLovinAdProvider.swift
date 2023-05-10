import AppLovinSDK
import NGAiChat
import NGCore
import NGRepoUser

@available(iOS 13.0.0, *)
public class AppLovinAdProvider: NSObject {
    
    //  MARK: - Dependencies
    
    private let ad: MARewardedAd
    private let sdk: ALSdk
    private let userRepository: UserRepository
    
    //  MARK: - Logic
    
    private var adViewId: String?
    private var showAdCompletion: ((ShowAdResult) -> Void)?
    
    //  MARK: - Lifecycle
    
    public init(apiKey: String, adUnitIdentifier: String, userRepository: UserRepository) {
        let sdk = ALSdk.shared(withKey: apiKey)!
        
        self.ad = MARewardedAd.shared(
            withAdUnitIdentifier: adUnitIdentifier,
            sdk: sdk
        )
        self.sdk = sdk
        self.userRepository = userRepository
        
        super.init()
        
        ad.delegate = self
    }
}

@available(iOS 13.0.0, *)
extension AppLovinAdProvider: AdProvider {
    public func initialize() {
        sdk.mediationProvider = "max"
        sdk.initializeSdk()
    }
    
    public func showAd() async -> ShowAdResult {
        return await withCheckedContinuation { continuation in
            self.showAd { result in
                continuation.resume(returning: result)
            }
        }
    }
}

//  MARK: - Private Functions

@available(iOS 13.0.0, *)
private extension AppLovinAdProvider {
    func showAd(completion: @escaping (ShowAdResult) -> Void) {
        self.showAdCompletion = completion
        
        if ad.isReady {
            internalShowAd()
        } else {
            ad.load()
        }
    }
    
    func internalShowAd() {
        let id = UUID().uuidString
        
        let data = CustomDataDTO(
            ad_view_id: id,
            user_token: userRepository.getCurrentUser()?.telegramToken
        )
        let dataJsonUrlEncoded: String?
        if let dataJson = try? JSONEncoder().encode(data),
           let dataJsonString = String(data: dataJson, encoding: .utf8) {
            dataJsonUrlEncoded = dataJsonString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        } else {
            dataJsonUrlEncoded = nil
        }
        
        self.adViewId = id
        self.ad.show(
            forPlacement: nil,
            customData: dataJsonUrlEncoded
        )
    }
    
    func completeSuccessfulAd() {
        guard let adViewId else {
            completeFailedAd(error: nil)
            return
        }
        self.showAdCompletion?(.success(id: adViewId))
        self.clearCachedData()
    }
    
    func completeFailedAd(error maError: MAError?) {
        let error: Error?
        if let maError {
            error = MessageError(message: maError.message)
        } else {
            error = nil
        }
        
        self.showAdCompletion?(.error(error))
        self.clearCachedData()
    }
    
    func clearCachedData() {
        self.adViewId = nil
        self.showAdCompletion = nil
    }
}

//  MARK: - MAAdDelegate

@available(iOS 13.0.0, *)
extension AppLovinAdProvider: MARewardedAdDelegate {
    public func didRewardUser(for ad: MAAd, with reward: MAReward) {
        completeSuccessfulAd()
    }
    
    public func didLoad(_ ad: MAAd) {
        internalShowAd()
    }
    
    public func didFailToLoadAd(forAdUnitIdentifier adUnitIdentifier: String, withError error: MAError) {
        completeFailedAd(error: error)
    }
    
    public func didDisplay(_ ad: MAAd) {
        // Do nothing
    }
    
    public func didHide(_ ad: MAAd) {
        // Do nothing
    }
    
    public func didClick(_ ad: MAAd) {
        // Do nothing
    }
    
    public func didFail(toDisplay ad: MAAd, withError error: MAError) {
        completeFailedAd(error: error)
    }
}

//  MARK: - Helpers

private struct CustomDataDTO: Encodable {
    let ad_view_id: String
    let user_token: String?
}


