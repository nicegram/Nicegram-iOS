//
//  TopChatsBackend.swift
//  AsyncUI#shared
//
//  Created by Sergey on 10.02.2020.
//

import Foundation

let JSON_URL = "https://combot.org/telegram/top/chats/langs/all.json"


struct TopChat: Decodable {
    let title : String
    let username : String
    let pc : String
    let lang : String
    let image: String
    let a: String
    let position: Int
    
    enum CodingKeys : String, CodingKey {
        case title = "t"
        case username = "u"
        case pc
        case lang = "l"
        case image = "i"
        case a
        case position = "p"
    }
}

