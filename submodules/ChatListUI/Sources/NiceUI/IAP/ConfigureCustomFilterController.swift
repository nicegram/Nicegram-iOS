//
//  ConigureCustomFilterController.swift
//  Nicegram
//
//  Created by Sergey Akentev on 11.11.2019. File was generated automatically
//  Copyright © 2019 Nicegram. All rights reserved.
//

import Foundation
import Display
import SwiftSignalKit
import Postbox
import TelegramCore
import TelegramPresentationData
import TelegramUIPreferences
import ItemListUI
import AccountContext



private struct SelectionState: Equatable {
}

private final class ConigureCustomFilterControllerArguments {
    let toggleSetting: (Bool, String) -> Void
    let testAction: () -> Void
    let toggleIncludeFilter: (Bool, String) -> Void
    let toggleUnincludeFilter: (Bool, String) -> Void
    let openSoundPicker: (String, String) -> Void

    
    init(toggleSetting:@escaping (Bool, String) -> Void,testAction:@escaping () -> Void, toggleIncludeFilter:@escaping (Bool, String) -> Void, toggleUnincludeFilter:@escaping (Bool, String) -> Void, openSoundPicker:@escaping (String, String) -> Void) {
        self.toggleSetting = toggleSetting
        self.testAction = testAction
        self.toggleIncludeFilter = toggleIncludeFilter
        self.toggleUnincludeFilter = toggleUnincludeFilter
        self.openSoundPicker = openSoundPicker
        
    }
}


private enum conigureCustomFilterControllerSection: Int32 {
    case includeChats
    case unincludeChats
    case test
}

private enum ConigureCustomFilterControllerEntityId: Equatable, Hashable {
    case index(Int)
}

private enum ConigureCustomFilterControllerEntry: ItemListNodeEntry {
    
    case testButton(PresentationTheme, String, Int32)
    
    case includeHeader(PresentationTheme, String, Int32, Int32)
    case toggleIncludeFilter(PresentationTheme, String, Bool, String, Int32, Int32)
    case unIncludeHeader(PresentationTheme, String, Int32)
    case toggleUnincludeFilter(PresentationTheme, String, Bool, String, Int32, Int32)
    
    //               Theme              Title   Label   Filter  Picked  Index  Section
    case soundPicker(PresentationTheme, String, String, String, String, Int32, Int32)
    
    var section: ItemListSectionId {
        return 0
    }
    
    var stableId: Int32 {
        switch self {
        case let .includeHeader(_, _, headerIndex, _):
            return 10000 + headerIndex
        case let .toggleIncludeFilter(_, _, _,_, filterIndex, _):
            return 10000 + filterIndex
        case let .soundPicker(_, _, _, _, _, soundIndex, _):
            return 10000 + soundIndex
        case .unIncludeHeader:
            return 20000
        case let .toggleUnincludeFilter(_, _, _,_, filterIndex, _):
            return 20001 + filterIndex
        case .testButton:
            return 999999
        }
    }
    
