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
    @Published var editingFolder: Folder?

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
            }.store(in: &disposeBag)

        context.menuAPI.subject
            .sink { event in
                switch event {
                case .deleteFolder:
                    if let folder = self.selectedFolder {
                        self.context.entityRemover.removeFolderWithFiles(folder)
                    }
                default: break
                }
            }.store(in: &disposeBag)
    }

    var firstLaunch: Bool = true
    private func setupLastOpenedFolder() {
        guard let folderUID = Cache.readUID(key: .lastOpenedFolderUID) else { return }
        if let folder = folders.first(where: { $0.uid == folderUID }) {
            selectFolder(folder)
        } else if folders.count > 0 {
            selectFolder(folders[0])
        } else {
            deselectFolder()
        }
    }

    func addNewFolder() {
        context.foldersRepo.write(Folder(uid: UID(), title: "New Folder", dispatcher: context.dispatcher))
    }

    func selectFolder(_ f: Folder) {
        if f != selectedFolder {
            selectedFolder = f
            editingFolder = nil
            Cache.write(key: .lastOpenedFolderUID, value: f.uid)
        }
    }
    
    func deselectFolder() {
        selectedFolder = nil
        editingFolder = nil
    }

    func startEditing(f: Folder) {
        if f != editingFolder {
            selectedFolder = f
            editingFolder = f
            Cache.write(key: .lastOpenedFolderUID, value: f.uid)
        }
    }

    func stopEditing() {
        editingFolder = nil
    }
}
