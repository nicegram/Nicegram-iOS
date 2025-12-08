//
//  NicegramSettingsController.swift
//  NicegramUI
//
//  Created by Sergey Akentev.
//  Copyright © 2020 Nicegram. All rights reserved.
//

// MARK: Imports

import AccountContext
import Display
import FeatAccountBackup
import FeatAdsgram
import FeatAiShortcuts
import FeatCallRecorder
import FeatCalls
import FeatDataSharing
import FeatPinnedChats
import Foundation
import ItemListUI
import NGData
import NGLogging
import NGStrings
import Postbox
import PresentationDataUtils
import SwiftSignalKit
import TelegramCore
import TelegramNotices
import TelegramPresentationData
import TelegramUIPreferences
import UIKit
import class NGCoreUI.SharedLoadingView
import NGEnv
import NGWebUtils
import NGAppCache
import NGCore
import var NGCoreUI.strings
import NGDataSharing
import NGDoubleBottom
import NGQuickReplies
import NGRemoteConfig
import NGUtils

fileprivate let LOGTAG = extractNameFromPath(#file)

// MARK: Arguments struct

private final class NicegramSettingsControllerArguments {
    let context: AccountContext
    let accountsContexts: [(AccountContext, EnginePeer)]
    let presentController: (ViewController, ViewControllerPresentationArguments?) -> Void
    let pushController: (ViewController) -> Void
    let getRootController: () -> UIViewController?
    let updateTabs: () -> Void

    init(context: AccountContext, accountsContexts: [(AccountContext, EnginePeer)], presentController: @escaping (ViewController, ViewControllerPresentationArguments?) -> Void, pushController: @escaping (ViewController) -> Void, getRootController: @escaping () -> UIViewController?, updateTabs: @escaping () -> Void) {
        self.context = context
        self.accountsContexts = accountsContexts
        self.presentController = presentController
        self.pushController = pushController
        self.getRootController = getRootController
        self.updateTabs = updateTabs
    }
}

// MARK: Sections

private enum NicegramSettingsControllerSection: Int32 {
    case Unblock
    case Tabs
    case Folders
    case RoundVideos
    case Account
    case Other
    case CallRecorder
    case QuickReplies
    case ShareData
    case PinnedChats
    case Tools
    case AccountsBackup
}


private enum EasyToggleType {
    case showNicegramButtonInChat
    case showAiShortcutsInChat
    case sendWithEnter
    case showProfileId
    case showRegDate
    case hideReactions
    case hideStories
    case hideBadgeCounters
    case hideUnreadCounters
    case hideMentionNotification
    case enableAnimationsInChatList
    case enableGrayscaleAll
    case enableGrayscaleInChatList
    case enableGrayscaleInChat
}


// MARK: ItemListNodeEntry

private enum NicegramSettingsControllerEntry: ItemListNodeEntry {
    case TabsHeader(String)
    case showContactsTab(String, Bool)
    case showCallsTab(String, Bool)
    case showTabNames(String, Bool)
    case showFeedTab(String, Bool)
    
    case pinnedChatsHeader
    case pinnedChat(PinnedChat)
    struct PinnedChat: Equatable {
        var index: Int32 = 0
        let title: String
        let enabled: Bool
        var enableInteractiveChanges: Bool = true
        @IgnoreEquatable var setEnabled: (Bool) -> Void
    }

    case FoldersHeader(String)
    case foldersKeywords(String, Int64, Bool)
    case foldersAtBottom(String, Bool)
    case foldersAtBottomNotice(String)

    case RoundVideosHeader(String)
    case startWithRearCam(String, Bool)
    case shouldDownloadVideo(String, Bool)

    case OtherHeader(String)
    case hidePhoneInSettings(String, Bool)
    case hidePhoneInSettingsNotice(String)
    
    case easyToggle(Int32, EasyToggleType, String, Bool)
    
    case Account(String)
    case doubleBottom(String)
    case nicegramCalls
    
    case unblockHeader(String)
    case unblock(String, URL)
    
    case callRecorderReceiverId
    
    case quickReplies(String)
    
    case enableAppleSpeech2Text(String, Int64, Bool)
    case onetaptr(String, Bool)
    
    case shareBotsData(String, Bool)
    case shareChannelsData(String, Bool)
    case shareStickersData(String, Bool)
    case shareDataNote(String)
    
    case accountsBackupHeader
    case icloudBackupEnabled(Bool)
    case importFromBackup
    case importFromFile
    case exportToFile
    case deleteSessions

    // MARK: Section

    var section: ItemListSectionId {
        switch self {
        case .TabsHeader, .showContactsTab, .showCallsTab, .showTabNames, .showFeedTab:
            return NicegramSettingsControllerSection.Tabs.rawValue
        case .FoldersHeader, .foldersAtBottom, .foldersAtBottomNotice, .foldersKeywords:
            return NicegramSettingsControllerSection.Folders.rawValue
        case .RoundVideosHeader, .startWithRearCam, .shouldDownloadVideo:
            return NicegramSettingsControllerSection.RoundVideos.rawValue
        case .OtherHeader, .hidePhoneInSettings, .hidePhoneInSettingsNotice, .easyToggle:
            return NicegramSettingsControllerSection.Other.rawValue
        case .callRecorderReceiverId:
            return NicegramSettingsControllerSection.CallRecorder.rawValue
        case .quickReplies:
            return NicegramSettingsControllerSection.QuickReplies.rawValue
        case .unblockHeader, .unblock:
            return NicegramSettingsControllerSection.Unblock.rawValue
        case .Account, .doubleBottom, .nicegramCalls:
            return NicegramSettingsControllerSection.Account.rawValue
        case .shareBotsData, .shareChannelsData, .shareStickersData, .shareDataNote:
            return NicegramSettingsControllerSection.ShareData.rawValue
        case .pinnedChatsHeader, .pinnedChat:
            return NicegramSettingsControllerSection.PinnedChats.rawValue
        case .enableAppleSpeech2Text, .onetaptr:
            return NicegramSettingsControllerSection.Tools.rawValue
        case .accountsBackupHeader, .icloudBackupEnabled, .importFromBackup, .importFromFile, .exportToFile, .deleteSessions:
            return NicegramSettingsControllerSection.AccountsBackup.rawValue
        }
    }

    // MARK: SectionId

    var stableId: Int32 {
        switch self {
        case .unblockHeader:
            return 800
            
        case .unblock:
            return 900
            
        case .TabsHeader:
            return 1300
            
        case .showContactsTab:
            return 1400
            
        case .showCallsTab:
            return 1500
            
        case .showTabNames:
            return 1600
            
        case .showFeedTab:
            return 1650
            
        case .FoldersHeader:
            return 1700
            
        case .foldersKeywords:
            return 1750
            
        case .foldersAtBottom:
            return 1800
            
        case .foldersAtBottomNotice:
            return 1900
            
        case .pinnedChatsHeader:
            return 1910
            
        case let .pinnedChat(chat):
            return 1911 + chat.index
            
        case .RoundVideosHeader:
            return 2000
            
        case .startWithRearCam:
            return 2100
            
        case .shouldDownloadVideo:
            return 2101
            
        case .OtherHeader:
            return 2200
            
        case .hidePhoneInSettings:
            return 2300
            
        case .hidePhoneInSettingsNotice:
            return 2400
            
        case .callRecorderReceiverId:
            return 2425
            
        case .quickReplies:
            return 2450
            
        case .Account:
            return 2500
            
        case .doubleBottom:
            return 2700
        case .nicegramCalls:
            return 2800
            
        case .accountsBackupHeader:
            return 3000
        case .icloudBackupEnabled:
            return 3001
        case .importFromBackup:
            return 3002
        case .importFromFile:
            return 3003
        case .exportToFile:
            return 3004
        case .deleteSessions:
            return 3005
            
        case let .easyToggle(index, _, _, _):
            return 5000 + Int32(index)
            
        case .onetaptr:
            return 5900
        case .enableAppleSpeech2Text:
            return 5950
            
        case .shareBotsData:
            return 6000
        case .shareChannelsData:
            return 6001
        case .shareStickersData:
            return 6002
        case .shareDataNote:
            return 6010
        }
    }

    // MARK: < overload

    static func < (lhs: NicegramSettingsControllerEntry, rhs: NicegramSettingsControllerEntry) -> Bool {
        lhs.stableId < rhs.stableId
    }

    // MARK: ListViewItem
    
    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! NicegramSettingsControllerArguments
        switch self {
        case let .TabsHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: section)
            
        case let .showContactsTab(text, value):
            return ItemListSwitchItem(presentationData: presentationData, title: text, value: value, enabled: true, sectionId: section, style: .blocks, updated: { value in
                ngLog("[showContactsTab] invoked with \(value)", LOGTAG)
                NGSettings.showContactsTab = value
                arguments.updateTabs()
            })
            
        case let .showCallsTab(text, value):
            return ItemListSwitchItem(presentationData: presentationData, title: text, value: value, enabled: true, sectionId: section, style: .blocks, updated: { value in
                ngLog("[showCallsTab] invoked with \(value)", LOGTAG)
                let _ = updateCallListSettingsInteractively(accountManager: arguments.context.sharedContext.accountManager, {
                    $0.withUpdatedShowTab(value)
                }).start()
                
                if value {
                    let _ = ApplicationSpecificNotice.incrementCallsTabTips(accountManager: arguments.context.sharedContext.accountManager, count: 4).start()
                }
            })
            
        case let .showTabNames(text, value):
            return ItemListSwitchItem(presentationData: presentationData, title: text, value: value, enabled: true, sectionId: section, style: .blocks, updated: { value in
                ngLog("[showTabNames] invoked with \(value)", LOGTAG)
                NGSettings.showTabNames = value
                
                showRestartRequiredAlert(with: arguments, presentationData: presentationData)
            })
            
        case let .showFeedTab(text, value):
            return ItemListSwitchItem(presentationData: presentationData, title: text, value: value, enabled: true, sectionId: section, style: .blocks, updated: { value in
                ngLog("[showFeedTab] invoked with \(value)", LOGTAG)
                NGSettings.showFeedTab = value
                arguments.updateTabs()
            })
            
        case let .FoldersHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: section)
            
        case let .foldersAtBottom(text, value):
            return ItemListSwitchItem(presentationData: presentationData, title: text, value: value, enabled: true, sectionId: section, style: .blocks, updated: { value in
                ngLog("[foldersAtBottom] invoked with \(value)", LOGTAG)
                let _ = arguments.context.sharedContext.accountManager.transaction ({ transaction in
                    transaction.updateSharedData(ApplicationSpecificSharedDataKeys.experimentalUISettings, { settings in
                        var settings = settings?.get(ExperimentalUISettings.self) ?? ExperimentalUISettings.defaultSettings
                        settings.foldersTabAtBottom = value
                        return PreferencesEntry(settings)
                    })
                }).start()
            })
            
        case let .foldersKeywords(text, id, value):
            return ItemListSwitchItem(presentationData: presentationData, title: text, value: value, enabled: true, sectionId: section, style: .blocks, updated: { value in
                updateNicegramSettings {
                    if !value {
                        sendKeywordsAnalytics(with: .folderDisabled)
                    }
                    $0.keywords.show[id] = value
                }
            })
            
        case let .foldersAtBottomNotice(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: section)
            
        case let .RoundVideosHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: section)
            
        case let .startWithRearCam(text, value):
            return ItemListSwitchItem(presentationData: presentationData, title: text, value: value, enabled: true, sectionId: section, style: .blocks, updated: { value in
                ngLog("[startWithRearCam] invoked with \(value)", LOGTAG)
                NGSettings.useRearCamTelescopy = value
            })
            
        case let .shouldDownloadVideo(text, value):
            return ItemListSwitchItem(presentationData: presentationData, title: text, value: value, sectionId: section, style: .blocks) { value in
                NGSettings.shouldDownloadVideo = value
            }
        case let .OtherHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: section)
            
        case let .hidePhoneInSettings(text, value):
            return ItemListSwitchItem(presentationData: presentationData, title: text, value: value, enabled: true, sectionId: section, style: .blocks, updated: { value in
                ngLog("[hidePhoneInSettings] invoked with \(value)", LOGTAG)
                NGSettings.hidePhoneSettings = value
            })
            
        case let .hidePhoneInSettingsNotice(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: section)
            
        case let .easyToggle(index, toggleType, text, value):
            return ItemListSwitchItem(presentationData: presentationData, title: text, value: value, enabled: true, sectionId: section, style: .blocks, updated: { value in
                ngLog("[easyToggle] \(index) \(toggleType) invoked with \(value)", LOGTAG)
                switch (toggleType) {
                case .showNicegramButtonInChat:
                    NGSettings.showNicegramButtonInChat = value
                case .showAiShortcutsInChat:
                    Task {
                        let updateSettingsUseCase = AiShortcutsModule.shared.updateSettingsUseCase()
                        await updateSettingsUseCase.set(showInChat: value)
                    }
                case .sendWithEnter:
                    NGSettings.sendWithEnter = value
                case .showProfileId:
                    NGSettings.showProfileId = value
                case .showRegDate:
                    NGSettings.showRegDate = value
                case .hideReactions:
                    VarSystemNGSettings.hideReactions = value
                    if value {
                        sendUserSettingsAnalytics(with: .hideReactionsOn)
                    }
                case .hideStories:
                    NGSettings.hideStories = value
                    if value {
                        sendUserSettingsAnalytics(with: .hideStoriesOn)
                    }
                case .hideBadgeCounters:
                    NGSettings.hideBadgeCounters = value
                    showRestartRequiredAlert(with: arguments, presentationData: presentationData)
                case .hideUnreadCounters:
                    NGSettings.hideUnreadCounters = value
                    showRestartRequiredAlert(with: arguments, presentationData: presentationData)
                case .hideMentionNotification:
                    NGSettings.hideMentionNotification = value
                    showRestartRequiredAlert(with: arguments, presentationData: presentationData)
                case .enableAnimationsInChatList:
                    updateNicegramSettings {
                        $0.disableAnimationsInChatList = !value
                    }
                case .enableGrayscaleAll:
                    updateNicegramSettings {
                        $0.grayscaleAll = value
                    }
                case .enableGrayscaleInChatList:
                    updateNicegramSettings {
                        $0.grayscaleInChatList = value
                    }
                case .enableGrayscaleInChat:
                    updateNicegramSettings {
                        $0.grayscaleInChat = value
                    }
                }
            })
        case let .unblockHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: section)
        case let .unblock(text, url):
            return ItemListActionItem(presentationData: presentationData, title: text, kind: .neutral, alignment: .natural, sectionId: section, style: .blocks) {
                Task { @MainActor in
                    CoreContainer.shared.urlOpener().open(url)
                }
            }
        case let .Account(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: section)
        case let .doubleBottom(text):
            return ItemListActionItem(presentationData: presentationData, title: text, kind: .neutral, alignment: .natural, sectionId: section, style: .blocks) {
                arguments.pushController(doubleBottomListController(context: arguments.context, presentationData: arguments.context.sharedContext.currentPresentationData.with { $0 }, accountsContexts: arguments.accountsContexts))
            }
        case .nicegramCalls:
            return ItemListActionItem(presentationData: presentationData, title: FeatCalls.strings.settingsItemTitle(), kind: .neutral, alignment: .natural, sectionId: section, style: .blocks) {
                if #available(iOS 15.0, *) {
                    Task { @MainActor in
                        FeatCalls.SettingsPresenter().present()
                    }
                }
            }
        case .callRecorderReceiverId:
            return ItemListActionItem(presentationData: presentationData, title: FeatCallRecorder.strings.receiverIdItem(), kind: .neutral, alignment: .natural, sectionId: section, style: .blocks) {
                ReceiverIdAlertPresenter().present()
            }
        case let .quickReplies(text):
            return ItemListActionItem(presentationData: presentationData, title: text, kind: .neutral, alignment: .natural, sectionId: section, style: .blocks) {
                arguments.pushController(quickRepliesController(context: arguments.context))
            }
        case let .shareBotsData(text, value):
            return ItemListSwitchItem(presentationData: presentationData, title: text, value: value, enabled: true, sectionId: section, style: .blocks, updated: { value in
                if #available(iOS 13.0, *) {
                    Task {
                        let updateSettingsUseCase = DataSharingModule.shared.updateSettingsUseCase()
                        
                        await updateSettingsUseCase {
                            $0.shareBotsData = value
                        }
                    }
                }
            })
        case let .shareChannelsData(text, value):
            return ItemListSwitchItem(presentationData: presentationData, title: text, value: value, enabled: true, sectionId: section, style: .blocks, updated: { value in
                if #available(iOS 13.0, *) {
                    Task {
                        let updateSettingsUseCase = DataSharingModule.shared.updateSettingsUseCase()
                        
                        await updateSettingsUseCase {
                            $0.shareChannelsData = value
                        }
                    }
                }
            })
        case let .shareStickersData(text, value):
            return ItemListSwitchItem(presentationData: presentationData, title: text, value: value, enabled: true, sectionId: section, style: .blocks, updated: { value in
                if #available(iOS 13.0, *) {
                    Task {
                        let updateSettingsUseCase = DataSharingModule.shared.updateSettingsUseCase()
                        
                        await updateSettingsUseCase {
                            $0.shareStickersData = value
                        }
                    }
                }
            })
        case let .shareDataNote(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: section)
        case .pinnedChatsHeader:
            return ItemListSectionHeaderItem(
                presentationData: presentationData,
                text: NGCoreUI.strings.ngSettingsPinnedChats().localizedUppercase,
                sectionId: section
            )
        case let .pinnedChat(chat):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: chat.title,
                value: chat.enabled,
                enableInteractiveChanges: chat.enableInteractiveChanges,
                enabled: true,
                sectionId: section,
                style: .blocks,
                updated: chat.setEnabled
            )
        case let .enableAppleSpeech2Text(text, id, value):
            return ItemListSwitchItem(presentationData: presentationData, title: text, value: value, enabled: true, sectionId: section, style: .blocks, updated: { value in
                updateNicegramSettings {
                    $0.speechToText.appleRecognizerState[id] = value
                }
            })
        case let .onetaptr(text, value):
            return ItemListSwitchItem(presentationData: presentationData, title: text, value: value, enabled: true, sectionId: section, style: .blocks, updated: { value in
                NGSettings.oneTapTr = value
            })
        case .accountsBackupHeader:
            return ItemListSectionHeaderItem(
                presentationData: presentationData,
                text: l("AccountsBackup.SectionHeader").localizedUppercase,
                sectionId: section
            )
        case let .icloudBackupEnabled(value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: l("AccountsBackup.ICloudBackupEnabled"),
                value: value,
                enabled: true,
                sectionId: section,
                style: .blocks,
                updated: { value in
                    Task {
                        let updateSettingsUseCase = AccountBackupModule.shared.updateSettingsUseCase()
                        await updateSettingsUseCase {
                            $0.icloudBackupEnabled = value
                        }
                    }
                }
            )
        case .importFromBackup:
            return ItemListActionItem(presentationData: presentationData, title: l("AccountsBackup.ImportFromICloud"), kind: .neutral, alignment: .natural, sectionId: self.section, style: .blocks, action: {
                if #available(iOS 15.0, *) {
                    Task { @MainActor in
                        ImportAccountsPresenter().presentImportFromBackup()
                    }
                }
            })
        case .importFromFile:
            return ItemListActionItem(presentationData: presentationData, title: l("AccountsBackup.ImportFromFile"), kind: .neutral, alignment: .natural, sectionId: self.section, style: .blocks, action: {
                if #available(iOS 15.0, *) {
                    Task { @MainActor in
                        ImportAccountsPresenter().presentImportFromExternalFile()
                    }
                }
            })
        case .exportToFile:
            return ItemListActionItem(presentationData: presentationData, title: l("AccountsBackup.ExportAsFile"), kind: .neutral, alignment: .natural, sectionId: self.section, style: .blocks, action: {
                if #available(iOS 15.0, *) {
                    Task { @MainActor in
                        ExportAccountsPresenter().present()
                    }
                }
            })
        case .deleteSessions:
            return ItemListActionItem(presentationData: presentationData, title: l("AccountsBackup.DeleteSessions"), kind: .neutral, alignment: .natural, sectionId: self.section, style: .blocks, action: {
                if #available(iOS 15.0, *) {
                    Task { @MainActor in
                        ResolveNotMainAccountsPresenter().presentAllActiveAccounts()
                    }
                }
            })
        }
    }
}

