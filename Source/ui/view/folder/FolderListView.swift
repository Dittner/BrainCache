//
//  ContentView.swift
//  BrainCache
//
//  Created by Alexander Dittner on 20.03.2021.
//

import SwiftUI

struct FolderListView: View {
    @ObservedObject private var vm = FolderListVM.shared

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .trailing, spacing: 1) {
                ForEach(vm.folders, id: \.uid) { f in
                    FolderListCell(folder: f, isSelected: f == vm.selectedFolder) {
                        vm.selectFolder(f)
                    }
                }

                HSeparatorView()

                TextButton(text: "New Folder", textColor: Colors.button.color, font: Font.custom(.pragmatica, size: SizeConstants.fontSize), padding: 5) {
                    self.vm.createFolder()
                }
            }
        }.background(FolderRootDropIndicator())

            .background(LinearGradient(gradient: Gradient(colors: Colors.folderListBG), startPoint: .top, endPoint: .bottom))
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
    private let childFolderOffset: CGFloat = 15

    init(folder: Folder, isSelected: Bool, didSelectAction: @escaping () -> Void) {
        self.folder = folder
        self.isSelected = isSelected
        self.didSelectAction = didSelectAction
        dragProcessor = vm.fileToFolderDragProcessor
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 1) {
            HStack(alignment: .center, spacing: 0) {
                IconButton(name: .arrow, size: SizeConstants.iconSize, color: Colors.textDark.color, width: 16) {
                    folder.update(isOpened: !folder.isOpened)
                }.rotationEffect(folder.isOpened ? .degrees(0) : .degrees(-90))
                    .opacity(folder.folders.count > 0 ? 1 : 0)
                    .disabled(folder.folders.count == 0)

                Icon(name: .folder, size: SizeConstants.iconSize)
                    .allowsHitTesting(false)

                EditableText(folder.title, uid: folder.uid, countClickActivation: 2) { value in
                    vm.updateFolderTitle(folder, title: value)
                }
                .frame(width: SizeConstants.folderListWidth - (folder.parent == nil ? 60 : 60 + childFolderOffset), height: SizeConstants.listCellHeight)
                .if(!isSelected) {
                    $0.highPriorityGesture(
                        TapGesture()
                            .onEnded { _ in
                                didSelectAction()
                            }
                    )
                }

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
                        .menuButtonStyle(BorderlessButtonMenuButtonStyle())
                        .foregroundColor(Colors.button.color)
                } else {
                    Spacer()
                }
            }
            .frame(height: SizeConstants.listCellHeight)
            .padding(.trailing, SizeConstants.padding / 5)
            .foregroundColor(isSelected ? Colors.textLight.color : Colors.textDark.color)
            .onDrop(of: ["public.plain-text"], delegate: FolderDropViewDelegate(destFolder: folder, dragProcessor: dragProcessor))
            .border(dragProcessor.dropCandidate?.uid == folder.uid ? Colors.focus.color : Colors.clear.color)

            if folder.isOpened && folder.folders.count > 0 {
                ForEach(folder.folders, id: \.uid) { ff in
                    FolderListCell(folder: ff, isSelected: ff == vm.selectedFolder) {
                        vm.selectFolder(ff)
                    }
                    .frame(width: SizeConstants.folderListWidth - childFolderOffset, height: SizeConstants.listCellHeight)
                }
            }
        }.onDrag { self.dragProcessor.draggingFolder = folder; return NSItemProvider(object: NSString()) }
    }
}
