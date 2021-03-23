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
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(vm.folders.count == 0 ? "No Folder" : vm.folders.count == 1 ? "1 Folder" : "\(vm.folders.count) Folders")
                    .allowsHitTesting(false)
                    .lineLimit(1)
                    .font(Font.custom(.pragmatica, size: SizeConstants.fontSize))
                    .foregroundColor(Colors.textDark.color)

                Spacer()

                IconButton(name: .plus, size: SizeConstants.iconSize, color: Colors.button.color, height: SizeConstants.appHeaderHeight, text: "New Folder") {
                    self.vm.addNewFolder()
                }

            }.frame(height: SizeConstants.appHeaderHeight)
                .padding(.horizontal, SizeConstants.padding)

            HSeparatorView()

            if vm.folders.count > 0 {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 1) {
                        ForEach(vm.folders, id: \.id) { f in
                            FolderListCell(folder: f, isSelected: f == vm.selectedFolder, isEditing: f == vm.editingFolder) { action in
                                switch action {
                                case .select:
                                    vm.selectFolder(f)
                                case .startEdit:
                                    vm.startEditing(f: f)
                                case .stopEdit:
                                    vm.stopEditing()
                                }
                            }
                        }
                    }
                }
            }

            Spacer()
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
    let action: (FolderAction) -> Void
    private let isSelected: Bool
    private let isEditing: Bool

    init(folder: Folder, isSelected: Bool, isEditing: Bool, action: @escaping (FolderAction) -> Void) {
        print("FolderListCell, folder: \(folder.title)")
        self.folder = folder
        self.isSelected = isSelected
        self.isEditing = isEditing
        self.action = action
    }

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 5) {
            Icon(name: .folder, size: SizeConstants.iconSize)
                .allowsHitTesting(false)
                .padding(.leading, SizeConstants.padding)

            if isEditing {
                TextField("", text: $folder.title, onEditingChanged: { editing in
                    print("Folder: \(folder.title), editing: \(editing)")
                }, onCommit: {
                    action(.stopEdit)
                })

                    .textFieldStyle(PlainTextFieldStyle())
                    .font(Font.custom(.pragmatica, size: SizeConstants.fontSize))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.trailing, SizeConstants.padding)
                    .border(isEditing ? Colors.focusColor.color : Colors.clear.color)
            } else {
                Text(self.folder.title)
                    .allowsHitTesting(false)
                    .lineLimit(1)
                    .font(Font.custom(.pragmatica, size: SizeConstants.fontSize))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.trailing, SizeConstants.padding)
            }
        }
        .foregroundColor(isSelected ? Colors.textLight.color : Colors.textDark.color)
        .frame(width: SizeConstants.folderListWidth, height: SizeConstants.listCellHeight)
        .background(isSelected ? Colors.black02.color : Colors.clear.color)
        .onTapGesture(count: isSelected ? 2 : 1) {
            if isSelected {
                action(.startEdit)
            } else {
                action(.select)
            }
        }
    }
}
