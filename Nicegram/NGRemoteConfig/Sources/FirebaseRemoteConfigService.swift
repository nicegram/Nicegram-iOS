import FirebaseRemoteConfig

public class FirebaseRemoteConfigService {
    
    //  MARK: - Dependencies
    
    private let remoteConfig: RemoteConfig
    
    //  MARK: - Lifecycle
    
    public init(remoteConfig: RemoteConfig = .remoteConfig(), cacheDuration: TimeInterval) {
        self.remoteConfig = remoteConfig
        
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = cacheDuration
        remoteConfig.configSettings = settings
    }
    
    //  MARK: - Public Functions
    
    public func prefetch(completion: @escaping () -> Void) {
        fetchRemoteConfig(completion: completion)
    }
}

extension FirebaseRemoteConfigService: RemoteConfigService {
    public func get<T>(_: T.Type, byKey key: String) -> T? where T : Decodable {
        if T.self == String.self {
            return remoteConfig.configValue(forKey: key).stringValue as? T
        }
        
        let data = remoteConfig.configValue(forKey: key).dataValue
        
        let jsonDecoder = JSONDecoder()
        
        return (try? jsonDecoder.decode(T.self, from: data))
    }
    
    public func fetch<T>(_: T.Type, byKey key: String, completion: ((T?) -> ())?) where T : Decodable {
        fetchRemoteConfig { [weak self] in
            completion?(self?.get(T.self, byKey: key))
        }
    }
}

private extension FirebaseRemoteConfigService {
    func fetchRemoteConfig(completion: (() -> ())?) {
        self.remoteConfig.fetchAndActivate(completionHandler: { _, _ in
            completion?()
        })
    }
}
