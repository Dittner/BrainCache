//
//  FolderStorage.swift
//  BrainCache
//
//  Created by Alexander Dittner on 23.03.2021.
//

import Combine
import SwiftUI

class FolderStorage {
    let subject = CurrentValueSubject<[Folder], Never>([])
    private let dispatcher: DomainEventDispatcher

    private let foldersRepo: JSONRepository<Folder>
    private let filesRepo: JSONRepository<File>
    private var fileSerializer: FileSerializer?
    private var folderSerializer: FolderSerializer?
    private let modelVersion: UInt

    private var disposeBag: Set<AnyCancellable> = []
    init(modelVersion: UInt, fileExtension: String, dispatcher: DomainEventDispatcher) {
        self.modelVersion = modelVersion
        self.dispatcher = dispatcher
        filesRepo = JSONRepository<File>(repoID: .file, url: FileSystemAPI.shared.getFilesUrl(ver: modelVersion), fileExtension: fileExtension, dispatcher: dispatcher)
        foldersRepo = JSONRepository<Folder>(repoID: .folder, url: FileSystemAPI.shared.getFoldersUrl(ver: modelVersion), fileExtension: fileExtension, dispatcher: dispatcher)

        fetchFolders()

        foldersRepo.subject
            .sink { folders in
                self.subject.send(folders)
            }.store(in: &disposeBag)
    }

    private func fetchFolders() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            let filesData = self.filesRepo.loadFromDisk()
            let fileSerializer = FileSerializer(dispatcher: self.dispatcher)
            self.fileSerializer = fileSerializer
            let files = self.filesRepo.deserialize(data: filesData, serializer: fileSerializer)
            
            let foldersData = self.foldersRepo.loadFromDisk()
            let folderSerializer = FolderSerializer(files: files, foldersData: foldersData, dispatcher: self.dispatcher)
            self.folderSerializer = folderSerializer
            _ = self.foldersRepo.deserialize(data: foldersData, serializer: folderSerializer)
            
            self.filesRepo.listenToEntitiesChanged()
            self.foldersRepo.listenToEntitiesChanged()
        }
    }
    
    func reload() {
        subject.send(subject.value)
    }

    func write(newFolder: Folder) {
        foldersRepo.write(newFolder)
    }

    func write(newFile: File) {
        filesRepo.write(newFile)
    }

    func destroy(file: File) {
        file.parent?.remove(file)
        filesRepo.remove(file.uid)
    }

    func destroy(folder: Folder) {
        folder.parent?.remove(folder)
        folder.files.forEach { destroy(file: $0) }
        folder.folders.forEach { destroy(folder: $0) }
        folder.isDestroyed = true
        foldersRepo.remove(folder.uid)
    }
}
