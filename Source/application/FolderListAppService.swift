//
//  FolderListAppService.swift
//  BrainCache
//
//  Created by Alexander Dittner on 05.04.2021.
//

import Foundation
class FolderListAppService {
    let context: BrainCacheContext
    init() {
        context = BrainCacheContext.shared
    }

    func createFolder() -> Folder {
        let newFolder = Folder.createFolder()
        context.storage.write(newFolder: newFolder)
        return newFolder
    }

    func destroyFolder(_ folder: Folder) {
        context.storage.destroy(folder: folder)
    }

    func createTextFile(from folder: Folder) {
        let f = File.createTextFile()
        folder.add(f)
        context.storage.write(newFile: f)
    }

    func createTableFile(from folder: Folder, with columnCount: Int) {
        let f = File.createTableFile(columnCount: columnCount)
        folder.add(f)
        context.storage.write(newFile: f)
    }

    func createListFile(from folder: Folder, with columnCount: Int) {
        let f = File.createListFile(columnCount: columnCount)
        folder.add(f)
        context.storage.write(newFile: f)
    }

    func updateFolderTitle(_ f: Folder, title: String) {
        f.update(title: title)
    }

    //
    // dragging
    //

    func moveToFolder(_ f: File, folder: Folder) {
        f.parent?.remove(f)
        folder.add(f)
    }

    func moveToFolder(_ f: Folder, folder: Folder?) {
        for ff in f.folders {
            f.remove(ff)
            folder?.add(ff)
        }
        f.parent?.remove(f)
        folder?.add(f)
        context.storage.reload()
    }
}
