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
            HStack(alignment: .center, spacing: 1) {
                if vm.files.count > 0 {
                    ForEach(vm.files, id: \.id) { f in
                        FileListCell(file: f, isSelected: f.uid == vm.selectedFile?.uid) {
                            vm.selectFile(f)
                        }

                        VSeparatorView(verticalPadding: 5)
                    }
                }

                Spacer()

                if let folder = vm.selectedFolder {
                    SearchView(folder: folder)
                }

            }.frame(height: SizeConstants.appHeaderHeight)
                .background(Colors.black02.color)

            HSeparatorView()

            if let folder = vm.selectedFolder, let file = vm.selectedFile, let fileBody = file.body as? TextFileBody {
                TextFileBodyView(file: file, fileBody: fileBody, folder: folder)
            } else if let folder = vm.selectedFolder, let file = vm.selectedFile, let fileBody = file.body as? TableFileBody {
                TableFileBodyView(file: file, fileBody: fileBody, folder: folder)
            } else {
                Spacer()
            }
        }
        .frame(maxHeight: .infinity)
    }
}

struct FileListCell: View {
    @ObservedObject private var file: File
    let didSelectAction: () -> Void
    private let isSelected: Bool

    init(file: File, isSelected: Bool, didSelectAction: @escaping () -> Void) {
        print("FileListCell, file: \(file.title)")
        self.file = file
        self.isSelected = isSelected
        self.didSelectAction = didSelectAction
    }

    private func getFileIcon() -> FontIcon {
        return file.body is TableFileBody ? .table : .file
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
            .frame(maxWidth: SizeConstants.fileListWidth)
        }
        .foregroundColor(isSelected ? Colors.textLight.color : Colors.textDark.color)
        .frame(height: SizeConstants.listCellHeight)
        .if(!isSelected) {
            $0.highPriorityGesture(
                TapGesture()
                    .onEnded { _ in
                        didSelectAction()
                    }
            )
        }
    }
}

struct TextFileBodyView: View {
    @ObservedObject private var file: File
    @ObservedObject private var fileBody: TextFileBody
    @ObservedObject private var folder: Folder

    init(file: File, fileBody: TextFileBody, folder: Folder) {
        self.file = file
        self.fileBody = fileBody
        self.folder = folder
    }

    var body: some View {
        GeometryReader { geometry in
            if file.useMonoFont {
                NSTextEditor(text: $fileBody.text, font: NSFont(name: .mono, size: SizeConstants.fontSize), textColor: Colors.text, lineHeight: SizeConstants.fontLineHeight, highlightedText: folder.search)
                    .padding(.leading, SizeConstants.padding - 5)
                    .frame(width: geometry.size.width, height: geometry.size.height)
            } else {
                NSTextEditor(text: $fileBody.text, font: NSFont(name: .pragmatica, size: SizeConstants.fontSize), textColor: Colors.text, lineHeight: SizeConstants.fontLineHeight, highlightedText: folder.search)
                    .padding(.leading, SizeConstants.padding - 5)
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
    }
}

struct TableFileBodyView: View {
    @ObservedObject private var gc: GridController
    @ObservedObject private var file: File
    private let fileBody: TableFileBody
    private let folder: Folder
    private let scrollerWidth: CGFloat = 15

    init(file: File, fileBody: TableFileBody, folder: Folder) {
        print("TableContentView init, use mono font = \(file.useMonoFont)!!!")
        self.file = file
        self.fileBody = fileBody
        self.folder = folder
        gc = GridController(table: fileBody)
    }

    var body: some View {
        GeometryReader { root in
            Colors.black02.color
                .frame(width: SizeConstants.tableRowNumberWidth)

            GridHeaderView(gc, useMonoFont: file.useMonoFont)
                .offset(x: SizeConstants.tableRowNumberWidth)
                .frame(width: root.size.width - scrollerWidth - SizeConstants.tableRowNumberWidth, height: SizeConstants.listCellHeight)

            ScrollView(.vertical, showsIndicators: /*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/) {
                GeometryReader { proxy in
                    VStack(alignment: .trailing, spacing: 0) {
                        ForEach(fileBody.rows.enumeratedArray(), id: \.offset) { rowIndex, row in
                            HStack(alignment: .top, spacing: 0) {
                                Text("\(rowIndex + 1)")
                                    .lineLimit(1)
                                    .font(Font.custom(file.useMonoFont ? .mono : .pragmatica, size: SizeConstants.fontSize))
                                    .foregroundColor(Colors.textDark.color)
                                    .padding(.horizontal, SizeConstants.padding)
                                    .padding(.top, 5)
                                    .frame(width: SizeConstants.tableRowNumberWidth, alignment: .trailing)

                                ForEach(row.cells.enumeratedArray(), id: \.offset) { index, cell in
                                    EditableMultilineText(cell.text, uid: cell.uid, alignment: .leading, useMonoFont: file.useMonoFont) { value in
                                        self.gc.updateCell(cell, text: value)
                                        self.gc.updateGridView()
                                    }
                                    .foregroundColor(Colors.text.color)
                                    .frame(width: fileBody.headers[index].ratio * (proxy.size.width - SizeConstants.tableRowNumberWidth))
                                }
                            }
                            HSeparatorView()
                        }

                        TextButton(text: "Add Row", textColor: Colors.button.color, font: Font.custom(.pragmatica, size: SizeConstants.fontSize), padding: 5) {
                            self.gc.addTableRow()
                            self.gc.updateGridView()
                        }
                    }
                }
            }
            .frame(width: root.size.width)
            .padding(.top, SizeConstants.listCellHeight)
            .clipped()

            HSeparatorView()
                .offset(y: SizeConstants.listCellHeight)

            VSeparatorView()
                .offset(x: SizeConstants.tableRowNumberWidth)

            VSeparatorView()
                .offset(x: root.size.width - scrollerWidth)

            GridLinesView(gc)
                .offset(x: SizeConstants.tableRowNumberWidth)
                .frame(width: root.size.width - scrollerWidth - SizeConstants.tableRowNumberWidth)
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
