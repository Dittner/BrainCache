//
//  FileListAppService.swift
//  BrainCache
//
//  Created by Alexander Dittner on 05.04.2021.
//

import Foundation
class FileListAppService {
    let context: BrainCacheContext
    init() {
        context = BrainCacheContext.shared
    }

    func selectFile(_ f: File) {
        f.parent?.update(selectedFile: f)
    }

    func destroyFile(_ f: File) {
        context.storage.destroy(file: f)
    }

    func updateFileTitle(_ f: File, title: String) {
        f.update(title: title)
    }

    func updateFileFont(_ f: File, useMonoFont: Bool) {
        f.update(useMonoFont: useMonoFont)
    }

    func deleteColumn(_ f: File, at index: Int) {
        if let listBody = f.body as? ListFileBody {
            listBody.deleteColumn(at: index)
        } else if let tableBody = f.body as? TableFileBody {
            tableBody.deleteColumn(at: index)
        }
    }
}
