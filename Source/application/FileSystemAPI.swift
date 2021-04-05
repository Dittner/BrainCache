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

    func getLogsUrl() -> URL {
        return projectURL.appendingPathComponent(StorageDirectory.logs.rawValue)
    }
    
    func getProjectUrl(ver: UInt) -> URL {
        return projectURL.appendingPathComponent("v\(ver)")
    }

    func getFilesUrl(ver: UInt) -> URL {
        return projectURL.appendingPathComponent("v\(ver)/\(StorageDirectory.files.rawValue)")
    }

    func getFoldersUrl(ver: UInt) -> URL {
        return projectURL.appendingPathComponent("v\(ver)/\(StorageDirectory.folders.rawValue)")
    }

    func getProjectContentURLs() throws -> [URL] {
        return try FileManager.default.contentsOfDirectory(at: projectURL, includingPropertiesForKeys: nil)
    }

    func getLogsContentURLs(filesWithExtension: String) throws -> [URL] {
        let dirPath = StorageDirectory.logs.rawValue
        return try FileManager.default.contentsOfDirectory(at: projectURL.appendingPathComponent(dirPath), includingPropertiesForKeys: nil).filter { $0.pathExtension == filesWithExtension }
    }

    func existDir(url: URL) -> Bool {
        var isDir: ObjCBool = true
        return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
    }

    func createDir(url: URL) throws {
        try FileManager.default.createDirectory(atPath: url.path, withIntermediateDirectories: true, attributes: nil)
    }

    func existLogsDir() -> Bool {
        var isDir: ObjCBool = true
        return FileManager.default.fileExists(atPath: projectURL.appendingPathComponent(StorageDirectory.logs.rawValue).path, isDirectory: &isDir)
    }

    func createLogsDir() throws {
        let dirPath = StorageDirectory.logs.rawValue
        try FileManager.default.createDirectory(atPath: projectURL.appendingPathComponent(dirPath).path, withIntermediateDirectories: true, attributes: nil)
    }

    func deleteFileToTrash(from url: URL) throws {
        try FileManager.default.trashItem(at: url, resultingItemURL: nil)
    }

    func copyContent(fromDir: URL, toDir: URL) throws {
        try FileManager.default.copyItem(at: fromDir, to: toDir)
    }
}
