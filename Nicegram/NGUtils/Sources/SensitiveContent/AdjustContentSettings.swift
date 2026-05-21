import FeatSensitiveContentAccess
import SwiftSignalKit
import TelegramCore

public func ngAdjustContentSettings() -> (Signal<ContentSettings, NoError>) -> Signal<ContentSettings, NoError> {
    { signal in
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
