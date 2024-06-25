import AccountContext
import Display
import ItemListUI
import NGAiChatUI
import SwiftSignalKit

private final class AiChatSettingsControllerArguments {}

private enum AiChatSettingsControllerSection: Int32 {
    case main
}

@available(iOS 13.0, *)
private enum AiChatSettingsControllerEntry: ItemListNodeEntry {
    case clearHistory
    
    var section: ItemListSectionId {
        switch self {
        case .clearHistory:
            return AiChatSettingsControllerSection.main.rawValue
        }
    }
    
    var stableId: Int32 {
        switch self {
        case .clearHistory:
            return 1
        }
    }
    
    static func < (lhs: AiChatSettingsControllerEntry, rhs: AiChatSettingsControllerEntry) -> Bool {
        lhs.stableId < rhs.stableId
    }
    
    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        switch self {
        case .clearHistory:
            return ItemListActionItem(presentationData: presentationData, title: AiChatUITgHelper.settingsClearHistory, kind: .destructive, alignment: .natural, sectionId: self.section, style: .blocks, action: {
                Task { await AiChatUITgHelper.presentConfirmClearHistory() }
            })
        }
    }
}

@available(iOS 13.0, *)
private func controllerEntries() -> [AiChatSettingsControllerEntry] {
    var entries: [AiChatSettingsControllerEntry] = []
    
    entries.append(.clearHistory)
    
    return entries
}

@available(iOS 13.0, *)
public func aiChatSettingsController(context: AccountContext) -> ViewController {
    let sharedContext = context.sharedContext
    
    let arguments = AiChatSettingsControllerArguments()
    
    let presentationData = sharedContext.presentationData
    
    let signal = presentationData |> map { presentationData -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let entries = controllerEntries()
        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(AiChatUITgHelper.botName), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: entries, style: .blocks)
        
        return (controllerState, (listState, arguments))
    }
    
    let controller = ItemListController(context: context, state: signal)
    
    return controller
}
