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
import FeatImagesHubUI
import FeatNicegramHub
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
import NGDoubleBottom
import NGQuickReplies
import NGRemoteConfig
import NGStats
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
    case QuickReplies
    case ShareData
    case PinnedChats
    case Tools
}


private enum EasyToggleType {
    case showNicegramButtonInChat
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
    case pinnedChat(Int32, PinnedChat)

    case FoldersHeader(String)
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
    
    case unblockHeader(String)
    case unblock(String, URL)
    
    case quickReplies(String)
    
    case enableAppleSpeech2Text(String, Bool)
    case onetaptr(String, Bool)
    
    case shareBotsData(String, Bool)
    case shareChannelsData(String, Bool)
    case shareStickersData(String, Bool)
    case shareDataNote(String)

    // MARK: Section

    var section: ItemListSectionId {
        switch self {
        case .TabsHeader, .showContactsTab, .showCallsTab, .showTabNames, .showFeedTab:
            return NicegramSettingsControllerSection.Tabs.rawValue
        case .FoldersHeader, .foldersAtBottom, .foldersAtBottomNotice:
            return NicegramSettingsControllerSection.Folders.rawValue
        case .RoundVideosHeader, .startWithRearCam, .shouldDownloadVideo:
            return NicegramSettingsControllerSection.RoundVideos.rawValue
        case .OtherHeader, .hidePhoneInSettings, .hidePhoneInSettingsNotice, .easyToggle:
            return NicegramSettingsControllerSection.Other.rawValue
        case .quickReplies:
            return NicegramSettingsControllerSection.QuickReplies.rawValue
        case .unblockHeader, .unblock:
            return NicegramSettingsControllerSection.Unblock.rawValue
        case .Account, .doubleBottom:
            return NicegramSettingsControllerSection.Account.rawValue
        case .shareBotsData, .shareChannelsData, .shareStickersData, .shareDataNote:
            return NicegramSettingsControllerSection.ShareData.rawValue
        case .pinnedChatsHeader, .pinnedChat:
            return NicegramSettingsControllerSection.PinnedChats.rawValue
        case .enableAppleSpeech2Text, .onetaptr:
            return NicegramSettingsControllerSection.Tools.rawValue
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

        case .foldersAtBottom:
            return 1800

        case .foldersAtBottomNotice:
            return 1900
            
        case .pinnedChatsHeader:
            return 1910
            
        case let .pinnedChat(index, _):
            return 1911 + index

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

        case .quickReplies:
            return 2450

        case .Account:
            return 2500
            
        case .doubleBottom:
            return 2700
            
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

    // MARK: == overload

    static func == (lhs: NicegramSettingsControllerEntry, rhs: NicegramSettingsControllerEntry) -> Bool {
        switch lhs {
        case let .TabsHeader(lhsText):
            if case let .TabsHeader(rhsText) = rhs, lhsText == rhsText {
                return true
            } else {
                return false
            }

        case let .showContactsTab(lhsText, lhsVar0Bool):
            if case let .showContactsTab(rhsText, rhsVar0Bool) = rhs, lhsText == rhsText, lhsVar0Bool == rhsVar0Bool {
                return true
            } else {
                return false
            }

        case let .showCallsTab(lhsText, lhsVar0Bool):
            if case let .showCallsTab(rhsText, rhsVar0Bool) = rhs, lhsText == rhsText, lhsVar0Bool == rhsVar0Bool {
                return true
            } else {
                return false
            }

        case let .showTabNames(lhsText, lhsVar0Bool):
            if case let .showTabNames(rhsText, rhsVar0Bool) = rhs, lhsText == rhsText, lhsVar0Bool == rhsVar0Bool {
                return true
            } else {
                return false
            }
            
        case let .showFeedTab(lhsText, lhsVar0Bool):
            if case let .showFeedTab(rhsText, rhsVar0Bool) = rhs, lhsText == rhsText, lhsVar0Bool == rhsVar0Bool {
                return true
            } else {
                return false
            }

        case let .FoldersHeader(lhsText):
            if case let .FoldersHeader(rhsText) = rhs, lhsText == rhsText {
                return true
            } else {
                return false
            }

        case let .foldersAtBottom(lhsText, lhsVar0Bool):
            if case let .foldersAtBottom(rhsText, rhsVar0Bool) = rhs, lhsText == rhsText, lhsVar0Bool == rhsVar0Bool {
                return true
            } else {
                return false
            }

        case let .foldersAtBottomNotice(lhsText):
            if case let .foldersAtBottomNotice(rhsText) = rhs, lhsText == rhsText {
                return true
            } else {
                return false
            }

        case let .RoundVideosHeader(lhsText):
            if case let .RoundVideosHeader(rhsText) = rhs, lhsText == rhsText {
                return true
            } else {
                return false
            }

        case let .startWithRearCam(lhsText, lhsVar0Bool):
            if case let .startWithRearCam(rhsText, rhsVar0Bool) = rhs, lhsText == rhsText, lhsVar0Bool == rhsVar0Bool {
                return true
            } else {
                return false
            }
        
        case let .shouldDownloadVideo(lhsText, lhsVar0Bool):
            if case let .shouldDownloadVideo(rhsText, rhsVar0Bool) = rhs, lhsText == rhsText, lhsVar0Bool == rhsVar0Bool {
                return true
            } else {
                return false
            }
            
        case let .OtherHeader(lhsText):
            if case let .OtherHeader(rhsText) = rhs, lhsText == rhsText {
                return true
            } else {
                return false
            }

        case let .hidePhoneInSettings(lhsText, lhsVar0Bool):
            if case let .hidePhoneInSettings(rhsText, rhsVar0Bool) = rhs, lhsText == rhsText, lhsVar0Bool == rhsVar0Bool {
                return true
            } else {
                return false
            }

        case let .hidePhoneInSettingsNotice(lhsText):
            if case let .hidePhoneInSettingsNotice(rhsText) = rhs, lhsText == rhsText {
                return true
            } else {
                return false
            }
        case let .easyToggle(lhsIndex, _, lhsText, lhsValue):
            if case let .easyToggle(rhsIndex, _, rhsText, rhsValue) = rhs, lhsIndex == rhsIndex, lhsText == rhsText, lhsValue == rhsValue {
                return true
            } else {
                return false
            }
        case let .unblockHeader(lhsText):
            if case let .unblockHeader(rhsText) = rhs, lhsText == rhsText {
                return true
            } else {
                return false
            }
        case let .unblock(lhsText, lhsUrl):
            if case let .unblock(rhsText, rhsUrl) = rhs, lhsText == rhsText, lhsUrl == rhsUrl {
                return true
            } else {
                return false
            }
        case let .Account(lhsText):
            if case let .Account(rhsText) = rhs, lhsText == rhsText {
                return true
            } else {
                return false
            }
        case let .doubleBottom(lhsText):
            if case let .doubleBottom(rhsText) = rhs, lhsText == rhsText {
                return true
            } else {
                return false
            }
        case let .quickReplies(lhsText):
            if case let .quickReplies(rhsText) = rhs, lhsText == rhsText {
                return true
            } else {
                return false
            }
        case let .shareBotsData(lhsText, lhsValue):
            if case let .shareBotsData(rhsText, rhsValue) = rhs, lhsText == rhsText, lhsValue == rhsValue {
                return true
            } else {
                return false
            }
        case let .shareChannelsData(lhsText, lhsValue):
            if case let .shareChannelsData(rhsText, rhsValue) = rhs, lhsText == rhsText, lhsValue == rhsValue {
                return true
            } else {
                return false
            }
        case let .shareStickersData(lhsText, lhsValue):
            if case let .shareStickersData(rhsText, rhsValue) = rhs, lhsText == rhsText, lhsValue == rhsValue {
                return true
            } else {
                return false
            }
        case let .shareDataNote(lhsText):
            if case let .shareDataNote(rhsText) = rhs, lhsText == rhsText {
                return true
            } else {
                return false
            }
        case .pinnedChatsHeader:
            if case .pinnedChatsHeader = rhs {
                return true
            } else {
                return false
            }
        case let .pinnedChat(lhsIndex, lhsChat):
            if case let .pinnedChat(rhsIndex, rhsChat) = rhs,
               lhsIndex == rhsIndex,
               lhsChat == rhsChat {
                return true
            } else {
                return false
            }
        case let .enableAppleSpeech2Text(lhsText, lhsValue):
            if case let .enableAppleSpeech2Text(rhsText, rhsValue) = rhs, lhsText == rhsText, lhsValue == rhsValue {
                return true
            } else {
                return false
            }
        case let .onetaptr(lhsText, lhsValue):
            if case let .onetaptr(rhsText, rhsValue) = rhs, lhsText == rhsText, lhsValue == rhsValue {
                return true
            } else {
                return false
            }
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
        case let .quickReplies(text):
            return ItemListActionItem(presentationData: presentationData, title: text, kind: .neutral, alignment: .natural, sectionId: section, style: .blocks) {
                arguments.pushController(quickRepliesController(context: arguments.context))
            }
        case let .shareBotsData(text, value):
            return ItemListSwitchItem(presentationData: presentationData, title: text, value: value, enabled: true, sectionId: section, style: .blocks, updated: { value in
                if #available(iOS 13.0, *) {
                    Task {
                        let updateSharingSettingsUseCase = NicegramHubContainer.shared.updateSharingSettingsUseCase()
                        
                        await updateSharingSettingsUseCase {
                            $0.with(\.shareBotsData, value)
                        }
                    }
                }
            })
        case let .shareChannelsData(text, value):
            return ItemListSwitchItem(presentationData: presentationData, title: text, value: value, enabled: true, sectionId: section, style: .blocks, updated: { value in
                if #available(iOS 13.0, *) {
                    Task {
                        let updateSharingSettingsUseCase = NicegramHubContainer.shared.updateSharingSettingsUseCase()
                        
                        await updateSharingSettingsUseCase {
                            $0.with(\.shareChannelsData, value)
                        }
                    }
                }
            })
        case let .shareStickersData(text, value):
            return ItemListSwitchItem(presentationData: presentationData, title: text, value: value, enabled: true, sectionId: section, style: .blocks, updated: { value in
                if #available(iOS 13.0, *) {
                    Task {
                        let updateSharingSettingsUseCase = NicegramHubContainer.shared.updateSharingSettingsUseCase()
                        
                        await updateSharingSettingsUseCase {
                            $0.with(\.shareStickersData, value)
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
        case let .pinnedChat(_, chat):
            if #available(iOS 13.0, *) {
                return ItemListSwitchItem(
                    presentationData: presentationData,
                    title: chat.name,
                    value: chat.isPinned,
                    enabled: true,
                    sectionId: section,
                    style: .blocks,
                    updated: { value in
                        Task {
                            let setChatPinnedUseCase = PinnedChatsContainer.shared.setChatPinnedUseCase()
                            await setChatPinnedUseCase(
                                id: chat.id,
                                pinned: value
                            )
                        }
                    }
                )
            } else {
                fatalError()
            }
        case let .enableAppleSpeech2Text(text, value):
            return ItemListSwitchItem(presentationData: presentationData, title: text, value: value, enabled: true, sectionId: section, style: .blocks, updated: { value in
                updateNicegramSettings {
                    $0.speechToText.enableApple = value
                }
            })
        case let .onetaptr(text, value):
            return ItemListSwitchItem(presentationData: presentationData, title: text, value: value, enabled: true, sectionId: section, style: .blocks, updated: { value in
                NGSettings.oneTapTr = value
            })
        }
    }
}

// MARK: Entries list

private func nicegramSettingsControllerEntries(presentationData: PresentationData, experimentalSettings: ExperimentalUISettings, showCalls: Bool, pinnedChats: [PinnedChat], sharingSettings: SharingSettings?, context: AccountContext) -> [NicegramSettingsControllerEntry] {
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
        presentationData.strings.CallSettings_TabIcon,
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
    entries.append(.foldersAtBottom(
        l("NiceFeatures.Folders.TgFolders"),
        experimentalSettings.foldersTabAtBottom
    ))
    entries.append(.foldersAtBottomNotice(
        l("NiceFeatures.Folders.TgFolders.Notice")
    ))
    
    let pinnedChatsEntries = pinnedChats.enumerated().map { index, chat in
        NicegramSettingsControllerEntry.pinnedChat(Int32(index), chat)
    }
    
    if !pinnedChatsEntries.isEmpty {
        entries.append(.pinnedChatsHeader)
        pinnedChatsEntries.forEach {
            entries.append($0)
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
        presentationData.strings.ChatSettings_Other.uppercased()))
    entries.append(.hidePhoneInSettings(
        l("NiceFeatures.HideNumber"),
        NGSettings.hidePhoneSettings
    ))
    entries.append(.hidePhoneInSettingsNotice(
        l("NicegramSettings.Other.hidePhoneInSettingsNotice")
    ))
    
    if #available(iOS 10.0, *) {
        entries.append(.quickReplies(l("NiceFeatures.QuickReplies")))
    }

    
    entries.append(.Account(l("NiceFeatures.Account.Header")))
    if !context.account.isHidden || !VarSystemNGSettings.inDoubleBottom {
        entries.append(.doubleBottom(l("DoubleBottom.Title")))
    }
    
    var toggleIndex: Int32 = 1
    // MARK: Other Toggles (Easy)
    entries.append(.easyToggle(toggleIndex, .showNicegramButtonInChat, l("ShowNicegramButtonInChat"), NGSettings.showNicegramButtonInChat))
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
    entries.append(.enableAppleSpeech2Text(l("NicegramSettings.EnableAppleSpeech2Text"), nicegramSettings.speechToText.enableApple ?? false))

    if let sharingSettings {
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
    }
    
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
            var value = false
            if let settings = sharedData.entries[ApplicationSpecificSharedDataKeys.callListSettings]?.get(CallListSettings.self) {
                value = settings.showTab
            }
            return value
        }

    let sharedDataSignal = context.sharedContext.accountManager.sharedData(keys: [
        ApplicationSpecificSharedDataKeys.experimentalUISettings,
    ])
    
    let pinnedChatsSignal: Signal<[PinnedChat], NoError>
    if #available(iOS 13.0, *) {
        pinnedChatsSignal = PinnedChatsContainer.shared.getPinnedChatsUseCase()
            .publisher()
            .toSignal()
            .skipError()
    } else {
        pinnedChatsSignal = .single([])
    }
    
