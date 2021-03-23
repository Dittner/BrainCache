//
//  FilerListView.swift
//  BrainCache
//
//  Created by Alexander Dittner on 20.03.2021.
//

import SwiftUI

struct FileListView: View {
    @ObservedObject private var vm = FileListVM.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 5) {
                if vm.files.count > 0 {
                    ForEach(vm.files, id: \.id) { f in
                        FileListCell(file: f, isSelected: f == vm.selectedFile, isEditing: f == vm.editingFile) { action in
                            switch action {
                            case .select:
                                vm.selectFile(f)
                            case .startEdit:
                                vm.startEditing(f: f)
                            case .stopEdit:
                                vm.stopEditing()
                            }
                        }

                        VSeparatorView(verticalPadding: 5)
                    }
                }

                if let folder = vm.selectedFolder {
                    IconButton(name: .plus, size: SizeConstants.iconSize, color: Colors.button.color, height: SizeConstants.appHeaderHeight, text: "New File") {
                        self.vm.addNewFile()
                    }.padding(.horizontal, SizeConstants.padding)

                    Spacer()

                    SearchView(folder: folder)
                        .padding(.trailing, SizeConstants.padding)
                }

            }.frame(height: SizeConstants.appHeaderHeight)

            HSeparatorView()

            if let folder = vm.selectedFolder, let file = vm.selectedFile {
                FileContentView(file: file, folder: folder)
            } else {
                Spacer()
            }
        }
        .frame(maxHeight: .infinity)
    }
}

enum FileAction {
    case select
    case startEdit
    case stopEdit
}

struct FileListCell: View {
    @ObservedObject private var file: File
    let action: (FileAction) -> Void
    private let isSelected: Bool
    private let isEditing: Bool

    init(file: File, isSelected: Bool, isEditing: Bool, action: @escaping (FileAction) -> Void) {
        print("FileListCell, file: \(file.title)")
        self.file = file
        self.isSelected = isSelected
        self.isEditing = isEditing
        self.action = action
    }

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 5) {
            Icon(name: .file, size: SizeConstants.iconSize)
                .allowsHitTesting(false)
                .padding(.leading, SizeConstants.padding)

            if isEditing {
                TextField("", text: $file.title, onEditingChanged: { _ in

                }, onCommit: {
                    action(.stopEdit)
                })

                    .textFieldStyle(PlainTextFieldStyle())
                    .font(Font.custom(.pragmatica, size: SizeConstants.fontSize))
                    .padding(.trailing, SizeConstants.padding)
                    .frame(width: SizeConstants.appHeaderHeight)
                    .border(isEditing ? Colors.focusColor.color : Colors.clear.color)
            } else {
                Text(self.file.title)
                    .allowsHitTesting(false)
                    .lineLimit(1)
                    .font(Font.custom(.pragmatica, size: SizeConstants.fontSize))
                    .padding(.trailing, SizeConstants.padding)
            }
        }
        .foregroundColor(isSelected ? Colors.textLight.color : Colors.textDark.color)
        .frame(height: SizeConstants.listCellHeight)
        .background(Colors.clear.color)
        .onTapGesture(count: isSelected ? 2 : 1) {
            if isSelected {
                action(.startEdit)
            } else {
                action(.select)
            }
        }
    }
}

struct FileContentView: View {
    @ObservedObject private var file: File
    @ObservedObject private var folder: Folder

    init(file: File, folder: Folder) {
        print("FileContentView init, use mono font = \(file.useMonoFont)!!!")
        self.file = file
        self.folder = folder
    }

    var body: some View {
        GeometryReader { geometry in
            if file.useMonoFont {
                NSTextEditor(text: $file.content, font: NSFont(name: .mono, size: SizeConstants.fontSize), textColor: Colors.text, lineHeight: SizeConstants.fontLineHeight, highlightedText: folder.search)
                    .padding(.leading, SizeConstants.padding - 5)
                    .frame(width: geometry.size.width, height: geometry.size.height)
            } else {
                NSTextEditor(text: $file.content, font: NSFont(name: .pragmatica, size: SizeConstants.fontSize), textColor: Colors.text, lineHeight: SizeConstants.fontLineHeight, highlightedText: folder.search)
                    .padding(.leading, SizeConstants.padding - 5)
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
    }
}

struct SearchView: View {
    @ObservedObject private var vm = FileListVM.shared
    @ObservedObject private var folder: Folder

    init(folder: Folder) {
        self.folder = folder
    }

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 5) {
            Icon(name: .search, size: SizeConstants.iconSize)
                .allowsHitTesting(false)
                .padding(.leading, 5)

            TextField("", text: $folder.search)
                .textFieldStyle(PlainTextFieldStyle())
                .font(Font.custom(.pragmatica, size: SizeConstants.fontSize))

            if folder.search.count > 0 {
                IconButton(name: .close, size: SizeConstants.iconSize, color: folder.search.count > 0 ? Colors.textLight.color : Colors.textDark.color, width: SizeConstants.iconSize + 10, height: SizeConstants.iconSize + 10) {
                    folder.search = ""
                }
            }
        }
        .frame(width: SizeConstants.searchBarWidth, height: SizeConstants.appHeaderHeight)
        .foregroundColor(folder.search.count > 0 ? Colors.textLight.color : Colors.textDark.color)
        .background(Colors.black02.color)
    }
}
