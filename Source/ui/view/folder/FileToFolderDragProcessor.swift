//
//  FileToFolderDragProcessor.swift
//  BrainCache
//
//  Created by Alexander Dittner on 31.03.2021.
//

import SwiftUI

class FileToFolderDragProcessor: ObservableObject {
    @Published var draggingFile: File?
    @Published var dropCandidate: Folder?

    func perform() -> Bool {
        guard let draggingFile = draggingFile else { return false }
        guard let dropCandidate = dropCandidate else { return false }

        draggingFile.updateFolderUID(uid: dropCandidate.uid)

        self.draggingFile = nil
        self.dropCandidate = nil
        return true
    }
}

struct FileToFolderDropViewDelegate: DropDelegate {
    let destFolder: Folder
    let dragProcessor: FileToFolderDragProcessor
    init(destFolder: Folder, dragProcessor: FileToFolderDragProcessor) {
        self.destFolder = destFolder
        self.dragProcessor = dragProcessor
    }

    func validateDrop(info: DropInfo) -> Bool {
        guard let srcFile = dragProcessor.draggingFile else { return false }
        return srcFile.folderUID != destFolder.uid
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
