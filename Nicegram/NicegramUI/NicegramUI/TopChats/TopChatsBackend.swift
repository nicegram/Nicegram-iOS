//
//  TopChatsBackend.swift
//  AsyncUI#shared
//
//  Created by Sergey on 10.02.2020.
//

import Foundation
import UIKit

let ARCHIVE_URL = "https://github.com/Kylmakalle/topchats/archive/latest.zip"
let JSON_URL = "https://github.com/Kylmakalle/topchats/raw/master/topchats.json"
let ORIG_JSON_URL = "https://combot.org/telegram/top/chats/langs/all.json"
let FILE_NAME = "topchats.json"
let AVATAR_URL = "https://ant.combot.org/a/ch/"

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
                        let img: UIImage! = UIImage(data: data)
                        self.cache.setObject(img, forKey: imagePath as NSString)
                        DispatchQueue.main.async {
                            completionHandler(img)
                        }
                    }
                }
            })
            task.resume()
        }
    }
}
