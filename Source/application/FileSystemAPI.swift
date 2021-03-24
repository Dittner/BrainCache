//
//  DocumentsStorage.swift
//  BrainCache
//
//  Created by Alexander Dittner on 13.02.2020.
//  Copyright © 2020 Alexander Dittner. All rights reserved.
//

import Foundation
enum StorageDirectory: String {
    case project = "BrainCache"
    case dropbox = "Dropbox"
    case logs
    case folders
    case files
}

class FileSystemAPI {
    static var shared: FileSystemAPI!

    let documentsURL: URL
    let projectURL: URL

    init(documentsURL: URL) {
        self.documentsURL = documentsURL
        projectURL = documentsURL.appendingPathComponent(StorageDirectory.project.rawValue)
    }

    func getUrl(of dir: StorageDirectory) -> URL {
        return projectURL.appendingPathComponent(dir.rawValue)
    }

    func existDir(_ dir: StorageDirectory) -> Bool {
        let dirPath = dir.rawValue
        var isDir: ObjCBool = true
        return FileManager.default.fileExists(atPath: projectURL.appendingPathComponent(dirPath).path, isDirectory: &isDir)
    }

    func createDir(_ dir: StorageDirectory) throws {
        let dirPath = dir.rawValue
        try FileManager.default.createDirectory(atPath: projectURL.appendingPathComponent(dirPath).path, withIntermediateDirectories: true, attributes: nil)
    }

    func getURLs(dir: StorageDirectory, filesWithExtension: String) throws -> [URL] {
        let dirPath = dir.rawValue
        return try FileManager.default.contentsOfDirectory(at: projectURL.appendingPathComponent(dirPath), includingPropertiesForKeys: nil).filter { $0.pathExtension == filesWithExtension }
    }

    func deleteFile(from url: URL) throws {
        try FileManager.default.trashItem(at: url, resultingItemURL: nil)
    }
}
