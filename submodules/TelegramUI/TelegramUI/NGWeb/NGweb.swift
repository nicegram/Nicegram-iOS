//
//  NGweb.swift
//  TelegramUI
//
//  Created by Sergey on 23/09/2019.
//  Copyright © 2019 Telegram. All rights reserved.
//

import Foundation

public var NGAPI = "https://my.nicegram.app/api/"
public var SHOW_E = false
public var BL_CH: [Int64] = []

extension String {
    func convertToDictionary() -> [String: Any]? {
        if let data = self.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
}

public func requestApi(_ path: String, pathParams: [String] = []) -> [String: Any]? {
    var result: [String: Any]? = nil
    let sem = DispatchSemaphore(value: 0)
    var urlString = NGAPI + path + "/"
    for param in pathParams {
        urlString = urlString + String(param) + "/"
    }
    let url = URL(string: urlString)!
    let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
        if let error = error {
            print("Error requesting settings: \(error)")
        } else {
            if let response = response as? HTTPURLResponse {
                // print("statusCode: \(response.statusCode)")
                if response.statusCode == 200 {
                    if let data = data, let dataString = String(data: data, encoding: .utf8) {
                        // print("data: \(dataString)")
                        result = dataString.convertToDictionary()
                    }
                }
            }
        }
        sem.signal()
    }
    task.resume()
    sem.wait()
    return result
}

public func getNGEStatus(_ userId: Int64) -> Bool {
    let response = requestApi("settings", pathParams: [String(userId)])
    var result = false
 
    if let response = response {
        if response["settings"] != nil {
            if (response["settings"]! as! [String: Any])["show_explicit"] != nil {
                result = (response["settings"]! as! [String: Any])["show_explicit"] as! Bool
            }
        }
    }
    return result
}

public func getNGBlocked() -> [Int64] {
    let response = requestApi("blocked")
    var result: [Int64] = []
    if let response = response {
        if response["chats"] != nil {
            for chat in response["chats"] as! [Any] {
                if (chat as! [String: Int64])["chat_id"] != nil {
                    result.append((chat as! [String: Int64])["chat_id"]!)
                }
            }
        }
    }
    return result
}

public func updateNGInfo(userId: Int64) {
    SHOW_E = getNGEStatus(userId)
    BL_CH = getNGBlocked()
}