    static func ==(lhs: ConigureCustomFilterControllerEntry, rhs: ConigureCustomFilterControllerEntry) -> Bool {
        switch lhs {
        case let .soundPicker(lhsTheme, lhsText, lhsValue1, lhsValue2, lhsValue3, lhsValue4, lhsValue5):
            if case let .soundPicker(rhsTheme, rhsText, rhsValue1, rhsValue2, rhsValue3, rhsValue4, rhsValue5) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue1 == rhsValue1, lhsValue2 == rhsValue2, lhsValue3 == rhsValue3, lhsValue4 == rhsValue4, lhsValue5 == rhsValue5 {
                return true
            } else {
                return false
            }
        case let .testButton(lhsTheme, lhsText, l):
            if case let .testButton(rhsTheme, rhsText, r) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, l == r {
                return true
            } else {
                return false
            }
        case let .includeHeader(lhsTheme, lhsText, l1, l):
            if case let .includeHeader(rhsTheme, rhsText, r1, r) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, l == r, l1 == r1 {
                return true
            } else {
                return false
            }
        case let .toggleIncludeFilter(lhsTheme, lhsText, lhsValue1, lhsValue2, l1, l):
            if case let .toggleIncludeFilter(rhsTheme, rhsText, rhsValue1, rhsValue2, r1, r) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue1 == rhsValue1, lhsValue2 == rhsValue2, l == r, l1==r1 {
                return true
            } else {
                return false
            }
        case let .unIncludeHeader(lhsTheme, lhsText, l):
            if case let .unIncludeHeader(rhsTheme, rhsText, r) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, l == r {
                return true
            } else {
                return false
            }
        case let .toggleUnincludeFilter(lhsTheme, lhsText, lhsValue1, lhsValue2, l1, l):
            if case let .toggleUnincludeFilter(rhsTheme, rhsText, rhsValue1, rhsValue2, r1, r) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue1 == rhsValue1, lhsValue2 == rhsValue2, l == r, l1==r1 {
                return true
            } else {
                return false
            }
        }
        
        
    }
    
    static func <(lhs: ConigureCustomFilterControllerEntry, rhs: ConigureCustomFilterControllerEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    
    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! ConigureCustomFilterControllerArguments
        switch self {
        case let .includeHeader(theme, text, _, section):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: section)
        case let .unIncludeHeader(theme, text, section):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: section)
        case let .toggleIncludeFilter(theme, title, value, filter, _, section):
            return ItemListSwitchItem(presentationData: presentationData, title: title, value: value, maximumNumberOfLines: 1, sectionId: section, style: .blocks, updated: { value in
                arguments.toggleIncludeFilter(value, filter)
            })
        case let .toggleUnincludeFilter(theme, title, value, filter, _, section):
            return ItemListSwitchItem(presentationData: presentationData, title: title, value: value, maximumNumberOfLines: 1, sectionId: section, style: .blocks, updated: { value in
                arguments.toggleUnincludeFilter(value, filter)
            })
        case let .soundPicker(theme, title, label, filter, rawValue, _, section):
            return ItemListDisclosureItem(presentationData: presentationData, title: title, label: label, sectionId: section, style: .blocks, action: {
                arguments.openSoundPicker(filter, rawValue)
            })
        case let .testButton(theme, text, section):
            return ItemListActionItem(presentationData: presentationData, title: text, kind: .generic, alignment: .natural, sectionId: section, style: .blocks, action: {
                arguments.testAction()
            })
        }
    }
    
}

private func conigureCustomFilterControllerEntries(presentationData: PresentationData, filterId: Int32) -> [ConigureCustomFilterControllerEntry] {
    var entries: [ConigureCustomFilterControllerEntry] = []
    
    let theme = presentationData.theme
    let strings = presentationData.strings
    let locale = presentationData.strings.baseLanguageCode
    
    
    //let customFilter = createOrGetCustomFilter(filterId)
    
    let customFilter = createOrGetCustomFilter(id: filterId)
    
    var sec: Int32 = 0
    for (index, filter) in IncludeFilters.enumerated() {
        // entries.append(.includeHeader(theme, filter.uppercased(), Int32( (index + 1) * 100 ), sec))
        
        
        var soundRawValue = SoundFilters[0]
        for soundSetting in SoundFilters {
            if getCustomFilterSetting(customFilter: customFilter, setting: "include.\(filter).\(soundSetting)") {
                soundRawValue = soundSetting
            }
        }
        
        
        let isEnabledFilter = isEnabledCustomFilterSetting(id: filterId, setting: "include.\(filter).\(soundRawValue)")
        
        // entries.append(.toggleIncludeFilter(theme, "\(filter)", isEnabledFilter, filter, Int32((index + 1) * 100 + 10), sec))
        
        
//        entries.append(.soundPicker(theme, "Sound Settings", l("CustomFilters.sound.\(soundRawValue)"), filter, soundRawValue, Int32((index + 1) * 100 + 10 + 1), sec))
        for (sIndex, sound) in SoundFilters.enumerated() {
            entries.append(.toggleIncludeFilter(theme, "\(filter) (\(sound))", isEnabledFilter, filter + "." + sound, Int32((index + 1) * 100 + 10 + sIndex), sec))
        }
        sec = sec + 1
    }
    
    
    #if DEBUG
    entries.append(.testButton(theme, "TEST", sec))
    #endif
    
    return entries
}


