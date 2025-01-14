import Foundation
import FeatPersonality

private let container = PersonalityContainer.shared
private let checkPreferencesStateUseCase = container.checkPreferencesStateUseCase()
private let collectActiveHoursUseCase = container.collectActiveHoursUseCase()

public func collectMessageActivity(with userId: Int64) {
    guard checkPreferencesStateUseCase(with: .activeHours([])) else { return }

    Task {
        await collectActiveHoursUseCase.collectMessageActivity(with: userId)
    }
}

public func collectScrollActivity(with userId: Int64) {
    guard checkPreferencesStateUseCase(with: .activeHours([])) else { return }

    collectActiveHoursUseCase.collectScrollActivity(with: userId)
}

public func collectCallActivity(with userId: Int64) {
    guard checkPreferencesStateUseCase(with: .activeHours([])) else { return }

    collectActiveHoursUseCase.collectCallActivity(with: userId)
}

public func collectVideoActivity(with userId: Int64) {
    guard checkPreferencesStateUseCase(with: .activeHours([])) else { return }

    collectActiveHoursUseCase.collectVideoActivity(with: userId)
}