// MARK: Entries list

private func nicegramSettingsControllerEntries(presentationData: PresentationData, experimentalSettings: ExperimentalUISettings, showCalls: Bool, pinnedChats: [NicegramSettingsControllerEntry.PinnedChat], sharingSettings: FeatDataSharing.Settings, aiShortcutsSettings: FeatAiShortcuts.Settings, accountBackupSettings: FeatAccountBackup.Settings, context: AccountContext) -> [NicegramSettingsControllerEntry] {
    let nicegramSettings = getNicegramSettings()
    
    var entries: [NicegramSettingsControllerEntry] = []
    
    if !hideUnblock {
        entries.append(.unblockHeader(l("NicegramSettings.Unblock.Header").uppercased()))
        entries.append(.unblock(l("NicegramSettings.Unblock.Button"), nicegramUnblockUrl))
    }

    entries.append(.TabsHeader(l("NiceFeatures.Tabs.Header")))
    entries.append(.showContactsTab(
        l("NiceFeatures.Tabs.ShowContacts"),
        NGSettings.showContactsTab
    ))
    entries.append(.showCallsTab(
        l("NiceFeatures.Tabs.ShowCalls"),
        showCalls
    ))
    entries.append(.showTabNames(
        l("NiceFeatures.Tabs.ShowNames"),
        NGSettings.showTabNames
    ))
    entries.append(.showFeedTab(
        l("Show Feed Tab"),
        NGSettings.showFeedTab
    ))

    entries.append(.FoldersHeader(l("NiceFeatures.Folders.Header")))
    let peerId = context.account.peerId.toInt64()
    entries.append(.foldersKeywords(
        l("NicegramSettings.ShowKeywords"),
        peerId,
        nicegramSettings.keywords.show[peerId] ?? true
    ))
    entries.append(.foldersAtBottom(
        l("NiceFeatures.Folders.TgFolders"),
        experimentalSettings.foldersTabAtBottom
    ))
    entries.append(.foldersAtBottomNotice(
        l("NiceFeatures.Folders.TgFolders.Notice")
    ))
    
    if !pinnedChats.isEmpty {
        entries.append(.pinnedChatsHeader)
        pinnedChats.forEach {
            entries.append(.pinnedChat($0))
        }
    }

    entries.append(.RoundVideosHeader(l("NiceFeatures.RoundVideos.Header")))
    entries.append(.startWithRearCam(
        l("NiceFeatures.RoundVideos.UseRearCamera"),
        NGSettings.useRearCamTelescopy
    ))
    entries.append(.shouldDownloadVideo(
        l("NicegramSettings.RoundVideos.DownloadVideos"), 
        NGSettings.shouldDownloadVideo
    ))

    entries.append(.OtherHeader(
        l("NiceFeatures.Other").uppercased()))
    entries.append(.hidePhoneInSettings(
        l("NiceFeatures.HideNumber"),
        NGSettings.hidePhoneSettings
    ))
    entries.append(.hidePhoneInSettingsNotice(
        l("NicegramSettings.Other.hidePhoneInSettingsNotice")
    ))
    
    entries.append(.callRecorderReceiverId)
    
    if #available(iOS 10.0, *) {
        entries.append(.quickReplies(l("NiceFeatures.QuickReplies")))
    }

    
    entries.append(.Account(l("NiceFeatures.Account.Header").localizedUppercase))
    if !context.account.isHidden || !VarSystemNGSettings.inDoubleBottom {
        entries.append(.doubleBottom(l("DoubleBottom.Title")))
    }
    if #available(iOS 15.0, *),
       isNicegramCallsEnabled() {
        entries.append(.nicegramCalls)
    }
    
    if #available(iOS 15.0, *) {
        entries.append(.accountsBackupHeader)
        entries.append(.icloudBackupEnabled(accountBackupSettings.icloudBackupEnabled))
        entries.append(.importFromBackup)
        entries.append(.importFromFile)
        entries.append(.exportToFile)
        entries.append(.deleteSessions)
    }
    
    var toggleIndex: Int32 = 1
    // MARK: Other Toggles (Easy)
    entries.append(.easyToggle(toggleIndex, .showNicegramButtonInChat, l("ShowNicegramButtonInChat"), NGSettings.showNicegramButtonInChat))
    toggleIndex += 1
    
    entries.append(.easyToggle(toggleIndex, .showAiShortcutsInChat, l("ShowAIShortcutsInChat"), aiShortcutsSettings.showInChat))
    toggleIndex += 1
    
    entries.append(.easyToggle(toggleIndex, .sendWithEnter, l("SendWithKb"), NGSettings.sendWithEnter))
    toggleIndex += 1
    
    entries.append(.easyToggle(toggleIndex, .showProfileId, l("NicegramSettings.Other.showProfileId"), NGSettings.showProfileId))
    toggleIndex += 1
    
    entries.append(.easyToggle(toggleIndex, .showRegDate, l("NicegramSettings.Other.showRegDate"), NGSettings.showRegDate))
    toggleIndex += 1
    
    entries.append(.easyToggle(toggleIndex, .hideReactions, l("NicegramSettings.Other.hideReactions"), VarSystemNGSettings.hideReactions))
    toggleIndex += 1
    
    entries.append(.easyToggle(toggleIndex, .hideStories, l("NicegramSettings.HideStories"), NGSettings.hideStories))
    toggleIndex += 1

    entries.append(
        .easyToggle(
            toggleIndex,
            .hideBadgeCounters,
            l("NicegramSettings.HideBadgeCounters"),
            NGSettings.hideBadgeCounters
        )
    )
    toggleIndex += 1

    entries.append(
        .easyToggle(
            toggleIndex,
            .hideUnreadCounters,
            l("NicegramSettings.HideUnreadCounters"),
            NGSettings.hideUnreadCounters
        )
    )
    toggleIndex += 1

    entries.append(
        .easyToggle(
            toggleIndex,
            .hideMentionNotification,
            l("NicegramSettings.HideMentionNotification"),
            NGSettings.hideMentionNotification
        )
    )
    toggleIndex += 1
    
    entries.append(.easyToggle(toggleIndex, .enableAnimationsInChatList, l("NicegramSettings.EnableAnimationsInChatList"), !nicegramSettings.disableAnimationsInChatList))
    toggleIndex += 1
    
    entries.append(.easyToggle(toggleIndex, .enableGrayscaleAll, l("NicegramSettings.EnableGrayscaleAll"), nicegramSettings.grayscaleAll))
    toggleIndex += 1
    
    entries.append(.easyToggle(toggleIndex, .enableGrayscaleInChatList, l("NicegramSettings.EnableGrayscaleInChatList"), nicegramSettings.grayscaleInChatList))
    toggleIndex += 1
    
    entries.append(.easyToggle(toggleIndex, .enableGrayscaleInChat, l("NicegramSettings.EnableGrayscaleInChat"), nicegramSettings.grayscaleInChat))
    toggleIndex += 1
    
    entries.append(.onetaptr(l("Premium.OnetapTranslate"), NGSettings.oneTapTr))
    let id = context.account.peerId.id._internalGetInt64Value()
    entries.append(
        .enableAppleSpeech2Text(l("NicegramSettings.EnableAppleSpeech2Text"),
                                id,
                                (nicegramSettings.speechToText.appleRecognizerState[id] ?? false) ?? false
                               )
    )

    entries.append(
        .shareBotsData(
            l("NicegramSettings.ShareBotsToggle"),
            sharingSettings.shareBotsData
        )
    )
    entries.append(
        .shareChannelsData(
            l("NicegramSettings.ShareChannelsToggle"),
            sharingSettings.shareChannelsData
        )
    )
    entries.append(
        .shareStickersData(
            l("NicegramSettings.ShareStickersToggle"),
            sharingSettings.shareStickersData
        )
    )
    entries.append(
        .shareDataNote(l("NicegramSettings.ShareData.Note"))
    )
    
    return entries
}

