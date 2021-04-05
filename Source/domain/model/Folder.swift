//
//  Folder.swift
//  BrainCache
//
//  Created by Alexander Dittner on 20.03.2021.
//

import Combine
import SwiftUI

class Folder: DomainEntity, ObservableObject {
    @Published private(set) var title: String
    @Published private(set) var selectedFile: File?
    @Published private(set) var files: [File]
    @Published private(set) var folders: [Folder]
    @Published private(set) var isOpened: Bool = false

    private(set) var parent: Folder?

    init(uid: UID, title: String, selectedFile: File? = nil, files: [File] = [], folders: [Folder] = [], isOpened: Bool = false, dispatcher: DomainEventDispatcher) {
        self.title = title
        self.selectedFile = selectedFile
        self.files = files
        self.folders = folders
        self.isOpened = isOpened
        super.init(uid: uid, dispatcher: dispatcher)
    }

    func initWith(selectedFile: File?) {
        self.selectedFile = selectedFile
    }

    func initWith(files: [File]) {
        self.files = files
        resortFiles()
    }

    func initWith(folders: [Folder]) {
        self.folders = folders
    }

    private func resortFiles() {
        files = files.sorted(by: { $0.title < $1.title })
    }

    private func resortFolders() {
        folders = folders.sorted(by: { $0.title < $1.title })
    }

    func add(_ f: File) {
        files.append(f)
        selectedFile = f
        f.update(parent: self)
        resortFiles()
        notifyStateDidChange()
    }

    func add(_ f: Folder) {
        folders.append(f)
        f.update(parent: self)
        resortFolders()
        notifyStateDidChange()
    }

    func remove(_ f: File) {
        if let index = files.firstIndex(of: f) {
            files.remove(at: index)
            if selectedFile == f {
                selectedFile = index > 0 ? files[index - 1] : files.count > 0 ? files[0] : nil
            }
            f.update(parent: nil)
            notifyStateDidChange()
        }
    }

    func remove(_ f: Folder) {
        if let index = folders.firstIndex(of: f) {
            folders.remove(at: index)
            f.parent = nil
            notifyStateDidChange()
        }
    }

    func update(title: String) {
        if self.title != title {
            self.title = title
            notifyStateDidChange()
        }
    }

    func update(selectedFile: File?) {
        if self.selectedFile != selectedFile {
            self.selectedFile = selectedFile
            notifyStateDidChange()
        }
    }
    
    func update(isOpened: Bool) {
        if self.isOpened != isOpened {
            self.isOpened = isOpened
            notifyStateDidChange()
        }
    }

    func update(parent: Folder?) {
        self.parent = parent
        notifyStateDidChange()
    }

    static func createFolder() -> Folder {
        return Folder(uid: UID(), title: "New Folder", dispatcher: BrainCacheContext.shared.dispatcher)
    }
}
