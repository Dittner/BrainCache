//
//  BrainCacheApp.swift
//  BrainCache
//
//  Created by Alexander Dittner on 20.03.2021.
//

import SwiftUI

struct BrainCacheApp: View {
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            FolderListView()
                .frame(width: SizeConstants.folderListWidth)
                .frame(maxHeight: .infinity, alignment: .topLeading)

            FileListView()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }.frame(minWidth: 1550, idealWidth: 1550, maxWidth: .infinity, minHeight: 700, idealHeight: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Colors.appBG.color)
    }
}
