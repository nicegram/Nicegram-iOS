//
//  NewFolderListController.swift
//  TelegramUI
//
//  Created by Sergey Ak on 02/08/2019.
//  Copyright © 2019 Nicegram. All rights reserved.
//

import Foundation
import UIKit
import Display
import SwiftSignalKit
import Postbox
import TelegramCore
import TelegramPresentationData
import TelegramUIPreferences
import ItemListUI
import ItemListPeerActionItem
import AccountContext

private final class NewFolderListControllerArguments {
    let createNew: () -> (Void)
    let addToExisting: (NiceFolder) -> (Void)
    let archive: () -> (Void)
    
    init(createNew:@escaping () -> (Void), addToExisting:@escaping (NiceFolder) -> (Void), archive:@escaping () -> (Void)) {
        self.createNew = createNew
        self.addToExisting = addToExisting
        self.archive = archive
    }
}

private enum NewFolderListSection: Int32 {
    case actions
    case archive
    case folders
}

private enum NewFolderListEntryStableId: Equatable, Hashable {
    case index(Int)
//    case create
//    case archive
//    case foldersHeader
//    case folder(Int32)
}

private enum NewFolderListEntry: ItemListNodeEntry {
    case create(PresentationTheme, String)
    case archive(PresentationTheme, String)
    case foldersHeader(PresentationTheme, String)
    case folderItem(Int32, PresentationTheme, PresentationStrings, NiceFolder)
    
    var section: ItemListSectionId {
        switch self {
        case .create:
            return NewFolderListSection.actions.rawValue
        case .archive:
            return NewFolderListSection.archive.rawValue
        case .folderItem, .foldersHeader:
            return NewFolderListSection.folders.rawValue
        }
    }
    
    var stableId: Int32 {
        switch self {
        case .create:
            return 0
        case .archive:
            return 1
        case .foldersHeader:
            return 2
        case let .folderItem(_, _, _, folder):
            return 100 + folder.groupId
        }
    }
    
    static func ==(lhs: NewFolderListEntry, rhs: NewFolderListEntry) -> Bool {
        switch lhs {
        case let .create(lhsTheme, lhsText):
            if case let .create(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                return true
            } else {
                return false
            }
        case let .archive(lhsTheme, lhsText):
            if case let .archive(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                return true
            } else {
                return false
            }
        case let .foldersHeader(lhsTheme, lhsText):
            if case let .foldersHeader(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                return true
            } else {
                return false
            }
        case let .folderItem(lhsIndex, lhsTheme, lhsStrings, lhsDateTimeFormat):
            if case let .folderItem(rhsIndex, rhsTheme, rhsStrings, rhsDateTimeFormat) = rhs {
                if lhsIndex != rhsIndex {
                    return false
                }
                if lhsTheme !== rhsTheme {
                    return false
                }
                if lhsStrings !== rhsStrings {
                    return false
                }
                if lhsDateTimeFormat != rhsDateTimeFormat {
                    return false
                }
                return true
            } else {
                return false
            }
        }
    }
    
    static func <(lhs: NewFolderListEntry, rhs: NewFolderListEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    
    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! NewFolderListControllerArguments
        switch self {
        case let .create(theme, text):
            return ItemListPeerActionItem(presentationData: presentationData, icon: PresentationResourcesItemList.plusIconImage(theme), title: text, sectionId: self.section, editing: false, action: {
                arguments.createNew()
            })
        case let .archive(theme, text):
            return ItemListPeerActionItem(presentationData: presentationData, icon: PresentationResourcesItemList.archiveIcon(theme), title: text, sectionId: self.section, editing: false, action: {
                arguments.archive()
            })
        case let .foldersHeader(theme, text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .folderItem(_, theme, _, folder):
            return ItemListActionItem(presentationData: presentationData, title: folder.name, kind: .neutral, alignment: .natural, sectionId: self.section, style: .blocks, action: {
                arguments.addToExisting(folder)
            })
        }
    }
}

private struct NewFolderListControllerState: Equatable {
    let editing: Bool
    let peerIdWithRevealedOptions: PeerId?
    let removingPeerId: PeerId?
    
    init() {
        self.editing = false
        self.peerIdWithRevealedOptions = nil
        self.removingPeerId = nil
    }
    
    init(editing: Bool, peerIdWithRevealedOptions: PeerId?, removingPeerId: PeerId?) {
        self.editing = editing
        self.peerIdWithRevealedOptions = peerIdWithRevealedOptions
        self.removingPeerId = removingPeerId
    }
    
    static func ==(lhs: NewFolderListControllerState, rhs: NewFolderListControllerState) -> Bool {
        if lhs.editing != rhs.editing {
            return false
        }
        if lhs.peerIdWithRevealedOptions != rhs.peerIdWithRevealedOptions {
            return false
        }
        if lhs.removingPeerId != rhs.removingPeerId {
            return false
        }
        
        return true
    }
    
