//
//  MenuAPI.swift
//  BrainCache
//
//  Created by Alexander Dittner on 23.03.2021.
//

import Combine
import Foundation
import SwiftUI

class MenuAPI {
    let subject = PassthroughSubject<MenuAPIEvent, Never>()
    private let appDelegate: AppDelegate

    init() {
        appDelegate = NSApplication.shared.delegate as! AppDelegate

        appDelegate.deleteFileMenu.isEnabled = false
        appDelegate.deleteFolderMenu.isEnabled = false
        appDelegate.monoFontMenu.isEnabled = false
    }

    // File Menu

    var isCreateTextFileEnabled: Bool = false {
        didSet {
            appDelegate.createTextFileMenu.isEnabled = isCreateTextFileEnabled
        }
    }

    var isCreateTableEnabled: Bool = false {
        didSet {
            appDelegate.createTableMenu.isEnabled = isCreateTableEnabled
        }
    }
    
    var isCreateListEnabled: Bool = false {
        didSet {
            appDelegate.createListMenu.isEnabled = isCreateListEnabled
        }
    }

    // Edit Menu

    var isDeleteFileEnabled: Bool = false {
        didSet {
            appDelegate.deleteFileMenu.isEnabled = isDeleteFileEnabled
        }
    }

    var isMonoFontEnabled: Bool = false {
        didSet {
            appDelegate.monoFontMenu.isEnabled = isMonoFontEnabled
        }
    }

    var isMonoFontSelected: Bool = false {
        didSet {
            appDelegate.monoFontMenu.state = isMonoFontSelected ? .on : .off
        }
    }

    var isDeleteFolderEnabled: Bool = false {
        didSet {
            appDelegate.deleteFolderMenu.isEnabled = isDeleteFolderEnabled
        }
    }
}

enum MenuAPIEvent {
    case createFolder
    case createTextFile
    case createTable(columns: Int)
    case createList(columns: Int)
    case deleteFile
    case deleteFolder
    case monoFontSelected(value: Bool)
}
