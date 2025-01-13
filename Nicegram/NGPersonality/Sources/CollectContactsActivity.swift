import Foundation
import FeatPersonality

private let container = PersonalityContainer.shared
private let checkPreferencesStateUseCase = container.checkPreferencesStateUseCase()
private let collectContactsActivityUseCase = container.collectContactsActivityUseCase()

public func collectContactsActivity(
    with userId: Int64,
    count: Int
) {
    guard checkPreferencesStateUseCase(with: .contactsActivity(.empty)) else { return }

    collectContactsActivityUseCase(with: userId, count: count)
}
