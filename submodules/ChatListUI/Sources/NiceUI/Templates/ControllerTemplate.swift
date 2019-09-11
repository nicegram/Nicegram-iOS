////
////  ControllerTemplate.swift
////  TelegramUI
////
////  Created by Sergey on 02/08/2019.
////  Copyright © 2019 Telegram. All rights reserved.
////
//
//import Foundation
//import UIKit
//import Display
//import SwiftSignalKit
//import Postbox
//import TelegramCore
//import TelegramPresentationData
//import TelegramUIPreferences
//
//// UI
//private final class TEMPLATEControllerArguments {
//    let updateState: ((TEMPLATEControllerState) -> TEMPLATEControllerState) -> Void
//    let usePasteboardData: () -> Void
//
//    init(updateState: @escaping ((TEMPLATEControllerState) -> TEMPLATEControllerState) -> Void, usePasteboardData: @escaping () -> Void) {
//        self.updateState = updateState
//        self.usePasteboardData = usePasteboardData
//    }
//}
//
//private enum TEMPLATESection: Int32 {
//    case text
//    case url
//    case pasteboard
//}
//
//private enum TEMPLATEEntry: ItemListNodeEntry {
//    case textHeader(PresentationTheme, String)
//    case text(PresentationTheme, String)
//    case urlHeader(PresentationTheme, String)
//    case url(PresentationTheme, String, String)
//
//    case pasteboard(PresentationTheme, String)
//    case pasteboardNotice(PresentationTheme, String)
//
//    var section: ItemListSectionId {
//        switch self {
//        case .text, .textHeader:
//            return TEMPLATESection.text.rawValue
//        case .url, .urlHeader:
//            return TEMPLATESection.url.rawValue
//        case .pasteboard, .pasteboardNotice:
//            return TEMPLATESection.pasteboard.rawValue
//        }
//    }
//
//    var stableId: Int32 {
//        switch self {
//        case .textHeader:
//            return 1
//        case .text:
//            return 2
//        case .urlHeader:
//            return 3
//        case .url:
//            return 4
//        case .pasteboard:
//            return 5
//        case .pasteboardNotice:
//            return 6
//        }
//    }
//
//    static func <(lhs: TEMPLATEEntry, rhs: TEMPLATEEntry) -> Bool {
//        return lhs.stableId < rhs.stableId
//    }
//
//    func item(_ arguments: TEMPLATEControllerArguments) -> ListViewItem {
//        switch self {
//        case let .textHeader(theme, text):
//            return ItemListSectionHeaderItem(theme: theme, text: text, sectionId: self.section)
//        case let .text(theme, text):
//            return ItemListMultilineTextItem(theme: theme, text: text, enabledEntityTypes: .all, sectionId: self.section, style: .blocks)
//        case let .urlHeader(theme, text):
//            return ItemListSectionHeaderItem(theme: theme, text: text, sectionId: self.section)
//        case let .url(theme, placeholder, text):
//            return ItemListMultilineInputItem(theme: theme, text: text, placeholder: placeholder, maxLength: nil, sectionId: self.section, style: .blocks, textUpdated: { value in
//                arguments.updateState { current in
//                    var state = current
//                    state.url = value
//                    return state
//                }
//            }, action: {})
//        case let .pasteboard(theme, text):
//            return ItemListActionItem(theme: theme, title: text, kind: .generic, alignment: .center, sectionId: self.section, style: .blocks, action: {
//                arguments.usePasteboardData()
//            })
//        case let .pasteboardNotice(theme, text):
//            return ItemListTextItem(theme: theme, text: .plain(text), sectionId: self.section)
//        }
//    }
//}
//
//private struct TEMPLATEControllerState: Equatable {
//    var url: String
//    var text: String
//
//    var isComplete: Bool {
//        if self.url.isEmpty {
//            return false
//        }
//        return true
//    }
//}
//
//private func TEMPLATEControllerEntries(presentationData: (theme: PresentationTheme, strings: PresentationStrings), state: TEMPLATEControllerState) -> [TEMPLATEEntry] {
//    var entries: [TEMPLATEEntry] = []
//    entries.append(.textHeader(presentationData.theme, "TEXT"))
//    entries.append(.text(presentationData.theme, state.text))
//
//    entries.append(.urlHeader(presentationData.theme, "URL"))
//    entries.append(.url(presentationData.theme, "Url", state.url))
//
//    entries.append(.pasteboard(presentationData.theme, "Paste & Format"))
//    entries.append(.pasteboardNotice(presentationData.theme, "Instantly format text with URL from your clipboard"))
//
//    return entries
//}
//
//
////private func templateSettings(with state: TEMPLATEControllerState) -> TEMPLATESettings? {
////    if state.isComplete {
////        return TEMPLATESettings(url: state.url)
////    }
////    return nil
////}
//
//public func templateController(context: AccountContext, text: String, completion: @escaping (String) -> Void) -> ViewController {
//    let presentationData = context.sharedContext.currentPresentationData.with { $0 }
//    return templateController(theme: presentationData.theme, strings: presentationData.strings, updatedPresentationData: context.sharedContext.presentationData |> map { ($0.theme, $0.strings) }, completion: completion, text: text)
//}
//
//func templateController(theme: PresentationTheme, strings: PresentationStrings, updatedPresentationData: Signal<(theme: PresentationTheme, strings: PresentationStrings), NoError>, completion: @escaping (String) -> Void, text: String) -> ViewController {
//
//    let initialState = TEMPLATEControllerState(url: "", text: text)
//    let stateValue = Atomic(value: initialState)
//    let statePromise = ValuePromise(initialState, ignoreRepeated: true)
//    let updateState: ((TEMPLATEControllerState) -> TEMPLATEControllerState) -> Void = { f in
//        statePromise.set(stateValue.modify { f($0) })
//    }
//
//    var presentImpl: ((ViewController, Any?) -> Void)?
//    var dismissImpl: (() -> Void)?
//
//
//    let arguments = TEMPLATEControllerArguments(updateState: { f in
//        updateState(f)
//    }, usePasteboardData: {
////        let content = UIPasteboard.general.string
////        if (content != nil && !content!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
////            updateState { state in
////                var state = state
////                state.url = content!
////                return state
////            }
////            completion(content!)
////            dismissImpl?()
////        }
//    })
//
//    let signal = combineLatest(updatedPresentationData, statePromise.get())
//        |> deliverOnMainQueue
//        |> map { presentationData, state -> (ItemListControllerState, (ItemListNodeState<TEMPLATEEntry>, TEMPLATEEntry.ItemGenerationArguments)) in
//            let leftNavigationButton = ItemListNavigationButton(content: .text(presentationData.strings.Common_Cancel), style: .regular, enabled: true, action: {
//                dismissImpl?()
//            })
//            let rightNavigationButton = ItemListNavigationButton(content: .text(presentationData.strings.Common_Done), style: .bold, enabled: state.isComplete, action: {
//                completion(state.url)
//                dismissImpl?()
//            })
//
//            let controllerState = ItemListControllerState(theme: presentationData.theme, title: .text("TEMPLATE"), leftNavigationButton: leftNavigationButton, rightNavigationButton: rightNavigationButton, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back), animateChanges: false)
//            let listState = ItemListNodeState(entries: TEMPLATEControllerEntries(presentationData: presentationData, state: state), style: .blocks, emptyStateItem: nil, animateChanges: false)
//
//            return (controllerState, (listState, arguments))
//    }
//
//    let controller = ItemListController(theme: theme, strings: strings, updatedPresentationData: updatedPresentationData, state: signal, tabBarItem: nil)
//    presentImpl = { [weak controller] c, d in
//        controller?.present(c, in: .window(.root), with: d)
//    }
//    dismissImpl = { [weak controller] in
//        let _ = controller?.dismiss()
//    }
//
//    return controller
//}
