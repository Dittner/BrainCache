//
//  Cache.swift
//  BrainCache
//
//  Created by Alexander Dittner on 21.03.2021.
//

import Foundation

enum CacheKey: String {
    case lastOpenedFolderUID
}

class Cache {
    static func write(key: CacheKey, value: String) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }

    static func write(key: CacheKey, value: UID) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }

    static func readString(key: CacheKey) -> String? {
        UserDefaults.standard.object(forKey: key.rawValue) as? String
    }

    static func readUID(key: CacheKey) -> UID? {
        UserDefaults.standard.object(forKey: key.rawValue) as? UID
    }
}
