//
//  FolderListVM.swift
//
//
//  Created by Alexander Dittner on 10.02.2021.
//

import Combine
import Foundation

class FolderListVM: ObservableObject {
    static var shared: FolderListVM = FolderListVM()

    @Published var folders: [Folder] = []
    @Published var selectedFolder: Folder?

    private var disposeBag: Set<AnyCancellable> = []
    private let context: BrainCacheContext

    init() {
        logInfo(msg: "FolderListVM init")
        context = BrainCacheContext.shared

        context.foldersRepo.subject
            .debounce(for: 0.2, scheduler: RunLoop.main)
            .sink { folders in
                self.folders = folders.sorted(by: { $0.title < $1.title })
                logInfo(msg: "FolderListVM received folders: \(self.folders.count)")
                self.setupLastOpenedFolder()
            }.store(in: &disposeBag)

        $selectedFolder
            .sink { folder in
                self.context.menuAPI.isDeleteFolderEnabled = folder != nil
                self.context.menuAPI.isCreateTableEnabled = folder != nil
                self.context.menuAPI.isCreateTextFileEnabled = folder != nil
            }.store(in: &disposeBag)

        context.menuAPI.subject
            .sink { event in
                switch event {
                case .deleteFolder:
                    if let folder = self.selectedFolder {
                        self.context.entityRemover.removeFolderWithFiles(folder)
                    }
                case .createFolder:
                    self.createFolder()
                case .createTextFile:
                    self.createTextFile()
                case let .createTable(columns):
                    self.createTableFile(with: columns)
                default: break
                }
            }.store(in: &disposeBag)
    }

    var firstLaunch: Bool = true
    private func setupLastOpenedFolder() {
        if let folderUID = Cache.readUID(key: .lastOpenedFolderUID), let folder = folders.first(where: { $0.uid == folderUID }) {
            selectFolder(folder)
        } else if folders.count > 0 {
            selectFolder(folders[0])
        } else {
            deselectFolder()
        }
    }

    private func createFolder() {
        context.foldersRepo.write(Folder(uid: UID(), title: "New Folder", dispatcher: context.dispatcher))
    }

    private func createTextFile() {
        if let folder = selectedFolder {
            let newFile = folder.createTextFile()
            context.filesRepo.write(newFile)
        }
    }

    private func createTableFile(with columnCount: Int) {
        if let folder = selectedFolder {
            let newTable = folder.createTableFile(columnCount: columnCount)
            context.filesRepo.write(newTable)
        }
    }

    func selectFolder(_ f: Folder) {
        if f != selectedFolder {
            selectedFolder = f
            Cache.write(key: .lastOpenedFolderUID, value: f.uid)
        }
    }

    func deselectFolder() {
        selectedFolder = nil
    }
}
