import UIKit
import FeatPersonality

private let container = PersonalityContainer.shared
private let checkPreferencesStateUseCase = container.checkPreferencesStateUseCase()
private let collectDailyActivityUseCases = container.collectDailyActivityUseCases()

public func collectDailyActivity(
    with userId: Int64,
    notificationName: NSNotification.Name
) {
    guard checkPreferencesStateUseCase(with: .dailyActivity(.empty)) else { return }

    collectDailyActivityUseCases(with: userId, notificationName: notificationName)
}
