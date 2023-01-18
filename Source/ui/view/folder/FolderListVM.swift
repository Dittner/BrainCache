//
//  FolderListVM.swift
//
//
//  Created by Alexander Dittner on 10.02.2021.
//

import Combine
import SwiftUI

class FolderListVM: ObservableObject {
    static var shared: FolderListVM = FolderListVM()

    @Published var folders: [Folder] = []
    @Published var selectedFolder: Folder?
    @Published var files: [File] = []
    @Published var selectedFile: File?
    @Published var search: String = ""
    let searchInputUID: UID = UID()

    private let foldersAppService: FolderListAppService
    private let filesAppService: FileListAppService

    private(set) var fileToFolderDragProcessor: FileToFolderDragProcessor
    private var disposeBag: Set<AnyCancellable> = []
    private let context: BrainCacheContext

    init() {
        logInfo(msg: "FolderListVM init")
        context = BrainCacheContext.shared

        foldersAppService = FolderListAppService()
        filesAppService = FileListAppService()

        fileToFolderDragProcessor = FileToFolderDragProcessor(fileToFolderDidMoveAction: foldersAppService.moveToFolder, folderToFolderDidMoveAction: foldersAppService.moveToFolder)

        context.storage.subject
            .sink { folders in
                self.folders = folders.sorted(by: { $0.title < $1.title }).filter { $0.parent == nil }
                logInfo(msg: "FolderListVM received root folders: \(self.folders.count)")
                self.setupLastOpenedFolder(folders)
            }.store(in: &disposeBag)

        $selectedFolder
            .compactMap { $0 }
            .flatMap { $0.$selectedFile }
            .sink { file in
                self.selectedFile = file
            }.store(in: &disposeBag)

        $selectedFolder
            .compactMap { $0 }
            .flatMap { $0.$files }
            .sink { files in
                self.files = files.sorted(by: { $0.title < $1.title })
            }.store(in: &disposeBag)

        $selectedFile
            .compactMap { $0 }
            .sink { f in
                (NSApplication.shared.delegate as! AppDelegate).window?.makeFirstResponder(nil)
                self.pushToStack(f: f)
            }.store(in: &disposeBag)

        NotificationCenter.default.addObserver(self, selector: #selector(onDidKeyDownSearch(_:)), name: .didKeyDownSearch, object: nil)
    }

    @objc func onDidKeyDownSearch(_ notification: Notification) {
        EditableTextManager.shared.ownerUID = searchInputUID
        EditableTextManager.shared.isEditing = true
    }

    var firstLaunch: Bool = true
    private func setupLastOpenedFolder(_ folders: [Folder]) {
        if let folderUID = Cache.readUID(key: .lastOpenedFolderUID), let folder = folders.first(where: { $0.uid == folderUID }) {
            selectFolder(folder)
        } else if folders.count > 0 {
            selectFolder(folders[0])
        } else {
            selectedFolder = nil
            selectedFile = nil
            files = []
        }
    }

    func createFolder() {
        let f = foldersAppService.createFolder()
        selectFolder(f)
    }

    func destroyFolder() {
        if let folder = selectedFolder {
            foldersAppService.destroyFolder(folder)
        }
    }

    func createTextFile() {
        if let folder = selectedFolder {
            foldersAppService.createTextFile(from: folder)
        }
    }

    func createTableFile(with columnCount: Int) {
        if let folder = selectedFolder {
            foldersAppService.createTableFile(from: folder, with: columnCount)
        }
    }

    func createListFile(with columnCount: Int) {
        if let folder = selectedFolder {
            foldersAppService.createListFile(from: folder, with: columnCount)
        }
    }

    func selectFolder(_ f: Folder) {
        if f != selectedFolder {
            selectedFolder = f
            Cache.write(key: .lastOpenedFolderUID, value: f.uid)
        }
    }

    func updateFolderTitle(_ f: Folder, title: String) {
        foldersAppService.updateFolderTitle(f, title: title)
        folders = folders.sorted(by: { $0.title < $1.title })
    }

    //
    // files
    //

    func updateFileTitle(_ f: File, title: String) {
        filesAppService.updateFileTitle(f, title: title)
        files = files.sorted(by: { $0.title < $1.title })
    }

    func selectFile(_ f: File) {
        if let folder = f.parent {
            selectFolder(folder)
            filesAppService.selectFile(f)
        }
    }

    func destroyFile(_ f: File) {
        filesAppService.destroyFile(f)
        destroyFileFromStack(f)
    }

    func updateFileFont(_ f: File, useMonoFont: Bool) {
        filesAppService.updateFileFont(f, useMonoFont: useMonoFont)
    }

    func deleteColumn(_ f: File, at index: Int) {
        filesAppService.deleteColumn(f, at: index)
    }

    //
    // FileNavigator
    //

    private var filesStack: [File] = []
    private var curFileIndex: Int = 0

    public func pushToStack(f: File) {
        if filesStack.count > 0 && filesStack[curFileIndex] == f { return }

        if curFileIndex < filesStack.count - 1 {
            filesStack = Array(filesStack[0 ... curFileIndex])
        }

        filesStack.append(f)
        curFileIndex = filesStack.count - 1
    }

    public func canOpenPrev() -> Bool {
        return curFileIndex > 0
    }

    public func canOpenNext() -> Bool {
        return filesStack.count > curFileIndex + 1
    }

    public func openPrev() {
        if canOpenPrev() {
            curFileIndex -= 1
            let f = filesStack[curFileIndex]
            if let folder = f.parent, folder.isDestroyed {
                filesStack.remove(at: curFileIndex)
            } else {
                selectFile(f)
            }
        }
    }

    public func openNext() {
        if canOpenNext() {
            curFileIndex += 1
            let f = filesStack[curFileIndex]
            if let folder = f.parent, folder.isDestroyed {
                filesStack.remove(at: curFileIndex)
            } else {
                selectFile(f)
            }
        }
    }

    public func destroyFileFromStack(_ f: File) {
        if filesStack[curFileIndex] == f {
            filesStack.remove(at: curFileIndex)
            if curFileIndex > 0 {
                curFileIndex -= 1
            }
        }
    }
}