private struct PremiumSelectionState: Equatable {
    var updatingFiltersAmountValue: Int32? = nil
}

import OverlayStatusController

public func conigureCustomFilterController(context: AccountContext, customFilterId: Int32) -> ViewController {
    // let statePromise = ValuePromise(PremiumSelectionState(), ignoreRepeated: true)
    var dismissImpl: (() -> Void)?
    var presentControllerImpl: ((ViewController, Any?) -> Void)?
    let presentationData = context.sharedContext.currentPresentationData.with { $0 }
    
    let statePromise = ValuePromise(SelectionState(), ignoreRepeated: false)
    let stateValue = Atomic(value: SelectionState())
    let updateState: ((SelectionState) -> SelectionState) -> Void = { f in
        statePromise.set(stateValue.modify { f($0) })
    }
    
    
    let arguments = ConigureCustomFilterControllerArguments(toggleSetting: { value, setting in
        switch (setting) {
        case "test":
            // PremiumSettings().syncPins = value
            break
        default:
            break
        }
        updateState { state in
            return SelectionState()
        }
    }, testAction: {
        var p: RecentPeers? = nil
        let signal = recentPeers(account: context.account)
        let semaphore = DispatchSemaphore(value: 0)
        (signal
            |> take(1)
            //|> deliverOnMainQueue
            ).start(next: { value in
                print("MY VALUE", value)
                p = value
                semaphore.signal()
            })
        semaphore.wait()
        if let p = p {
        }
        print("END")
    }, toggleIncludeFilter: { value, filter in
        print(filter, value)
        
        
        
        updateState { state in
            return SelectionState()
        }
    }, toggleUnincludeFilter: { value, filter in
        
    }, openSoundPicker: { filter, rawSoundValue in
        let presentationData = context.sharedContext.currentPresentationData.with { $0 }
        let actionSheet = ActionSheetController(presentationData: presentationData)
        var items: [ActionSheetItem] = []
        let setAction: (String?) -> Void = { value in
            
            updateState { state in
                return SelectionState()
            }
        }

        
        for value in SoundFilters {
            items.append(ActionSheetButtonItem(title: value, color: .accent, action: { [weak actionSheet] in
                actionSheet?.dismissAnimated()
                setAction(value)
            }))
        }
        
        actionSheet.setItemGroups([ActionSheetItemGroup(items: items), ActionSheetItemGroup(items: [
            ActionSheetButtonItem(title: presentationData.strings.Common_Cancel, color: .accent, action: { [weak actionSheet] in
                actionSheet?.dismissAnimated()
            })
        ])])
        presentControllerImpl?(actionSheet, ViewControllerPresentationArguments(presentationAnimation: .modalSheet))
    }
    )
    
    
    
    let signal = combineLatest(context.sharedContext.presentationData, statePromise.get())
        |> map { presentationData, state -> (ItemListControllerState, (ItemListNodeState, Any)) in
            
            let entries = conigureCustomFilterControllerEntries(presentationData: presentationData, filterId: customFilterId)
            
            
            let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(l("ConfigureCustomFilterController.Title", presentationData.strings.baseLanguageCode)), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
            let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: entries, style: .blocks, ensureVisibleItemTag: nil, initialScrollToItem: nil)
            
            return (controllerState, (listState, arguments))
    }
    
    let controller = ItemListController(context: context, state: signal)
    dismissImpl = { [weak controller] in
        controller?.dismiss()
    }
    presentControllerImpl = { [weak controller] c, a in
        controller?.present(c, in: .window(.root), with: a)
    }
    return controller
}

