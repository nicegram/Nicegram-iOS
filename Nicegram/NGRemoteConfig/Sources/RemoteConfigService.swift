import Foundation
import NGEnv
import _NGRemoteConfig

public protocol RemoteConfigService {
    func get<T: Decodable>(_: T.Type, byKey: String) -> T?
    func fetch<T: Decodable>(_: T.Type, byKey: String, completion: ((T?) -> ())?)
}

public class RemoteConfigServiceImpl {
    
    //  MARK: - Dependencies
    
    private let remoteConfigFetchTask: RemoteConfigFetchTask
    private let firebaseRemoteConfig: FirebaseRemoteConfigService
    
    //  MARK: - Logic
    
    private var task: Any?
    
    //  MARK: - Lifecycle
    
    public static let shared: RemoteConfigServiceImpl = {
        let cacheDuration: TimeInterval
        #if DEBUG
        cacheDuration = 10
        #else
        cacheDuration = NGENV.remote_config_cache_duration_seconds
        #endif
        
        let firebaseRemoteConfig = FirebaseRemoteConfigService(
            cacheDuration: cacheDuration
        )
        return .init(firebaseRemoteConfig: firebaseRemoteConfig)
    }()
    
    private init(firebaseRemoteConfig: FirebaseRemoteConfigService) {
        self.firebaseRemoteConfig = firebaseRemoteConfig
        self.remoteConfigFetchTask = .init(firebaseRemoteConfig: firebaseRemoteConfig)
    }
}

extension RemoteConfigServiceImpl: RemoteConfigService {
    public func prefetch() {
        if #available(iOS 13.0, *) {
            Task {
                _ = await remoteConfigFetchTask.startIfNeeded()
            }
        } else {
            firebaseRemoteConfig.prefetch(completion: {})
        }
    }
    
    public func get<T>(_ type: T.Type, byKey key: String) -> T? where T : Decodable {
        return firebaseRemoteConfig.get(type, byKey: key)
    }
    
    public func fetch<T>(_ type: T.Type, byKey key: String, completion: ((T?) -> ())?) where T : Decodable {
        if #available(iOS 13.0, *) {
            Task {
                let value: T? = await asyncGet(
                    RemoteVariable(
                        key: key,
                        defaultValue: nil
                    )
                )
                completion?(value)
            }
        } else {
            firebaseRemoteConfig.fetch(type, byKey: key, completion: completion)
        }
    }
}

extension RemoteConfigServiceImpl: RemoteConfig {
    public func get<Payload>(_ variable: RemoteVariable<Payload>) -> Payload {
        return self.get(Payload.self, byKey: variable.key) ?? variable.defaultValue
    }
    
    public func getString(_ variable: RemoteVariable<String>) -> String {
        firebaseRemoteConfig.getString(
            byKey: variable.key
        )
    }
    
    @available(iOS 13.0, *)
    public func asyncGet<Payload>(_ variable: RemoteVariable<Payload>) async -> Payload {
        let task = await remoteConfigFetchTask.startIfNeeded()
        _ = await task.value
        return self.get(variable)
    }
}

private actor RemoteConfigFetchTask {
    private let firebaseRemoteConfig: FirebaseRemoteConfigService

    private var task: Any?

    init(firebaseRemoteConfig: FirebaseRemoteConfigService) {
        self.firebaseRemoteConfig = firebaseRemoteConfig
    }
    
    func startIfNeeded() -> Task<Void, Never> {
        if let task = task as? Task<Void, Never> {
            return task
        }
        
        let task = Task {
            await withCheckedContinuation { continuation in
                firebaseRemoteConfig.prefetch {
                    continuation.resume()
                }
            }
        }
        
        self.task = task
        
        return task
    }
}