    let sharingSettingsSignal: Signal<SharingSettings?, NoError>
    if #available(iOS 13.0, *) {
        sharingSettingsSignal = NicegramHubContainer.shared.getSharingSettingsUseCase()
            .publisher()
            .map { Optional($0) }
            .toSignal()
            .skipError()
    } else {
        sharingSettingsSignal = .single(nil)
    }

    let signal = combineLatest(context.sharedContext.presentationData, sharedDataSignal, showCallsTab, pinnedChatsSignal, sharingSettingsSignal) |> map { presentationData, sharedData, showCalls, pinnedChats, sharingSettings -> (ItemListControllerState, (ItemListNodeState, Any)) in

        let experimentalSettings: ExperimentalUISettings = sharedData.entries[ApplicationSpecificSharedDataKeys.experimentalUISettings]?.get(ExperimentalUISettings.self) ?? ExperimentalUISettings.defaultSettings

        var leftNavigationButton: ItemListNavigationButton?
        if modal {
            leftNavigationButton = ItemListNavigationButton(content: .text(presentationData.strings.Common_Cancel), style: .regular, enabled: true, action: {
                dismissImpl?()
            })
        }

        let entries = nicegramSettingsControllerEntries(presentationData: presentationData, experimentalSettings: experimentalSettings, showCalls: showCalls, pinnedChats: pinnedChats, sharingSettings: sharingSettings, context: context)
        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(l("AppName")), leftNavigationButton: leftNavigationButton, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
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
            TextAlertAction(type: .genericAction, title: presentationData.strings.Common_OK, action: {})
        ]
    )

    arguments.presentController(controller, nil)
}
