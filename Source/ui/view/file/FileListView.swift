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
                    SearchInputView(folder: folder)
                }

            }.frame(height: SizeConstants.appHeaderHeight)
                .background(Colors.black02.color)
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
    let didSelectAction: () -> Void
    private let isSelected: Bool

    init(file: File, isSelected: Bool, didSelectAction: @escaping () -> Void) {
        self.file = file
        self.isSelected = isSelected
        self.didSelectAction = didSelectAction
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
        .background(Colors.black02.color)
    }
}

struct TextFileView: View {
    @ObservedObject private var file: File
    private let fileBody: TextFileBody
    @ObservedObject private var folder: Folder
    @ObservedObject private var notifier = HeightDidChangeNotifier()

    init(file: File, fileBody: TextFileBody, folder: Folder) {
        self.file = file
        self.fileBody = fileBody
        self.folder = folder
    }

    var body: some View {
        GeometryReader { proxy in
            VScrollBar(uid: file.uid) {
                TextFileBodyView(fileBody: fileBody, useMonoFont: file.useMonoFont, searchText: folder.search, width: proxy.size.width, minHeight: proxy.size.height)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
}

struct TextFileBodyView: View {
    @ObservedObject private var fileBody: TextFileBody
    @ObservedObject private var notifier = HeightDidChangeNotifier()
    let useMonoFont: Bool
    let searchText: String
    let font: NSFont
    let width: CGFloat
    let minHeight: CGFloat

    init(fileBody: TextFileBody, useMonoFont: Bool, searchText: String, width: CGFloat, minHeight: CGFloat) {
        print("TextFileBodyView init, useMonoFont = \(useMonoFont)")
        self.fileBody = fileBody
        self.useMonoFont = useMonoFont
        self.searchText = searchText
        self.width = width
        self.minHeight = minHeight
        font = NSFont(name: useMonoFont ? .mono : .pragmatica, size: SizeConstants.fontSize)
    }

    var body: some View {
        TextArea(text: $fileBody.text, height: $notifier.height, textColor: Colors.text, font: font, highlightedText: searchText, lineHeight: SizeConstants.fontLineHeight, width: width - 2 * SizeConstants.padding)
            .colorScheme(.dark)
            .offset(x: -4)
            .padding(.horizontal, SizeConstants.padding)
            .frame(height: max(minHeight - 5, notifier.height))
    }
}

struct TableFileView: View {
    @ObservedObject private var gc: GridController
    @ObservedObject private var file: File
    private let fileBody: TableFileBody
    private let folder: Folder
    private let scrollerWidth: CGFloat = 15

    init(file: File, fileBody: TableFileBody, folder: Folder) {
        print("TableContentView init, use mono font = \(file.useMonoFont)")
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

            VScrollBar(uid: file.uid) {
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
                                .frame(width: fileBody.headers[index].ratio * (root.size.width - SizeConstants.tableRowNumberWidth - scrollerWidth))
                            }
                            
                            //Spacer()
                        }
                        HSeparatorView()
                    }

                    TextButton(text: "Add Row", textColor: Colors.button.color, font: Font.custom(.pragmatica, size: SizeConstants.fontSize), padding: 5) {
                        self.gc.addTableRow()
                        self.gc.updateGridView()
                    }

                    Spacer()
                }.frame(width: root.size.width - scrollerWidth)
            }
            .frame(width: root.size.width, height: root.size.height - SizeConstants.listCellHeight)
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

struct ListFileView: View {
    @ObservedObject private var lc: ListController
    @ObservedObject private var file: File
    private let fileBody: ListFileBody
    @ObservedObject private var folder: Folder
    private let scrollerWidth: CGFloat = 15

    init(file: File, fileBody: ListFileBody, folder: Folder) {
        print("ListFileBodyView init, use mono font = \(file.useMonoFont)")
        self.file = file
        self.fileBody = fileBody
        self.folder = folder
        lc = ListController(list: fileBody)
    }

    var body: some View {
        GeometryReader { proxy in
            VScrollBar(uid: file.uid) {
                HStack(alignment: .top, spacing: 0) {
                    ForEach(fileBody.columns, id: \.uid) { column in
                        ListColumnCell(column: column, useMonoFont: file.useMonoFont, searchText: folder.search, width: column.ratio * (proxy.size.width - scrollerWidth), minHeight: proxy.size.height)
                            .frame(width: column.ratio * (proxy.size.width - scrollerWidth))
                    }
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)

            VSeparatorView()
                .offset(x: proxy.size.width - scrollerWidth)

            ListLinesView(lc)
                .frame(width: proxy.size.width - scrollerWidth)
        }
    }
}

struct ListColumnCell: View {
    @ObservedObject private var column: ListColumn
    @ObservedObject private var notifier = HeightDidChangeNotifier()
    let useMonoFont: Bool
    let searchText: String
    let font: NSFont
    let width: CGFloat
    let minHeight: CGFloat

    init(column: ListColumn, useMonoFont: Bool, searchText: String, width: CGFloat, minHeight: CGFloat) {
        print("ListColumnCell init, useMonoFont = \(useMonoFont)")
        self.column = column
        self.useMonoFont = useMonoFont
        self.searchText = searchText
        self.width = width
        self.minHeight = minHeight
        font = NSFont(name: useMonoFont ? .mono : .pragmatica, size: SizeConstants.fontSize)
    }

    var body: some View {
        TextArea(text: $column.text, height: $notifier.height, textColor: Colors.text, font: font, highlightedText: searchText, lineHeight: SizeConstants.fontLineHeight, width: width - 2 * SizeConstants.padding)
            .colorScheme(.dark)
            .offset(x: -4)
            .padding(.horizontal, SizeConstants.padding)
            .frame(height: max(minHeight - 5, notifier.height))
    }
}
