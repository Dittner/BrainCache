//
//  DTO_v3.swift
//  BrainCache
//
//  Created by Alexander Dittner on 12.02.2021.
//

import Foundation

struct FolderDTO_v3: Codable {
    var uid: UID
    var title: String
    var selectedFile: UID?
    var files: [UID]
    var folders: [UID]
    var isOpened: Bool = false
}

struct FileDTO_v3: Codable {
    var uid: UID
    var title: String
    var textBody: Data?
    var tableBody: Data?
    var listFileBody: Data?
    var useMonoFont: Bool
}

struct TableFileBodyDTO_v3: Codable {
    var headers: [TableHeaderDTO_v3]
    var rows: [[String]]
    var sortType: SortType
    var sortByHeaderIndex: Int
}

struct TableHeaderDTO_v3: Codable {
    var title: String
    var ratio: CGFloat
}

struct TextFileBodyDTO_v3: Codable {
    var text: String
}

struct ListFileBodyDTO_v3: Codable {
    var columns: [ListFileColumnDTO_v3]
}

struct ListFileColumnDTO_v3: Codable {
    var title: String
    var text: String
    var ratio: CGFloat
}
