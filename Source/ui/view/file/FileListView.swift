//
//  FilerListView.swift
//  BrainCache
//
//  Created by Alexander Dittner on 20.03.2021.
//

import Combine
import SwiftUI

struct FileListView: View {
    @ObservedObject private var vm = FolderListVM.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let folder = vm.selectedFolder {
                FileBodyView(folder: folder)
                    .zIndex(1)
            } else {
                Spacer()
            }
        }
        .frame(maxHeight: .infinity)
    }
}

struct FileBodyView: View {
    @ObservedObject private var folder: Folder

    init(folder: Folder) {
        self.folder = folder
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let file = folder.selectedFile, let fileBody = file.body as? TextFileBody {
                TextFileView(file: file, fileBody: fileBody)
            } else if let file = folder.selectedFile, let fileBody = file.body as? TableFileBody {
                TableFileView(file: file, fileBody: fileBody)
            } else if let file = folder.selectedFile, let fileBody = file.body as? ListFileBody {
                ListFileView(file: file, fileBody: fileBody)
            } else {
                Spacer()
            }
        }
        .frame(maxHeight: .infinity)
    }
}
