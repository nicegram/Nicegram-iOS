#if CN
//
//  TopChatsBackend.swift
//  AsyncUI#shared
//
//  Created by Sergey on 10.02.2020.
//

import Foundation
import UIKit

// let ARCHIVE_URL = "https://github.com/Kylmakalle/topchats/archive/latest.zip"
let JSON_URL = "https://github.com/Kylmakalle/topchats/raw/master/topchats.json"
// let ORIG_JSON_URL = "https://combot.org/telegram/top/chats/langs/all.json"
let FILE_NAME = "topchats.json"
// let AVATAR_URL = "https://ant.combot.org/a/ch/"

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

func code_to_lang_emoji(_ lang: String) -> (String, String) {
    switch (lang) {
    case "RU":
        return ("Русский", "🇷🇺")
    case "EN":
        return ("English", "🇬🇧")
    case "UZ":
        return ("Oʻzbek", "🇺🇿")
    case "ES":
        return ("Español", "🇪🇸")
    case "IT":
        return ("Italiano", "🇮🇹")
    case "PT":
        return ("Português", "🇵🇹")
    case "ID":
        return ("Indonesia", "🇮🇩")
    case "TR":
        return ("Türkçe", "🇹🇷")
    case "ZH":
        return ("中文", "ZH")
    case "DE":
        return ("Deutsch", "🇩🇪")
    case "VI":
        return ("Tiếng Việt", "🇻🇳")
    case "KO":
        return ("한국어", "🇰🇷")
    case "UK":
        return ("Українська", "🇺🇦")
    case "FA":
        return ("فارسی", "🇮🇷")
    case "AR":
        return ("العربية","🇦🇪/🇸🇦")
    case "HI":
        return ("हिंदी", "🇮🇳")
    case "NL":
        return ("Nederlands", "🇳🇱")
    case "FR":
        return ("Français","🇫🇷")
    case "JA":
        return ("日本語", "🇯🇵")
    case "MA":
        return ("Malay", "🇲🇾")
    case "IW":
        return ("עברית", "🇮🇱")
    case "PL":
        return ("Polski","🇵🇱")
    case "ML":
        return ("മലയാളം", "ML")
    case "ZH-HANS":
        return ("简体中文", "🇨🇳")
    case "ZH-HANT":
        return ("正體中文", "🇹🇼")
    default:
        return (lang, lang)
    }
}


typealias ImageCacheLoaderCompletionHandler = ((UIImage) -> ())

class ImageCacheLoader {

    var task: URLSessionDownloadTask!
    var session: URLSession!
    var cache: NSCache<NSString, UIImage>!

    init() {
        session = URLSession.shared
        task = URLSessionDownloadTask()
        self.cache = NSCache()
    }

    func obtainImageWithPath(imagePath: String, completionHandler: @escaping ImageCacheLoaderCompletionHandler) {
        if let image = self.cache.object(forKey: imagePath as NSString) {
            DispatchQueue.main.async {
                completionHandler(image)
            }
        } else {
            /* You need placeholder image in your assets,
               if you want to display a placeholder to user */
            let placeholder = UIImage(bundleImageName: "Contact List/CreateGroupActionIcon")!
            DispatchQueue.main.async {
                completionHandler(placeholder)
            }
            let url: URL! = URL(string: imagePath)
            task = session.downloadTask(with: url, completionHandler: { (location, response, error) in
                if let location = location {
                    if let data = try? Data(contentsOf: location) {
                        if let img = UIImage(data: data) {
                            self.cache.setObject(img, forKey: imagePath as NSString)
                            DispatchQueue.main.async {
                                completionHandler(img)
                            }
                        }
                    }
                }
            })
            task.resume()
        }
    }
}
#endif
