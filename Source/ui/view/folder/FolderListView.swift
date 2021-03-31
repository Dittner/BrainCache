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
        VStack(alignment: .trailing, spacing: 0) {
            if vm.folders.count > 0 {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .trailing, spacing: 1) {
                        ForEach(vm.folders, id: \.id) { f in
                            FolderListCell(folder: f, isSelected: f == vm.selectedFolder) {
                                vm.selectFolder(f)
                            }
                        }

                        HSeparatorView()

                        TextButton(text: "New Folder", textColor: Colors.button.color, font: Font.custom(.pragmatica, size: SizeConstants.fontSize), padding: 5) {
                            self.vm.createFolder()
                        }
                    }
                }.frame(maxHeight: .infinity)
            } else {
                Spacer()
            }
        }
        .background(LinearGradient(gradient: Gradient(colors: Colors.folderListBG), startPoint: .top, endPoint: .bottom))
    }
}

enum FolderAction {
    case select
    case startEdit
    case stopEdit
}

struct FolderListCell: View {
    @ObservedObject private var folder: Folder
    @ObservedObject private var dragProcessor: FileToFolderDragProcessor
    let vm = FolderListVM.shared
    let didSelectAction: () -> Void
    private let isSelected: Bool

    init(folder: Folder, isSelected: Bool, didSelectAction: @escaping () -> Void) {
        print("FolderListCell, folder: \(folder.title)")
        self.folder = folder
        self.isSelected = isSelected
        self.didSelectAction = didSelectAction
        dragProcessor = vm.fileToFolderDragProcessor
    }

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Icon(name: .folder, size: SizeConstants.iconSize)
                .allowsHitTesting(false)

            EditableText(folder.title, uid: folder.uid, countClickActivation: 2) { value in
                folder.title = value
            }
            .frame(width: SizeConstants.folderListWidth - 50, height: SizeConstants.listCellHeight)

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

                        Button("Delete Folder") { vm.deleteFolder() }

                    })
                    .menuButtonStyle(BorderlessButtonMenuButtonStyle())
                    .foregroundColor(Colors.button.color)
            } else {
                Spacer()
            }
        }
        .padding(.horizontal, SizeConstants.padding)
        .foregroundColor(isSelected ? Colors.textLight.color : Colors.textDark.color)
        .frame(width: SizeConstants.folderListWidth, height: SizeConstants.listCellHeight)
        .onDrop(of: ["public.plain-text"], delegate: FileToFolderDropViewDelegate(destFolder: folder, dragProcessor: dragProcessor))
        .border(dragProcessor.dropCandidate?.uid == folder.uid ? Colors.focusColor.color : Colors.clear.color)

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
