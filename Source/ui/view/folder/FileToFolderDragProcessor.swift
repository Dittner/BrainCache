//
//  FileToFolderDragProcessor.swift
//  BrainCache
//
//  Created by Alexander Dittner on 31.03.2021.
//

import SwiftUI

class FileToFolderDragProcessor: ObservableObject {
    @Published var draggingFile: File?
    @Published var draggingFolder: Folder?
    @Published var dropCandidate: Folder?

    func perform() -> Bool {
        guard let dropCandidate = dropCandidate else { return false }
        if let draggingFile = draggingFile {
            draggingFile.updateFolderUID(uid: dropCandidate.uid)
        } else if let draggingFolder = draggingFolder {
            draggingFolder.parentFolderUID = dropCandidate.uid
        }

        draggingFile = nil
        draggingFolder = nil
        self.dropCandidate = nil
        return true
    }
}

struct FolderDropViewDelegate: DropDelegate {
    let destFolder: Folder
    let dragProcessor: FileToFolderDragProcessor
    init(destFolder: Folder, dragProcessor: FileToFolderDragProcessor) {
        self.destFolder = destFolder
        self.dragProcessor = dragProcessor
    }

    func validateDrop(info: DropInfo) -> Bool {
        if let srcFile = dragProcessor.draggingFile {
            return srcFile.folderUID != destFolder.uid
        } else if let srcFolder = dragProcessor.draggingFolder {
            return srcFolder.uid != destFolder.uid && destFolder.parentFolderUID == nil
        } else {
            return false
        }
    }

    func dropEntered(info: DropInfo) {
        dragProcessor.dropCandidate = destFolder
    }

    func dropExited(info: DropInfo) {
        dragProcessor.dropCandidate = nil
    }

    func performDrop(info: DropInfo) -> Bool {
        return dragProcessor.perform()
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
}
