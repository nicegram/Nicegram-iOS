//
//  RegDate.swift
//  NicegramLib
//
//  Created by Sergey on 23.11.2019.
//  Copyright © 2019 Nicegram. All rights reserved.
//

import Foundation
import SwiftSignalKit
import NGEnv
import NGDeviceCheck

public enum RegDateError {
    case generic
    case badDeviceToken
}

struct RegDate: Codable {   
    let data: RegDateData
    
    enum CodingKeys: String, CodingKey {
        case data
    }
    
    struct RegDateData: Codable {
        let type: RegDateType
        let date: String

        enum CodingKeys: String, CodingKey {
            case type, date
        }
        
        enum RegDateType: String, Codable {
            case older = "TYPE_OLDER"
            case approx = "TYPE_APPROX"
            case exactly = "TYPE_EXACTLY"
            case newer = "TYPE_NEWER"
        }
    }
}


public func requestRegDate(jsonData: Data) -> Signal<String, RegDateError> {
    return Signal { subscriber in
        let completed = Atomic<Bool>(value: false)

        var request = URLRequest(url: URL(string: "\(NGENV.ng_api_url)/v7/regdate")!)

        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // insert json data to the request
        request.httpBody = jsonData as Data
        request.timeoutInterval = 10
        let downloadTask = URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
            let _ = completed.swap(true)
            if let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    if let data = data {
                        do {  
                            let decoder = JSONDecoder()
                            let gitData = try decoder.decode(RegDate.self, from: data)
                            subscriber.putNext(gitData.data.date)
                        } catch {
                            subscriber.putError(.generic)
                        }
                    } else {
                        subscriber.putError(.generic)
                    }
                } else {
                    subscriber.putError(.generic)
                }
            } else {
                subscriber.putError(.generic)
            }
        })
        downloadTask.resume()
        
        return ActionDisposable {
            if !completed.with({ $0 }) {
                downloadTask.cancel()
            }
        }
    }
}


public func getRegDate(_ userId: Int64) -> Signal<String, RegDateError> {
    return Signal { subscriber in
        let requestSignal = requestRegDate(jsonData: prepareRegDateData(userId))
        let _ = (requestSignal |> deliverOnMainQueue).start(next: { responseDate in
            setCachedRegDate(userId, responseDate)
            subscriber.putNext(responseDate)
            subscriber.putCompletion()
        }, error: { _ in
            subscriber.putError(.generic)
        })
        return ActionDisposable {}
    }
}

func prepareRegDateData(_ userId: Int64) -> Data {
    let json = ["telegramId": userId] as [String : Any]
    let jsonData = try! JSONSerialization.data(withJSONObject: json)
    return jsonData
}

public func getCachedRegDate(_ userId: Int64) -> String? {
    let UD = UserDefaults(suiteName: "CachedRegDate")
    if let regDate = UD?.string(forKey: "RD:\(userId)"), !regDate.isEmpty {
        return regDate
    }
    
    return nil
}

public func setCachedRegDate(_ userId: Int64, _ ts: String) -> Void {
    let UD = UserDefaults(suiteName: "CachedRegDate")
    UD?.set(ts, forKey: "RD:\(userId)")
}

public func makeNiceRegDateStr(_ date: String) -> String {
    let monthDateFormatter = DateFormatter()
    monthDateFormatter.dateFormat = "yyyy-MM"
    
    let dayDateFormatter = DateFormatter()
    dayDateFormatter.dateFormat = "yyyy-MM-dd"
    
    var convertDateFormatter = DateFormatter()
    
    if let monthDate = monthDateFormatter.date(from: date) {
        convertDateFormatter.dateFormat = "~ MMMM yyyy"
        
        return convertDateFormatter.string(from: monthDate)
    } else if let dayDate = dayDateFormatter.date(from: date) {
        convertDateFormatter.dateFormat = "dd MMMM yyyy"
        
        return convertDateFormatter.string(from: dayDate)
    }  else {
        return ""
    }
}


public func resetRegDateCache() -> Void {
    UserDefaults.standard.removePersistentDomain(forName: "CachedRegDate")
}

