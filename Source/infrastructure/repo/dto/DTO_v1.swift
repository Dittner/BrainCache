//
//  DTO_v1.swift
//  BrainCache
//
//  Created by Alexander Dittner on 12.02.2021.
//

import Foundation

struct FolderDTO_v1: Codable {
    var uid: UID
    var title: String
    var selectedFileUID: UID?
}

struct FileDTO_v1: Codable {
    var uid: UID
    var folderUID: UID
    var title: String
    var textBody: Data?
    var tableBody: Data?
    var listFileBody: Data?
    var useMonoFont: Bool
}

struct TableFileBodyDTO_v1: Codable {
    var headers: [TableHeaderDTO_v1]
    var rows: [[String]]
    var sortType: SortType
    var sortByHeaderIndex: Int
}

struct TableHeaderDTO_v1: Codable {
    var title: String
    var ratio: CGFloat
}

struct TextFileBodyDTO_v1: Codable {
    var text: String
}

struct ListFileBodyDTO_v1: Codable {
    var columns: [ListFileColumnDTO_v1]
}

struct ListFileColumnDTO_v1: Codable {
    var title: String
    var text: String
    var ratio: CGFloat
}
