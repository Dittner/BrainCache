//
//  Table.swift
//  BrainCache
//
//  Created by Alexander Dittner on 24.03.2021.
//

import Combine
import SwiftUI

class TextFileBody: FileBody, ObservableObject {
    @Published var text: String

    var stateDidChange = PendingPassthroughSubject<DomainEntityStateDidChangeEvent, Never>()

    private var disposeBag: Set<AnyCancellable> = []
    init(text: String) {
        self.text = text

        $text
            .removeDuplicates()
            .dropFirst()
            .sink { _ in
                self.stateDidChange.send(.textFileContent)
            }
            .store(in: &disposeBag)
    }
}
