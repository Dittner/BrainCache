//
//  ContentView.swift
//  BrainCache
//
//  Created by Alexander Dittner on 20.03.2021.
//

import Combine
import SwiftUI

struct FolderListView: View {
    @ObservedObject private var vm = FolderListVM.shared

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .trailing, spacing: 0) {
                HStack(alignment: .center, spacing: 0) {
                    SearchInputView()
                    
                    IconButton(name: .prev, size: SizeConstants.fontSize, color: Colors.button.color, width: 30) {
                        self.vm.openPrev()
                    }.opacity(vm.canOpenPrev() ? 1 : 0.5)
                        .disabled(!vm.canOpenPrev())

                    IconButton(name: .next, size: SizeConstants.fontSize, color: Colors.button.color, width: 30) {
                        self.vm.openNext()
                    }.opacity(vm.canOpenNext() ? 1 : 0.5)
                        .disabled(!vm.canOpenNext())
                }.frame(width: SizeConstants.folderListWidth, height: SizeConstants.listCellHeight)
                    .background(Colors.black01.color)

                HSeparatorView().opacity(0.5)

                ForEach(vm.folders, id: \.uid) { f in
                    FolderListCell(folder: f, isSelected: f == vm.selectedFolder, isChild: false) {
                        vm.selectFolder(f)
                    }
                }

                HSeparatorView()

                TextButton(text: "New Folder", textColor: Colors.button.color, font: Font.custom(.pragmatica, size: SizeConstants.fontSize), padding: 5) {
                    self.vm.createFolder()
                }
            }.frame(width: SizeConstants.folderListWidth)
        }
        .background(FolderRootDropIndicator())
            .background(LinearGradient(gradient: Gradient(colors: Colors.folderListBG), startPoint: .top, endPoint: .bottom))
    }
}

struct SearchInputView: View {
    @ObservedObject private var vm = FolderListVM.shared

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Spacer()
                .frame(width: 15)

            Icon(name: .search, size: SizeConstants.iconSize + 2)
                .allowsHitTesting(false)
            
            EditableText(vm.search, uid: vm.searchInputUID, countClickActivation: 1) { value in
                vm.search = value
            }
            .frame(width: 180, height: SizeConstants.listCellHeight)

            if vm.search.count > 0 {
                IconButton(name: .close, size: SizeConstants.iconSize, color: vm.search.count > 0 ? Colors.textLight.color : Colors.textDark.color, width: SizeConstants.iconSize + 10, height: SizeConstants.iconSize + 10) {
                    vm.search = ""
                }
            }
        }
        .frame(width: SizeConstants.folderListWidth - 60, height: SizeConstants.listCellHeight, alignment: .leading)

        .foregroundColor(vm.search.count > 0 ? Colors.textLight.color : Colors.textDark.color)
    }
}

struct FolderRootDropIndicator: View {
    @ObservedObject private var dragProcessor: FileToFolderDragProcessor

    init() {
        dragProcessor = FolderListVM.shared.fileToFolderDragProcessor
    }

    var body: some View {
        HStack {
            LinearGradient(gradient: Gradient(colors: [Colors.focus.color, Colors.focus.color.opacity(0)]), startPoint: .leading, endPoint: .trailing)
                .opacity(dragProcessor.dropFolderRootCandidate ? 0.5 : 0)
                .onDrop(of: ["public.plain-text"], delegate: FolderRootDropViewDelegate(dragProcessor: dragProcessor))
                .frame(width: 8)

            Spacer()
        }
    }
}

struct FolderListCell: View {
    @ObservedObject private var folder: Folder
    @ObservedObject private var dragProcessor: FileToFolderDragProcessor
    let vm = FolderListVM.shared
    let didSelectAction: () -> Void
    private let isSelected: Bool
    private let folderOffset: CGFloat
    private let isChild: Bool

