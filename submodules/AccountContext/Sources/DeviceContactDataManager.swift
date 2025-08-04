import Foundation
import TelegramCore
import TelegramUIPreferences
import SwiftSignalKit

public typealias DeviceContactStableId = String

public var sharedDisableDeviceContactDataDiffing: Bool = false

public protocol DeviceContactDataManager: AnyObject {
    func personNameDisplayOrder() -> Signal<PresentationPersonNameOrder, NoError>
    func basicData() -> Signal<[DeviceContactStableId: DeviceContactBasicData], NoError>
    func basicDataForNormalizedPhoneNumber(_ normalizedNumber: DeviceContactNormalizedPhoneNumber) -> Signal<[(DeviceContactStableId, DeviceContactBasicData)], NoError>
    func extendedData(stableId: DeviceContactStableId) -> Signal<DeviceContactExtendedData?, NoError>
    func importable() -> Signal<[DeviceContactNormalizedPhoneNumber: ImportableDeviceContactData], NoError>
    func appSpecificReferences() -> Signal<[EnginePeer.Id: DeviceContactBasicDataWithReference], NoError>
    func search(query: String) -> Signal<[DeviceContactStableId: (DeviceContactBasicData, EnginePeer.Id?)], NoError>
    func appendContactData(_ contactData: DeviceContactExtendedData, to stableId: DeviceContactStableId) -> Signal<DeviceContactExtendedData?, NoError>
    func appendPhoneNumber(_ phoneNumber: DeviceContactPhoneNumberData, to stableId: DeviceContactStableId) -> Signal<DeviceContactExtendedData?, NoError>
    // Nicegram DB Changes
    func createContactWithData(_ contactData: DeviceContactExtendedData, account: Account) -> Signal<(DeviceContactStableId, DeviceContactExtendedData)?, NoError>
    func deleteContactWithAppSpecificReference(peerId: EnginePeer.Id) -> Signal<Never, NoError>
}