// MARK: Controller

public func nicegramSettingsController(context: AccountContext, accountsContexts: [(AccountContext, EnginePeer)], modal: Bool = false) -> ViewController {
    var presentControllerImpl: ((ViewController, ViewControllerPresentationArguments?) -> Void)?
    var pushControllerImpl: ((ViewController) -> Void)?
    var dismissImpl: (() -> Void)?
    var getRootControllerImpl: (() -> UIViewController?)?
    var updateTabsImpl: (() -> Void)?

    let presentationData = context.sharedContext.currentPresentationData.with { $0 }

    let arguments = NicegramSettingsControllerArguments(context: context, accountsContexts: accountsContexts, presentController: { controller, arguments in
        presentControllerImpl?(controller, arguments)
    }, pushController: { controller in
        pushControllerImpl?(controller)
    }, getRootController: {
        getRootControllerImpl?()
    }, updateTabs: {
        updateTabsImpl?()
    })

    let showCallsTab = context.sharedContext.accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.callListSettings])
        |> map { sharedData -> Bool in
            var value = CallListSettings.defaultSettings.showTab
            if let settings = sharedData.entries[ApplicationSpecificSharedDataKeys.callListSettings]?.get(CallListSettings.self) {
                value = settings.showTab
            }
            return value
        }

    let sharedDataSignal = context.sharedContext.accountManager.sharedData(keys: [
        ApplicationSpecificSharedDataKeys.experimentalUISettings,
    ])
    
    let adsgramModule = AdsgramModule.shared
    let adsgramSettingsPublisher = adsgramModule.getFeatureStatusUseCase().enabledPublisher()
        .combineLatestThreadSafe(
            adsgramModule.getSettingsUseCase().publisher()
        )
        .map { enabled, settings in
            enabled ? settings : nil
        }
    
    let pinnedChatsSignal = adsgramSettingsPublisher
        .map { adsgramSettings in
            var entries = [NicegramSettingsControllerEntry.PinnedChat]()
            
            if let adsgramSettings {
                entries.append(
                    NicegramSettingsControllerEntry.PinnedChat(
                        index: (entries.last?.index ?? 0) + 1,
                        title: "adsgram",
                        enabled: adsgramSettings.showPin,
                        enableInteractiveChanges: false,
                        setEnabled: { value in
                            Task { @MainActor in
                                let settingsViewModel = SettingsViewModel()
                                settingsViewModel.onChange(showPin: value)
                            }
                        }
                    )
                )
            }
            
            for i in entries.startIndex..<entries.endIndex {
                entries[i].index = Int32(i + 1)
            }
            
            return entries
        }
        .toSignal()
        .skipError()
    
    let sharingSettingsSignal = DataSharingModule.shared.getSettingsUseCase()
        .publisher()
        .toSignal()
        .skipError()
    
    let aiShortcutsSettingsSignal = AiShortcutsModule.shared.getSettingsUseCase()
        .publisher()
        .toSignal()
        .skipError()
    
    let accountBackupSettingsSignal = AccountBackupModule.shared.getSettingsUseCase()
        .publisher()
        .toSignal()
        .skipError()

    let signal = combineLatest(context.sharedContext.presentationData, sharedDataSignal, showCallsTab, pinnedChatsSignal, sharingSettingsSignal, aiShortcutsSettingsSignal, accountBackupSettingsSignal) |> map { presentationData, sharedData, showCalls, pinnedChats, sharingSettings, aiShortcutsSettings, accountBackupSettings -> (ItemListControllerState, (ItemListNodeState, Any)) in

        let experimentalSettings: ExperimentalUISettings = sharedData.entries[ApplicationSpecificSharedDataKeys.experimentalUISettings]?.get(ExperimentalUISettings.self) ?? ExperimentalUISettings.defaultSettings

        var leftNavigationButton: ItemListNavigationButton?
        if modal {
            leftNavigationButton = ItemListNavigationButton(content: .text(strings.cancel()), style: .regular, enabled: true, action: {
                dismissImpl?()
            })
        }

        let entries = nicegramSettingsControllerEntries(presentationData: presentationData, experimentalSettings: experimentalSettings, showCalls: showCalls, pinnedChats: pinnedChats, sharingSettings: sharingSettings, aiShortcutsSettings: aiShortcutsSettings, accountBackupSettings: accountBackupSettings, context: context)
        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(l("AppName")), leftNavigationButton: leftNavigationButton, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: strings.back()))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: entries, style: .blocks)

        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    presentControllerImpl = { [weak controller] c, a in
        controller?.present(c, in: .window(.root), with: a)
    }
    pushControllerImpl = { [weak controller] c in
        (controller?.navigationController as? NavigationController)?.pushViewController(c)
    }
    dismissImpl = { [weak controller] in
        controller?.dismiss()
    }
    getRootControllerImpl = { [weak controller] in
        controller?.view.window?.rootViewController
    }
    updateTabsImpl = {
        updateTabs(with: context)
    }
    return controller
}

