//
//  FolderSerializer_v1.swift
//  BrainCache
//
//  Created by Alexander Dittner on 12.02.2021.
//

import Foundation

enum FolderSerializerError: DetailedError {
    case childFolderNotFound(parentFolderUID: UID, details: String)
    case childFileNotFound(parentFolderUID: UID, details: String)
}

class FolderSerializer: ISerializer {
    typealias Entity = Folder
    typealias FolderDTO = FolderDTO_v3

    let dispatcher: DomainEventDispatcher
    let encoder: JSONEncoder
    let decoder: JSONDecoder

    var filesHash: [UID: File] = [:]
    var foldersDTOHash: [UID: FolderDTO] = [:]
    var hash: [UID: Folder] = [:]

    init(files: [File], foldersData: [Data], dispatcher: DomainEventDispatcher) {
        self.dispatcher = dispatcher
        encoder = JSONEncoder()
        decoder = JSONDecoder()

        files.forEach { filesHash[$0.uid] = $0 }
        foldersData.map { try? decoder.decode(FolderDTO.self, from: $0) }.compactMap { $0 }.forEach { foldersDTOHash[$0.uid] = $0 }
    }

    func serialize(_ e: Folder) throws -> Data {
        let dto = FolderDTO(uid: e.uid, title: e.title, selectedFile: e.selectedFile?.uid, files: e.files.map { $0.uid }, folders: e.folders.map { $0.uid }, isOpened: e.isOpened)
        return try encoder.encode(dto)
    }

    func deserialize(data: Data) throws -> Folder {
        let dto = try decoder.decode(FolderDTO.self, from: data)
        return try createFolder(dto: dto)
    }

    private func createFolder(dto: FolderDTO) throws -> Folder {
        if let f = hash[dto.uid] { return f }
        
        var files: [File] = []
        for uid in dto.files {
            if let childFile = filesHash[uid] {
                files.append(childFile)
            } else {
                throw FolderSerializerError.childFileNotFound(parentFolderUID: dto.uid, details: "Child file uid = \(uid)")
            }
        }

        var folders: [Folder] = []
        for uid in dto.folders {
            if let childFolderDTO = foldersDTOHash[uid] {
                folders.append(try createFolder(dto: childFolderDTO))
            } else {
                throw FolderSerializerError.childFolderNotFound(parentFolderUID: dto.uid, details: "Child folder uid = \(uid)")
            }
        }

        var selectedFile: File?
        if let selectedFileUID = dto.selectedFile {
            selectedFile = filesHash[selectedFileUID]
        }

        let parentFolder = Folder(uid: dto.uid, title: dto.title, selectedFile: selectedFile, files: files, folders: folders, isOpened: dto.isOpened, dispatcher: dispatcher)

        files.forEach { $0.update(parent: parentFolder) }
        folders.forEach { $0.update(parent: parentFolder) }

        hash[parentFolder.uid] = parentFolder
        return parentFolder
    }
}