    func withUpdatedEditing(_ editing: Bool) -> NewFolderListControllerState {
        return NewFolderListControllerState(editing: editing, peerIdWithRevealedOptions: self.peerIdWithRevealedOptions, removingPeerId: self.removingPeerId)
    }
    
    func withUpdatedPeerIdWithRevealedOptions(_ peerIdWithRevealedOptions: PeerId?) -> NewFolderListControllerState {
        return NewFolderListControllerState(editing: self.editing, peerIdWithRevealedOptions: peerIdWithRevealedOptions, removingPeerId: self.removingPeerId)
    }
    
    func withUpdatedRemovingPeerId(_ removingPeerId: PeerId?) -> NewFolderListControllerState {
        return NewFolderListControllerState(editing: self.editing, peerIdWithRevealedOptions: self.peerIdWithRevealedOptions, removingPeerId: removingPeerId)
    }
}

private func newFolderListControllerEntries(presentationData: PresentationData) -> [NewFolderListEntry] {
    var entries: [NewFolderListEntry] = []
    
    entries.append(.create(presentationData.theme, l("Folder.Create", presentationData.strings.baseLanguageCode)))
    print("NICE FOLDER \(getNiceFolders())")
    
    entries.append(.archive(presentationData.theme, presentationData.strings.ChatList_ArchiveAction))
    
    if getNiceFolders().count > 0 {
        entries.append(.foldersHeader(presentationData.theme, l("Folder.AddToExisting", presentationData.strings.baseLanguageCode).uppercased()))
    }
    
    
    var index: Int32 = 0
    for folder in getNiceFolders() {
        entries.append(.folderItem(index, presentationData.theme, presentationData.strings, folder))
        index += 1
    }
    
    return entries
}

private struct NewFolderListSelectionState: Equatable {
}

public func newFolderListController(context: AccountContext, parent: ChatListControllerImpl, peerIds: [PeerId]) -> ViewController {
    let statePromise = ValuePromise(NewFolderListSelectionState(), ignoreRepeated: true)
    var dismissImpl: (() -> Void)?
    var presentControllerImpl: ((ViewController, Any?) -> Void)?
    let presentationData = context.sharedContext.currentPresentationData.with { $0 }
    let locale = presentationData.strings.baseLanguageCode
    
    func updateTabs() {
    }
    
    let arguments = NewFolderListControllerArguments(
    createNew: {
        if getNiceFolders().count >= 3 && !canUnlimFolders() {
            let controller = standardTextAlertController(theme: AlertControllerTheme(presentationData: presentationData), title: nil, text: l("Folder.LimitExceeded", locale), actions: [TextAlertAction(type: .genericAction, title: "OK", action: {})])
            presentControllerImpl?(controller, nil)
        } else {
            var text: String?
            let controller = textInputController(sharedContext: context.sharedContext, account: context.account, text: text ?? "", input: nil, apply: { input in
                if let input = input {
                    dismissImpl?()
                    fLog("Naming \(input)")
                    parent.folderChats(peerIds: peerIds, name: input)
                    parent.donePressed()
                }
                }, title: l("Folder.Create.Name", locale), subtitle: "", placeholder: l("Folder.Create.Placeholder", locale))
            presentControllerImpl?(controller, nil)
        }
        
    }, addToExisting: { folder in
        dismissImpl?()
        fLog("Addded \(peerIds.count) peers to \(folder)")
        parent.folderChats(peerIds: peerIds, name: nil, existingFolder: folder)
        parent.donePressed()
    }, archive : {
        dismissImpl?()
        parent.archiveChats(peerIds: peerIds)
        parent.donePressed()
    })
    
    
    let signal = combineLatest(context.sharedContext.presentationData, statePromise.get())
        |> map { presentationData,  state -> (ItemListControllerState, (ItemListNodeState, Any)) in
            
            let entries = newFolderListControllerEntries(presentationData: presentationData)
            
            var index = 0
            var scrollToItem: ListViewScrollToItem?
            // workaround
            let focusOnItemTag: FakeEntryTag? = nil
            if let focusOnItemTag = focusOnItemTag {
                for entry in entries {
                    if entry.tag?.isEqual(to: focusOnItemTag) ?? false {
                        scrollToItem = ListViewScrollToItem(index: index, position: .top(0.0), animated: false, curve: .Default(duration: 0.0), directionHint: .Up)
                    }
                    index += 1
                }
            }
            
            let leftNavigationButton = ItemListNavigationButton(content: .text(presentationData.strings.Common_Cancel), style: .regular, enabled: true, action: {
                dismissImpl?()
            })
            
            let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(l("Folder.New", presentationData.strings.baseLanguageCode)), leftNavigationButton: leftNavigationButton, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
            let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: entries, style: .blocks, ensureVisibleItemTag: focusOnItemTag, initialScrollToItem: scrollToItem)
            
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
