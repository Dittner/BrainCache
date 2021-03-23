//
//  DomainEntityRemover.swift
//  BrainCache
//
//  Created by Alexander Dittner on 23.03.2021.
//

import Foundation
class DomainEntityRemover {
    func removeFile(_ f: File) {
        BrainCacheContext.shared.filesRepo.remove(f.uid)
    }

    func removeFolderWithFiles(_ f: Folder) {
        let context = BrainCacheContext.shared
        let files = context.filesRepo.subject.value.filter { $0.folderUID == f.uid }
        for f in files {
            context.filesRepo.remove(f.uid)
        }
        context.foldersRepo.remove(f.uid)
    }
}
