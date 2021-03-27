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
            Colors.black01.color
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
                                }
                                .foregroundColor(Colors.text.color)
                                .frame(width: fileBody.headers[index].ratio * (root.size.width - SizeConstants.tableRowNumberWidth - scrollerWidth))
                            }
                        }
                        HSeparatorView()
                    }

                    TextButton(text: "Add Row", textColor: Colors.button.color, font: Font.custom(.pragmatica, size: SizeConstants.fontSize), padding: 5) {
                        self.gc.addTableRow()
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
    private let headerHeight: CGFloat = SizeConstants.listCellHeight

    init(file: File, fileBody: ListFileBody, folder: Folder) {
        print("ListFileBodyView init, use mono font = \(file.useMonoFont)")
        self.file = file
        self.fileBody = fileBody
        self.folder = folder
        lc = ListController(list: fileBody)
    }

    var body: some View {
        GeometryReader { proxy in
            ListHeaderView(lc: lc, useMonoFont: file.useMonoFont)
                .frame(width: proxy.size.width - scrollerWidth, height: headerHeight)

            VScrollBar(uid: file.uid) {
                HStack(alignment: .top, spacing: 0) {
                    ForEach(fileBody.columns, id: \.uid) { column in
                        ListColumnCell(column: column, useMonoFont: file.useMonoFont, searchText: folder.search, width: column.ratio * (proxy.size.width - scrollerWidth), minHeight: proxy.size.height - SizeConstants.listCellHeight - headerHeight)
                            .frame(width: column.ratio * (proxy.size.width - scrollerWidth))
                    }
                }
            }
            .padding(.top, headerHeight)
            .frame(width: proxy.size.width, height: proxy.size.height - headerHeight)

            HSeparatorView()
                .offset(y: headerHeight)

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
