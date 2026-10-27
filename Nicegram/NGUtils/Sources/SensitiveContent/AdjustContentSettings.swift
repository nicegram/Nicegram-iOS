import FeatSensitiveContentAccess
import Foundation
import SwiftSignalKit
import TelegramCore

public func ngAdjustContentSettings() -> (Signal<ContentSettings, NoError>) -> Signal<ContentSettings, NoError> {
    { signal in
        // The policy reads the assistant's Firebase-backed Remote Config, and only the main app
        // configures Firebase. Since 13.1.1 the share extension builds full account contexts too,
        // and resolving the policy there crashed it.
        if Bundle.main.bundlePath.hasSuffix(".appex") {
            return signal
        }

        let getSensitiveContentPolicyUseCase = FeatSensitiveContentAccess.Module.shared.getSensitiveContentPolicyUseCase()
        
        let sensitiveContentPolicySignal = getSensitiveContentPolicyUseCase.publisher()
            .prepend(
                SensitiveContentPolicy(
                    reasonsToIgnore: []
                )
            )
            .toSignal()
            .skipError()
        
        return combineLatest(signal, sensitiveContentPolicySignal)
        |> map { settings, policy in
            var settings = settings
            
            let adjustedReasons = settings.ignoreContentRestrictionReasons.union(policy.reasonsToIgnore)
            settings.ignoreContentRestrictionReasons = adjustedReasons
            
            return settings
        }
    }
}
