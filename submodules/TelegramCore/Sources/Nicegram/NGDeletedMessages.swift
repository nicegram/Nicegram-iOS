import Foundation
import Postbox
import SwiftSignalKit

public struct NGDeletedMessages {}

public extension NGDeletedMessages {
    static var showDeletedMessages: Bool {
        get {
            UserDefaults.standard.bool(forKey: "ng_showDeletedMessages")
        } set {
            UserDefaults.standard.setValue(newValue, forKey: "ng_showDeletedMessages")
        }
    }
    
    static func actuallyDeleteMarkedMessages(
        postbox: Postbox
    ) -> Signal<Void, NoError> {
        postbox.transaction { transaction in
            let ids = transaction.allMessageIds { attributes in
                for attribute in attributes {
                    if let nicegramAttribute = attribute as? NicegramMessageAttribute,
                       nicegramAttribute.isDeleted {
                        return true
                    }
                }
                return false
            }
            
            _internal_deleteMessages(
                transaction: transaction,
                mediaBox: postbox.mediaBox,
                ids: ids
            )
        }
    }
}

extension NGDeletedMessages {
    static func markMessagesAsDeleted(
        globalIds: [Int32],
        transaction: Transaction
    ) -> [Int32] {
        guard showDeletedMessages else {
            return globalIds
        }
        
        var markedIds: [Int32] = []
        
        for globalId in globalIds {
            if let id = transaction.messageIdsForGlobalIds([globalId]).first {
                transaction.updateNicegramAttribute(messageId: id) {
                    if !$0.isDeleted {
                        $0.isDeleted = true
                        markedIds.append(globalId)
                    }
                }
            }
        }
        
        let unmarkedIds = Set(globalIds).subtracting(markedIds)
        
        return Array(unmarkedIds)
    }

    static func markMessagesAsDeleted(
        ids: [MessageId],
        transaction: Transaction
    ) -> [MessageId] {
        guard showDeletedMessages else {
            return ids
        }
        
        var markedIds: [MessageId] = []
        
        for id in ids {
            transaction.updateNicegramAttribute(messageId: id) {
                if !$0.isDeleted {
                    $0.isDeleted = true
                    markedIds.append(id)
                }
            }
        }
        
        let unmarkedIds = Set(ids).subtracting(markedIds)
        
        return Array(unmarkedIds)
    }
}


