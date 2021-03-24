//
//  TextFileSerializer_v1.swift
//  BrainCache
//
//  Created by Alexander Dittner on 12.02.2021.
//

import Foundation

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

class TableFileBodySerializer_v1: ISerializer {
    typealias Entity = TableFileBody
    let encoder: JSONEncoder
    let decoder: JSONDecoder

    init() {
        encoder = JSONEncoder()
        decoder = JSONDecoder()
    }

    func serialize(_ e: TableFileBody) throws -> Data {
        let headers = e.headers.map { TableHeaderDTO_v1(title: $0.title,
                                                        ratio: $0.ratio) }

        return try encoder.encode(TableFileBodyDTO_v1(headers: headers,
                                                      rows: e.rows.map { $0.cells.map { $0.text } },
                                                      sortType: e.sortType,
                                                      sortByHeaderIndex: e.sortByHeaderIndex))
    }

    func deserialize(data: Data) throws -> TableFileBody {
        let dto = try decoder.decode(TableFileBodyDTO_v1.self, from: data)

        let headers = dto.headers.map { TableHeader(title: $0.title, ratio: $0.ratio) }
        let tableRows = dto.rows.map { TableRow(cells: $0.map { TableCell(text: $0) }) }
        
        return TableFileBody(headers: headers,
                             rows: tableRows,
                             sortType: dto.sortType,
                             sortByHeaderIndex: dto.sortByHeaderIndex)
    }
}
