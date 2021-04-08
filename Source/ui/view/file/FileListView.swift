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
            FileHeaderList(dragProcessor: vm.fileToFolderDragProcessor)
                .zIndex(2)

            HSeparatorView()

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

struct FileHeaderList: View {
    @ObservedObject private var vm = FolderListVM.shared
    @ObservedObject var dragProcessor: FileToFolderDragProcessor
    @State var fileListOffset: CGFloat = 0

    func isNextBtnEnabled(containerWidth: CGFloat, offset: CGFloat) -> Bool {
        let res = (containerWidth - offset - (CGFloat(vm.files.count) * SizeConstants.fileListWidth) - SizeConstants.searchBarWidth)
        return res < CGFloat(50)
    }

    func isPrevBtnEnabled(offset: CGFloat) -> Bool {
        return offset < 0
    }

    var body: some View {
        GeometryReader { proxy in
            HStack(alignment: .center, spacing: 1) {
                HStack(alignment: .center, spacing: -1) {
                    if vm.files.count > 0 {
                        ForEach(vm.files, id: \.uid) { f in
                            FileHeaderCell(file: f, isSelected: f.uid == vm.selectedFile?.uid)
                                .onDrag { self.dragProcessor.draggingFile = f; return NSItemProvider(object: NSString()) }
                            VSeparatorView(verticalPadding: 5)
                        }
                    }

                }.offset(x: fileListOffset)
                    .frame(width: proxy.size.width - SizeConstants.searchBarWidth - 50, height: SizeConstants.appHeaderHeight, alignment: .leading)
                    .clipped()

                Spacer().frame(minWidth: 0, maxWidth: .infinity)

                IconButton(name: .prev, size: SizeConstants.fontSize, color: Colors.button.color, width: 25) {
                    withAnimation {
                        self.fileListOffset += SizeConstants.fileListWidth
                    }

                }.background(Colors.selection.color)
                    .opacity(isPrevBtnEnabled(offset: fileListOffset) ? 1 : 0.4)
                    .disabled(!isPrevBtnEnabled(offset: fileListOffset))

                IconButton(name: .next, size: SizeConstants.fontSize, color: Colors.button.color, width: 25) {
                    withAnimation {
                        self.fileListOffset -= SizeConstants.fileListWidth
                    }
                }.background(Colors.selection.color)
                    .opacity(isNextBtnEnabled(containerWidth: proxy.size.width, offset: fileListOffset) ? 1 : 0.4)
                    .disabled(!isNextBtnEnabled(containerWidth: proxy.size.width, offset: fileListOffset))

                if vm.selectedFile != nil {
                    SearchInputView()
                }

            }.frame(width: proxy.size.width, height: SizeConstants.appHeaderHeight, alignment: .leading)
                .background(Colors.black01.color)
        }.frame(height: SizeConstants.appHeaderHeight, alignment: .leading)
    }
}

struct FileHeaderCell: View {
    @ObservedObject private var file: File
    private let vm = FolderListVM.shared
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
                vm.updateFileTitle(file, title: value)
            }
            .frame(height: SizeConstants.listCellHeight)
            .frame(width: SizeConstants.fileListWidth - 45)

            if isSelected {
                FileMenuButton(file: file)
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
    private let vm = FolderListVM.shared

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
                    Button(file.useMonoFont ? "Use Default Font" : "Use Mono Font") {
                        vm.updateFileFont(file, useMonoFont: !file.useMonoFont)
                    }
                    MenuButton("Delete ...") {
                        if tableBody.headers.count > 1 {
                            ForEach(tableBody.headers.enumeratedArray(), id: \.offset) { index, header in
                                Button("C\(index + 1): «\(header.title)»") {
                                    vm.deleteColumn(file, at: index)
                                }
                            }
                        }

                        Button("Delete Table") { vm.destroyFile(file) }
                    }

                } else if let listBody = file.body as? ListFileBody {
                    Button("Add Column") { listBody.addNewColumn() }
                    Button(file.useMonoFont ? "Use Default Font" : "Use Mono Font") {
                        vm.updateFileFont(file, useMonoFont: !file.useMonoFont)
                    }
                    MenuButton("Delete ...") {
                        if listBody.columns.count > 1 {
                            ForEach(listBody.columns.enumeratedArray(), id: \.offset) { index, column in
                                Button("С\(index + 1): «\(column.title)»") {
                                    vm.deleteColumn(file, at: index)
                                }
                            }
                        }

                        Button("Delete List") { vm.destroyFile(file) }
                    }

                } else {
                    Button(file.useMonoFont ? "Use Default Font" : "Use Mono Font") {
                        vm.updateFileFont(file, useMonoFont: !file.useMonoFont)
                    }
                    Button("Delete File") { vm.destroyFile(file) }
                }
            })
            .menuButtonStyle(BorderlessButtonMenuButtonStyle())
            .foregroundColor(Colors.button.color)
    }
}

struct SearchInputView: View {
    @ObservedObject private var vm = FolderListVM.shared

    var body: some View {
        HStack(alignment: .center, spacing: 5) {
            Icon(name: .search, size: SizeConstants.iconSize)
                .allowsHitTesting(false)
                .padding(.leading, 5)

            EditableText(vm.search, uid: vm.searchInputUID, countClickActivation: 1) { value in
                vm.search = value
            }
            .frame(height: SizeConstants.appHeaderHeight)
            .frame(maxWidth: SizeConstants.searchBarWidth - 40)

            if vm.search.count > 0 {
                IconButton(name: .close, size: SizeConstants.iconSize, color: vm.search.count > 0 ? Colors.textLight.color : Colors.textDark.color, width: SizeConstants.iconSize + 10, height: SizeConstants.iconSize + 10) {
                    vm.search = ""
                }
            }
        }
        .frame(width: SizeConstants.searchBarWidth, height: SizeConstants.appHeaderHeight, alignment: .leading)
        .foregroundColor(vm.search.count > 0 ? Colors.textLight.color : Colors.textDark.color)
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