    init(folder: Folder, isSelected: Bool, isChild: Bool, didSelectAction: @escaping () -> Void) {
        self.folder = folder
        self.isSelected = isSelected
        self.didSelectAction = didSelectAction
        self.isChild = isChild
        folderOffset = isChild ? SizeConstants.folderListChildOffset : 0
        dragProcessor = vm.fileToFolderDragProcessor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(alignment: .center, spacing: 0) {
                Spacer().frame(width: folderOffset)

                IconButton(name: .arrow, size: SizeConstants.iconSize, color: Colors.textDark.color, width: 16) {
                    folder.update(isOpened: !folder.isOpened)
                }.rotationEffect(folder.isOpened ? .degrees(0) : .degrees(-90))
                    .opacity(folder.folders.count > 0 ? 1 : 0)
                    .disabled(folder.folders.count == 0)

                Icon(name: .folder, size: SizeConstants.iconSize)
                    .allowsHitTesting(false)

                EditableText(folder.title.uppercased(), uid: folder.uid, countClickActivation: 2) { value in
                    vm.updateFolderTitle(folder, title: value)
                }
                .frame(width: SizeConstants.folderListWidth - 80 - folderOffset, height: SizeConstants.listCellHeight)
                .if(!isSelected) {
                    $0.highPriorityGesture(
                        TapGesture()
                            .onEnded { _ in
                                didSelectAction()
                            }
                    )
                }

                Spacer()

                if isSelected {
                    MenuButton(
                        label: Icon(name: .dropdown, size: SizeConstants.fontSize),
                        content: {
                            Button("New Text File") { vm.createTextFile() }

                            MenuButton("New List ...") {
                                Button("1 column") { vm.createListFile(with: 1) }
                                ForEach(2 ... 10, id: \.self) { columnsNum in
                                    Button("\(columnsNum) columns") { vm.createListFile(with: columnsNum) }
                                }
                            }.menuButtonStyle(BorderlessButtonMenuButtonStyle())

                            Colors.clear.color
                                .frame(height: 0.1)
                                .frame(maxWidth: .infinity)

                            MenuButton("New Table ...") {
                                Button("1 column") { vm.createTableFile(with: 1) }
                                ForEach(2 ... 10, id: \.self) { columnsNum in
                                    Button("\(columnsNum) columns") { vm.createTableFile(with: columnsNum) }
                                }
                            }.menuButtonStyle(BorderlessButtonMenuButtonStyle())

                            Button("Delete Folder") { vm.destroyFolder() }

                        })
                        .frame(width: 22)
                        .menuButtonStyle(BorderlessButtonMenuButtonStyle())
                        .foregroundColor(Colors.button.color)
                } else {
                    Text(folder.files.count > 0 ? "(\(folder.files.count))" : "")
                        .lineLimit(1)
                        .frame(width: 30)
                        .foregroundColor(Colors.textDark.color)
                        .font(Font.custom(.pragmatica, size: 14))
                        .opacity(0.5)
                }
            }
            .frame(width: SizeConstants.folderListWidth, height: SizeConstants.listCellHeight)
            .padding(.trailing, 0)
            .foregroundColor(isSelected ? Colors.textLight.color : Colors.textDark.color)
            .onDrop(of: ["public.plain-text"], delegate: FolderDropViewDelegate(destFolder: folder, dragProcessor: dragProcessor))
            .border(dragProcessor.dropCandidate?.uid == folder.uid ? Colors.focus.color : Colors.clear.color)

            if folder.isOpened && folder.folders.count > 0 {
                ForEach(folder.folders, id: \.uid) { ff in
                    FolderListCell(folder: ff, isSelected: ff == vm.selectedFolder, isChild: true) {
                        vm.selectFolder(ff)
                    }
                }
            }

            if isSelected {
                ForEach(vm.files, id: \.uid) { f in
                    FileHeaderCell(file: f, isSelected: f.uid == vm.selectedFile?.uid, isFolderChild: self.isChild)
                        .frame(width: SizeConstants.folderListWidth, height: SizeConstants.listCellHeight)
                        .onDrag { self.dragProcessor.draggingFile = f; return NSItemProvider(object: NSString()) }
                }.background(Colors.black01.color)
            }
        }.onDrag { self.dragProcessor.draggingFolder = folder; return NSItemProvider(object: NSString()) }
    }
}

struct FileHeaderCell: View {
    @ObservedObject private var file: File
    private let vm = FolderListVM.shared
    private let isSelected: Bool
    private let folderOffset: CGFloat

    init(file: File, isSelected: Bool, isFolderChild: Bool) {
        self.file = file
        self.isSelected = isSelected
        folderOffset = isFolderChild ? SizeConstants.folderListChildOffset + 15 : 15
    }

    private func getFileIcon() -> FontIcon {
        if file.body is TableFileBody { return .table }
        if file.body is ListFileBody { return .list }
        return .file
    }

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
//            Icon(name: getFileIcon(), size: SizeConstants.iconSize)
//                .allowsHitTesting(false)
//                .padding(.leading, SizeConstants.padding)

            Spacer().frame(width: folderOffset)

            Text(" ")
                .lineLimit(1)
                .font(Font.custom(.pragmatica, size: SizeConstants.fontSize))
                .frame(width: 16)

            EditableText(file.title, uid: file.uid) { value in
                vm.updateFileTitle(file, title: value)
            }
            .frame(width: SizeConstants.folderListWidth - 60 - folderOffset, height: SizeConstants.listCellHeight)

            Spacer()

            FileMenuButton(file: file)
                .opacity(isSelected ? 1 : 0)
                .frame(width: 22)
        }
        .foregroundColor(isSelected ? Colors.textLight.color : Colors.textDark.color)

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
