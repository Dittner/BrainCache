//
//  BrainCacheContext.swift
//  BrainCache
//
//  Created by Alexander Dittner on 27.02.2020.
//  Copyright © 2020 Alexander Dittner. All rights reserved.
//

import Combine
import Foundation
import SwiftUI

class BrainCacheContext: ObservableObject {
    static var shared = BrainCacheContext()

    let dispatcher: DomainEventDispatcher
    let foldersRepo: JSONRepository<Folder>
    let filesRepo: JSONRepository<File>
    let menuAPI: MenuAPI
    let entityRemover: DomainEntityRemover

    init() {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dropboxUrl = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(StorageDirectory.dropbox.rawValue)

        var isDir: ObjCBool = true
        let hasDropboxProjectDir = FileManager.default.fileExists(atPath: dropboxUrl.appendingPathComponent(StorageDirectory.project.rawValue).path, isDirectory: &isDir)

        FileSystemAPI.shared = FileSystemAPI(documentsURL: hasDropboxProjectDir ? dropboxUrl : documentsURL)

        Logger.run()
        BrainCacheContext.logAbout()
        logInfo(msg: "BrainCacheContext init")

        dispatcher = DomainEventDispatcher()
        menuAPI = MenuAPI()
        entityRemover = DomainEntityRemover()

        let folderSerializer = FolderSerializer_v1(dispatcher: dispatcher)
        foldersRepo = JSONRepository<Folder>(repoID: .folder, dispatcher: dispatcher, storeTo: FileSystemAPI.shared.getUrl(of: .folders), serialize: folderSerializer.serialize, deserialize: folderSerializer.deserialize)

        let fileSerializer = FileSerializer_v1(dispatcher: dispatcher)
        filesRepo = JSONRepository<File>(repoID: .file, dispatcher: dispatcher, storeTo: FileSystemAPI.shared.getUrl(of: .files), serialize: fileSerializer.serialize, deserialize: fileSerializer.deserialize)
    }

    static func logAbout() {
        var aboutLog: String = "BrainCache Logs\n"
        let ver: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
        let build: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
        aboutLog += "v." + ver + "." + build + "\n"

        #if DEBUG
            aboutLog += "debug mode\n"
            aboutLog += "docs folder: \\" + FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].description
        #else
            aboutLog += "release mode\n"
        #endif

        let home = FileManager.default.homeDirectoryForCurrentUser
        print("home dir = \(home.description)")

        logInfo(msg: aboutLog)
    }

    func run() {
    }
}
