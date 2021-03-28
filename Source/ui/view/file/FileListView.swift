//
//  FilerListView.swift
//  BrainCache
//
//  Created by Alexander Dittner on 20.03.2021.
//

import Combine
import SwiftUI

struct FileListView: View {
    @ObservedObject private var vm = FileListVM.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: -1) {
                if vm.files.count > 0 {
                    ForEach(vm.files, id: \.id) { f in
                        FileListCell(file: f, isSelected: f.uid == vm.selectedFile?.uid)
                        VSeparatorView(verticalPadding: 5)
                    }
                }

                Spacer()

                if let folder = vm.selectedFolder {
                    SearchInputView(folder: folder)
                }

            }.frame(height: SizeConstants.appHeaderHeight)
                .background(Colors.black01.color)
                .zIndex(1)

            HSeparatorView()

            if let folder = vm.selectedFolder, let file = vm.selectedFile, let fileBody = file.body as? TextFileBody {
                TextFileView(file: file, fileBody: fileBody, folder: folder)
            } else if let folder = vm.selectedFolder, let file = vm.selectedFile, let fileBody = file.body as? TableFileBody {
                TableFileView(file: file, fileBody: fileBody, folder: folder)
            } else if let folder = vm.selectedFolder, let file = vm.selectedFile, let fileBody = file.body as? ListFileBody {
                ListFileView(file: file, fileBody: fileBody, folder: folder)
            } else {
                Spacer()
            }
        }
        .frame(maxHeight: .infinity)
    }
}

struct FileListCell: View {
    @ObservedObject private var file: File
    private let vm = FileListVM.shared
    private let isSelected: Bool

    init(file: File, isSelected: Bool) {
        self.file = file
        self.isSelected = isSelected
    }

    private func getFileIcon() -> FontIcon {
        if file.body is TableFileBody { return .table }
        if file.body is ListFileBody { return .list }
        return .file
    }

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Icon(name: getFileIcon(), size: SizeConstants.iconSize)
                .allowsHitTesting(false)
                .padding(.leading, SizeConstants.padding)

            EditableText(file.title, uid: file.uid) { value in
                file.title = value
            }
            .frame(height: SizeConstants.listCellHeight)
            .frame(width: SizeConstants.fileListWidth - 45)

            if isSelected {
                FileMenuButton(file: file)
            } else {
                Spacer()
            }
        }
        .background(isSelected ? Colors.selection.color : Colors.clear.color)
        .foregroundColor(isSelected ? Colors.textLight.color : Colors.textDark.color)
        .frame(width: SizeConstants.fileListWidth, height: SizeConstants.listCellHeight)

        .if(!isSelected) {
            $0.highPriorityGesture(
                TapGesture()
                    .onEnded { _ in
                        vm.selectFile(file)
                    }
            )
        }
    }
}

struct FileMenuButton: View {
    @ObservedObject private var file: File
    @ObservedObject private var notifier = Notifier()
    private let vm = FileListVM.shared

    class Notifier: ObservableObject {
        @Published var stateChanged: Bool = false
    }

    private var disposeBag: Set<AnyCancellable> = []
    init(file: File) {
        self.file = file

        file.body.stateDidChange
            .map { _ in true }
            .assign(to: \.stateChanged, on: notifier)
            .store(in: &disposeBag)
    }

    var body: some View {
        MenuButton(
            label: Icon(name: .dropdown, size: SizeConstants.fontSize),
            content: {
                if let tableBody = file.body as? TableFileBody {
                    Button("Add Row") { tableBody.addNewRow() }
                    Button("Add Column") { tableBody.addNewColumn() }
                    Button(file.useMonoFont ? "Use Default Font" : "Use Mono Font") { file.useMonoFont.toggle() }
                    MenuButton("Delete ...") {
                        if tableBody.headers.count > 1 {
                            ForEach(tableBody.headers.enumeratedArray(), id: \.offset) { index, header in
                                Button("C\(index + 1): «\(header.title)»") {
                                    tableBody.deleteColumn(at: index)
                                }
                            }
                        }

                        Button("Delete Table") { vm.deleteFile() }
                    }

                } else if let listBody = file.body as? ListFileBody {
                    Button("Add Column") { listBody.addNewColumn() }
                    Button(file.useMonoFont ? "Use Default Font" : "Use Mono Font") { file.useMonoFont.toggle() }
                    MenuButton("Delete ...") {
                        if listBody.columns.count > 1 {
                            ForEach(listBody.columns.enumeratedArray(), id: \.offset) { index, column in
                                Button("С\(index + 1): «\(column.title)»") {
                                    listBody.deleteColumn(at: index)
                                }
                            }
                        }

                        Button("Delete List") { vm.deleteFile() }
                    }

                } else {
                    Button(file.useMonoFont ? "Use Default Font" : "Use Mono Font") { file.useMonoFont.toggle() }
                    Button("Delete File") { vm.deleteFile() }
                }
            })
            .menuButtonStyle(BorderlessButtonMenuButtonStyle())
            .foregroundColor(Colors.button.color)
    }
}

struct SearchInputView: View {
    @ObservedObject private var vm = FileListVM.shared
    @ObservedObject private var folder: Folder

    init(folder: Folder) {
        self.folder = folder
    }

    var body: some View {
        HStack(alignment: .center, spacing: 5) {
            Icon(name: .search, size: SizeConstants.iconSize)
                .allowsHitTesting(false)
                .padding(.leading, 5)

            EditableText(folder.search, uid: folder.searchUID, countClickActivation: 1) { value in
                folder.search = value
            }
            .frame(height: SizeConstants.appHeaderHeight)
            .frame(maxWidth: SizeConstants.searchBarWidth)

            if folder.search.count > 0 {
                IconButton(name: .close, size: SizeConstants.iconSize, color: folder.search.count > 0 ? Colors.textLight.color : Colors.textDark.color, width: SizeConstants.iconSize + 10, height: SizeConstants.iconSize + 10) {
                    folder.search = ""
                }
            }
        }
        .frame(width: SizeConstants.searchBarWidth, height: SizeConstants.appHeaderHeight)
        .foregroundColor(folder.search.count > 0 ? Colors.textLight.color : Colors.textDark.color)
        .background(Colors.black01.color)
    }
}
