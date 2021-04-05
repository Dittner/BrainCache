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
    @Published var dropFolderRootCandidate: Bool = false
    
    let fileToFolderDidMoveAction:(File, Folder) -> Void
    let folderToFolderDidMoveAction:(Folder, Folder?) -> Void
    
    init(fileToFolderDidMoveAction: @escaping (File, Folder) -> Void, folderToFolderDidMoveAction: @escaping (Folder, Folder?) -> Void) {
        self.fileToFolderDidMoveAction = fileToFolderDidMoveAction
        self.folderToFolderDidMoveAction = folderToFolderDidMoveAction
    }

    func perform() -> Bool {
        if let dropCandidate = dropCandidate, let draggingFile = draggingFile {
            fileToFolderDidMoveAction(draggingFile, dropCandidate)
        } else if let dropCandidate = dropCandidate, let draggingFolder = draggingFolder {
            folderToFolderDidMoveAction(draggingFolder, dropCandidate)
        } else if dropFolderRootCandidate, let draggingFolder = draggingFolder {
            folderToFolderDidMoveAction(draggingFolder, nil)
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
        if let draggingFile = dragProcessor.draggingFile {
            return draggingFile.parent != destFolder
        } else if let draggingFolder = dragProcessor.draggingFolder {
            return (draggingFolder != destFolder && draggingFolder.parent != destFolder && destFolder.parent == nil)
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

struct FolderRootDropViewDelegate: DropDelegate {
    let dragProcessor: FileToFolderDragProcessor
    init(dragProcessor: FileToFolderDragProcessor) {
        self.dragProcessor = dragProcessor
    }

    func validateDrop(info: DropInfo) -> Bool {
        if let draggingFolder = dragProcessor.draggingFolder, draggingFolder.parent != nil {
            return true
        } else {
            return false
        }
    }

    func dropEntered(info: DropInfo) {
        dragProcessor.dropFolderRootCandidate = true
    }

    func dropExited(info: DropInfo) {
        dragProcessor.dropFolderRootCandidate = false
    }

    func performDrop(info: DropInfo) -> Bool {
        return dragProcessor.perform()
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
}
