//
//  ManageFilters.swift
//  Nicegram
//
//  Created by Sergey Akentev on 10.11.2019. File was generated automatically
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
import OverlayStatusController


private struct SelectionState: Equatable {
}

private final class ManageFiltersArguments {
    let toggleSetting: (Bool, String) -> Void
    let toggleFilter: (Int32, Bool) -> Void
    let testAction: () -> Void
    
    init(toggleSetting:@escaping (Bool, String) -> Void, toggleFilter:@escaping (Int32, Bool) -> Void, testAction:@escaping () -> Void) {
        self.toggleSetting = toggleSetting
        self.toggleFilter = toggleFilter
        self.testAction = testAction
    }
}


private enum manageFiltersSection: Int32 {
    case filtersList
    case test
}

private enum ManageFiltersEntityId: Equatable, Hashable {
    case index(Int)
    case filter(Int32)
}

private enum ManageFiltersEntry: ItemListNodeEntry {
    case header(PresentationTheme, String)
    
    case filterSwitch(PresentationTheme, String, Bool, Int32, Int32)
    
    case configureCustom(PresentationTheme, String)
    
    var section: ItemListSectionId {
        switch self {
        case .header, .configureCustom, .filterSwitch:
            return manageFiltersSection.filtersList.rawValue
        }
        
    }
    
    var stableId: Int32 {
        switch self {
        case .header:
            return 0
        case let .filterSwitch(_, _, _, _, enumerator):
            return enumerator + 10000
        case .configureCustom:
            return 1
        }
    }
    
    static func ==(lhs: ManageFiltersEntry, rhs: ManageFiltersEntry) -> Bool {
        switch lhs {
        case let .header(lhsTheme, lhsText):
            if case let .header(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                return true
            } else {
                return false
            }
        case let .filterSwitch(lhsTheme, lhsText, lhsValue1, lhsValue2, lhsValue3):
            if case let .filterSwitch(rhsTheme, rhsText, rhsValue1, rhsValue2, rhsValue3) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue1 == rhsValue1, lhsValue2 == rhsValue2, lhsValue3 == rhsValue3 {
                return true
            } else {
                return false
            }
        case let .configureCustom(lhsTheme, lhsText):
            if case let .configureCustom(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                return true
            } else {
                return false
            }
        }
        
    }
    
    static func <(lhs: ManageFiltersEntry, rhs: ManageFiltersEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    
    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! ManageFiltersArguments
        switch self {
        case let .header(theme, text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .filterSwitch(theme, title, value, filter, _):
            return ItemListSwitchItem(presentationData: presentationData, title: title, value: value, maximumNumberOfLines: 1, sectionId: self.section, style: .blocks, updated: { value in
                arguments.toggleFilter(filter, value)
            })
        case let .configureCustom(theme, text):
            return ItemListDisclosureItem(presentationData: presentationData, title: text, label: "", sectionId: self.section, style: .blocks, action: {
                arguments.testAction()
            })
        }
    }
    
}


private func manageFiltersEntries(presentationData: PresentationData) -> [ManageFiltersEntry] {
    var entries: [ManageFiltersEntry] = []
    
    let theme = presentationData.theme
    let strings = presentationData.strings
    let locale = presentationData.strings.baseLanguageCode
    
    entries.append(.header(theme, l("ManageFilters.Header", locale)))
    
    // entries.append(.configureCustom(theme, l("ConfigureCustomFilterController.Title", locale)))
    for (index, filter) in NiceChatListNodePeersFilter.all.reversed().enumerated() {
        entries.append(.filterSwitch(theme, l(getFilterTabName(filter: filter), locale), isEnabledFilter(filter.rawValue), filter.rawValue, Int32(index)))
    }
    
//    #if DEBUG
//    entries.append(.configureCustom(theme, "TEST"))
//    #endif
    
    return entries
}


private struct PremiumSelectionState: Equatable {
    var updatingFiltersAmountValue: Int32? = nil
}


public func manageFilters(context: AccountContext) -> ViewController {
    // let statePromise = ValuePromise(PremiumSelectionState(), ignoreRepeated: true)
    var dismissImpl: (() -> Void)?
    let openEditingDisposable = MetaDisposable()
    var cancelImpl: (() -> Void)?
    var presentControllerImpl: ((ViewController, Any?) -> Void)?
    let presentationData = context.sharedContext.currentPresentationData.with { $0 }
    var pushControllerImpl: ((ViewController) -> Void)?

    let statePromise = ValuePromise(SelectionState(), ignoreRepeated: false)
    let stateValue = Atomic(value: SelectionState())
    let updateState: ((SelectionState) -> SelectionState) -> Void = { f in
        statePromise.set(stateValue.modify { f($0) })
    }
    
    
    let arguments = ManageFiltersArguments(toggleSetting: { value, setting in
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
    }, toggleFilter: { filter, value in
        if value {
            print("Enabling filter")
            enableFilter(filter)
        } else {

            print("Disabling filter")
            disableFilter(filter)
        }
        print(SimplyNiceFilters().disabledFilters)
    }, testAction: {
        print("TAPPED")
//        Queue.mainQueue().async {
//            let controller = OverlayStatusController(theme: presentationData.theme, strings: presentationData.strings,  type: .loading(cancelled: {
//                cancelImpl?()
//            }))
//            presentControllerImpl?(controller, nil)
//        }
        pushControllerImpl?(conigureCustomFilterController(context: context, customFilterId: 0))
    }
    )
    
    
    
    let signal = combineLatest(context.sharedContext.presentationData, statePromise.get())
        |> map { presentationData, state -> (ItemListControllerState, (ItemListNodeState, Any)) in
            
            let entries = manageFiltersEntries(presentationData: presentationData)
            
            
            let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(l("ManageFilters.Title", presentationData.strings.baseLanguageCode)), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
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
    pushControllerImpl = { [weak controller] c in
        (controller?.navigationController as? NavigationController)?.pushViewController(c)
    }
    cancelImpl = {
        openEditingDisposable.set(nil)
    }
    
    return controller
}

