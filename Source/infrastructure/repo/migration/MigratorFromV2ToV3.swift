//
//  RepoManager.swift
//  BrainCache
//
//  Created by Alexander Dittner on 03.04.2021.
//

import Foundation

class MigratorFromV2ToV3: Migrator {
    let fileExtension = "bc"
    let oldVer: UInt = 2
    let newVer: UInt = 3
    let encoder: JSONEncoder
    let decoder: JSONDecoder

    init() {
        encoder = JSONEncoder()
        decoder = JSONDecoder()
    }

    func migrate() throws {
        

        let oldFoldersDirUrl = FileSystemAPI.shared.getFoldersUrl(ver: oldVer)
        let oldFilesDirUrl = FileSystemAPI.shared.getFilesUrl(ver: oldVer)

        let oldFoldersData = loadData(url: oldFoldersDirUrl, fileExtension: fileExtension)
        let oldFilesData = loadData(url: oldFilesDirUrl, fileExtension: fileExtension)
        try updateDTO(oldFoldersData, oldFilesData)
        try deleteOldVersionDir()
    }

    func loadData(url: URL, fileExtension: String) -> [Data] {
        let loadService = LoadDirectoryContentService()
        return loadService.load(url: url, fileExtension: fileExtension)
    }

    func updateDTO(_ oldFoldersData: [Data], _ oldFilesData: [Data]) throws {
        let newFoldersDirUrl = FileSystemAPI.shared.getFoldersUrl(ver: newVer)
        let newFilesDirUrl = FileSystemAPI.shared.getFilesUrl(ver: newVer)

        if !FileSystemAPI.shared.existDir(url: newFoldersDirUrl) {
            try FileSystemAPI.shared.createDir(url: newFoldersDirUrl)
        }
        if !FileSystemAPI.shared.existDir(url: newFilesDirUrl) {
            try FileSystemAPI.shared.createDir(url: newFilesDirUrl)
        }

        var folderFilesHash: [UID: [UID]] = [:] // [folderUID : [fileUID]]
        for d in oldFilesData {
            do {
                let dto_v2 = try decoder.decode(FileDTO_v2.self, from: d)
                if let folderFiles = folderFilesHash[dto_v2.folderUID] {
                    folderFilesHash[dto_v2.folderUID] = folderFiles + [dto_v2.uid]
                } else {
                    folderFilesHash[dto_v2.folderUID] = [dto_v2.uid]
                }

                let dto_v3 = FileDTO_v3(uid: dto_v2.uid, title: dto_v2.title, textBody: dto_v2.textBody, tableBody: dto_v2.tableBody, listFileBody: dto_v2.listFileBody, useMonoFont: dto_v2.useMonoFont)
                let updatedData = try encoder.encode(dto_v3)
                try updatedData.write(to: newFilesDirUrl.appendingPathComponent("\(dto_v3.uid).\(fileExtension)"))

            } catch {
                deleteNewVersionDir()
                throw MigrationError.copyFilesFailed(fromVersion: oldVer, toVersion: newVer, details: error.localizedDescription)
            }
        }

        for d in oldFoldersData {
            do {
                let dto_v2 = try decoder.decode(FolderDTO_v2.self, from: d)
                let files = folderFilesHash[dto_v2.uid] ?? []
                let dto_v3 = FolderDTO_v3(uid: dto_v2.uid, title: dto_v2.title, selectedFile: dto_v2.selectedFileUID, files: files, folders: [], isOpened: false)
                let updatedData = try encoder.encode(dto_v3)
                try updatedData.write(to: newFoldersDirUrl.appendingPathComponent("\(dto_v3.uid).\(fileExtension)"))

            } catch {
                deleteNewVersionDir()
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

    func deleteNewVersionDir() {
        let newProjectDir = FileSystemAPI.shared.projectURL.appendingPathComponent("v\(newVer)")
        try? FileSystemAPI.shared.deleteFileToTrash(from: newProjectDir)
    }
}
