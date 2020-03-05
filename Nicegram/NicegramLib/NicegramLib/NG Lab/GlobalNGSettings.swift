//
//  GlobalNGSettings.swift
//  NicegramLib
//
//  Created by mac-zen on 2/21/20.
//

import Foundation


struct GlobalNGSettingsObj: Decodable {
    let gmod: Bool
    let youtube_pip: Bool
    let qr_login_camera: Bool
    let gmod2: Bool
    let gmod3: Bool
}

public var VarGNGSettings = GNGSettings()

public class GNGSettings {
    let UD = UserDefaults(suiteName: "GlobalNGSettings")
    
    public init() {
        UD?.register(defaults:
        [
            "gmod": false,
            "youtube_pip": true,
            "qr_login_camera": false,
            "gmod2": false,
            "gmod3": false
        ])
    }
    
    public var gmod: Bool {
        get {
            return UD?.bool(forKey: "gmod") ?? false
        }
        set {
            UD?.set(newValue, forKey: "gmod")
        }
    }
    
    public var youtube_pip: Bool {
        get {
            return UD?.bool(forKey: "youtube_pip") ?? true
        }
        set {
            UD?.set(newValue, forKey: "youtube_pip")
        }
    }
    
    public var qr_login_camera: Bool {
        get {
            return UD?.bool(forKey: "qr_login_camera") ?? false
        }
        set {
            UD?.set(newValue, forKey: "qr_login_camera")
        }
    }
    
    public var gmod2: Bool {
        get {
            return UD?.bool(forKey: "gmod2") ?? false
        }
        set {
            UD?.set(newValue, forKey: "gmod2")
        }
    }
    
    public var gmod3: Bool {
        get {
            return UD?.bool(forKey: "gmod3") ?? false
        }
        set {
            UD?.set(newValue, forKey: "gmod3")
        }
    }
}

public func updateGlobalNGSettings() {
    let url = "https://raw.githubusercontent.com/nicegram/settings/master/global.json"
    URLSession(configuration: URLSessionConfiguration.default).dataTask(with: URL(string: url)!) { data, response, error in
          // ensure there is data returned from this HTTP response
         guard let data = data else {
              print("No data")
              return
         }

          // Parse JSON into Post array struct using JSONDecoder
          guard let parsedSettings = try? JSONDecoder().decode(GlobalNGSettingsObj.self, from: data) else {
              print("Error: Couldn't decode data into globalsettings model")
              return
          }
        print("GlobalSettings \(parsedSettings)")
        let currentSettings = VarGNGSettings
        currentSettings.gmod = parsedSettings.gmod
        currentSettings.youtube_pip = parsedSettings.youtube_pip
        currentSettings.qr_login_camera = parsedSettings.qr_login_camera
        currentSettings.gmod2 = parsedSettings.gmod2
        currentSettings.gmod3 = parsedSettings.gmod3
    }.resume()
}


