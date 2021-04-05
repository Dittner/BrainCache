//
//  RepoManager.swift
//  BrainCache
//
//  Created by Alexander Dittner on 03.04.2021.
//

import Foundation

class MigratorFromV1ToV2: Migrator {
    let fileExtension = "bc"
    let oldVer: UInt = 1
    let newVer: UInt = 2
    let encoder: JSONEncoder
    let decoder: JSONDecoder

    init() {
        encoder = JSONEncoder()
        decoder = JSONDecoder()
    }

    func migrate() throws {
        

        let oldFoldersDirUrl = FileSystemAPI.shared.getFoldersUrl(ver: oldVer)
        let newFoldersDirUrl = FileSystemAPI.shared.getFoldersUrl(ver: newVer)

        try copyFilesToNewVersionDir()
        let oldFoldersData = loadOldFoldersData(url: oldFoldersDirUrl, fileExtension: fileExtension)
        try updateDTO(from: oldFoldersData, writeTo: newFoldersDirUrl)
        try deleteOldVersionDir()
    }

    func copyFilesToNewVersionDir() throws {
        let newFoldersDir = FileSystemAPI.shared.getFoldersUrl(ver: newVer)
        let oldFilesDir = FileSystemAPI.shared.getFilesUrl(ver: oldVer)
        let newFilesDir = FileSystemAPI.shared.getFilesUrl(ver: newVer)
        
        if !FileSystemAPI.shared.existDir(url: newFoldersDir) {
            try FileSystemAPI.shared.createDir(url: newFoldersDir)
        }
        
        do {
            try FileSystemAPI.shared.copyContent(fromDir: oldFilesDir, toDir: newFilesDir)

        } catch {
            throw MigrationError.copyFilesFailed(fromVersion: oldVer, toVersion: newVer, details: error.localizedDescription)
        }
    }

    func loadOldFoldersData(url: URL, fileExtension: String) -> [Data] {
        let loadService = LoadDirectoryContentService()
        return loadService.load(url: url, fileExtension: fileExtension)
    }

    func updateDTO(from oldFoldersData: [Data], writeTo: URL) throws {
        for d in oldFoldersData {
            do {
                let dto_v1 = try decoder.decode(FolderDTO_v1.self, from: d)
                let dto_v2 = FolderDTO_v2(uid: dto_v1.uid, title: dto_v1.title, selectedFileUID: dto_v1.selectedFileUID, parentFolderUID: nil, isOpened: false)
                let updatedData = try encoder.encode(dto_v2)
                try updatedData.write(to: writeTo.appendingPathComponent("\(dto_v2.uid).\(fileExtension)"))

            } catch {
                throw MigrationError.copyFilesFailed(fromVersion: oldVer, toVersion: newVer, details: error.localizedDescription)
            }
        }
    }

    func deleteOldVersionDir() throws {
        let oldProjectDir = FileSystemAPI.shared.projectURL.appendingPathComponent("v\(oldVer)")
        do {
            try FileSystemAPI.shared.deleteFileToTrash(from: oldProjectDir)
        } catch {
            throw MigrationError.moveDirToTrashFailed(fromVersion: oldVer, toVersion: newVer, details: error.localizedDescription)
        }
    }
}
