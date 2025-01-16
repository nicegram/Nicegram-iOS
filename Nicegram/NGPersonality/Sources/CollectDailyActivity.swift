import UIKit
import FeatPersonality

private let container = PersonalityContainer.shared
private let checkPreferencesStateUseCase = container.checkPreferencesStateUseCase()
private let collectDailyActivityUseCases = container.collectDailyActivityUseCases()

public func collectDailyActivity(
    with userId: Int64,
    notificationName: NSNotification.Name
) async {
    guard checkPreferencesStateUseCase(with: userId, personality: .dailyActivity(.empty)) else { return }

    await collectDailyActivityUseCases(with: userId, notificationName: notificationName)
}
