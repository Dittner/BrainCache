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
            if vm.folders.count > 0 {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 1) {
                        ForEach(vm.folders, id: \.id) { f in
                            FolderListCell(folder: f, isSelected: f == vm.selectedFolder) {
                                vm.selectFolder(f)
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
    let didSelectAction: () -> Void
    private let isSelected: Bool

    init(folder: Folder, isSelected: Bool, didSelectAction: @escaping () -> Void) {
        print("FolderListCell, folder: \(folder.title)")
        self.folder = folder
        self.isSelected = isSelected
        self.didSelectAction = didSelectAction
    }

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Icon(name: .folder, size: SizeConstants.iconSize)
                .allowsHitTesting(false)
                .padding(.leading, SizeConstants.padding)

            EditableText(folder.title, uid: folder.uid) { value in
                folder.title = value
            }
            .frame(height: SizeConstants.listCellHeight)
        }
        .foregroundColor(isSelected ? Colors.textLight.color : Colors.textDark.color)
        .frame(width: SizeConstants.folderListWidth, height: SizeConstants.listCellHeight)
        .background(isSelected ? Colors.black02.color : Colors.clear.color)
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
