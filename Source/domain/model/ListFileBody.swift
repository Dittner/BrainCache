//
//  Table.swift
//  BrainCache
//
//  Created by Alexander Dittner on 24.03.2021.
//

import Combine
import SwiftUI

class ListFileBody: FileBody {
    var stateDidChange = CurrentValueSubject<Bool, Never>(false)
    
    private(set) var columns: [ListColumn]

    private var disposeBag: Set<AnyCancellable> = []
    init(columns: [ListColumn]) {
        self.columns = columns
        
        for c in columns {
            c.$text
                .removeDuplicates()
                .dropFirst()
                .sink { _ in
                    self.stateDidChange.send(true)
                }
                .store(in: &disposeBag)
            
            c.$ratio
                .removeDuplicates()
                .dropFirst()
                .sink { _ in
                    self.stateDidChange.send(true)
                }
                .store(in: &disposeBag)
        }
    }
}

class ListColumn: ObservableObject {
    let uid: UID = UID()
    @Published var text: String
    @Published var ratio: CGFloat // 0..1

    init(text: String, ratio: CGFloat) {
        self.text = text
        self.ratio = ratio
    }
}
