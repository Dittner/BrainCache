//
//  DTO_v2.swift
//  BrainCache
//
//  Created by Alexander Dittner on 12.02.2021.
//

import Foundation

struct FolderDTO_v2: Codable {
    var uid: UID
    var title: String
    var selectedFileUID: UID?
    var parentFolderUID: UID?
    var isOpened: Bool = false
}

struct FileDTO_v2: Codable {
    var uid: UID
    var folderUID: UID
    var title: String
    var textBody: Data?
    var tableBody: Data?
    var listFileBody: Data?
    var useMonoFont: Bool
}

struct TableFileBodyDTO_v2: Codable {
    var headers: [TableHeaderDTO_v2]
    var rows: [[String]]
    var sortType: SortType
    var sortByHeaderIndex: Int
}

struct TableHeaderDTO_v2: Codable {
    var title: String
    var ratio: CGFloat
}

struct TextFileBodyDTO_v2: Codable {
    var text: String
}

struct ListFileBodyDTO_v2: Codable {
    var columns: [ListFileColumnDTO_v2]
}

struct ListFileColumnDTO_v2: Codable {
    var title: String
    var text: String
    var ratio: CGFloat
}