public func updateTabs(with context: AccountContext) {
    _ = updateCallListSettingsInteractively(accountManager: context.sharedContext.accountManager) { settings in
        var settings = settings
        settings.showTab = !settings.showTab
        return settings
    }.start(completed: {
        _ = updateCallListSettingsInteractively(accountManager: context.sharedContext.accountManager) { settings in
            var settings = settings
            settings.showTab = !settings.showTab
            return settings
        }.start(completed: {
            ngLog("Tabs refreshed", LOGTAG)
        })
    })
}

private func showRestartRequiredAlert(
    with arguments: NicegramSettingsControllerArguments,
    presentationData: ItemListPresentationData
) {
    let controller = standardTextAlertController(
        theme: AlertControllerTheme(
            presentationData: arguments.context.sharedContext.currentPresentationData.with { $0 }
        ),
        title: nil,
        text: l("Common.RestartRequired"),
        actions: [
            TextAlertAction(type: .genericAction, title: strings.nicegramAlertOk(), action: {})
        ]
    )

    arguments.presentController(controller, nil)
}

@propertyWrapper
private struct IgnoreEquatable<Value>: Equatable {
    var value: Value
    
    init(wrappedValue: Value) {
        self.value = wrappedValue
    }

    var wrappedValue: Value {
        get { value }
        set { value = newValue }
    }
    
    static func == (lhs: IgnoreEquatable<Value>, rhs: IgnoreEquatable<Value>) -> Bool {
        true
    }
}
