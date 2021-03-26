//
//  AppDelegate.swift
//  BrainCache
//
//  Created by Alexander Dittner on 20.03.2021.
//

import Cocoa
import SwiftUI

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!

    func applicationWillFinishLaunching(_ notification: Notification) {
        UserDefaults.standard.set(true, forKey: "NSDisabledDictationMenuItem")
        UserDefaults.standard.set(true, forKey: "NSDisabledCharacterPaletteMenuItem")
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        BrainCacheContext.shared.run()

        // Create the SwiftUI view that provides the window contents.
        let app = BrainCacheApp()

        // Create the window and set the content view.
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.center()
        window.setFrameAutosaveName("Main Window")
        window.contentView = AppHostingView(rootView: app)
        window.makeKeyAndOrderFront(nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    // Menu Edit

    @IBOutlet var deleteFileMenu: NSMenuItem!
    @IBOutlet var deleteFolderMenu: NSMenuItem!
    @IBOutlet var monoFontMenu: NSMenuItem!

    @IBAction func menuDeleteFolder(_ sender: Any) {
        BrainCacheContext.shared.menuAPI.subject.send(.deleteFolder)
    }

    @IBAction func menuDeleteFile(_ sender: Any) {
        BrainCacheContext.shared.menuAPI.subject.send(.deleteFile)
    }

    @IBAction func menuMonoFont(_ sender: Any) {
        monoFontMenu.state = monoFontMenu.state == .off ? .on : .off
        BrainCacheContext.shared.menuAPI.subject.send(.monoFontSelected(value: monoFontMenu.state == .on))
    }

    // Menu File

    @IBOutlet var createTextFileMenu: NSMenuItem!
    @IBOutlet var createTableMenu: NSMenuItem!
    @IBOutlet var createListMenu: NSMenuItem!

    @IBAction func createTextFile(_ sender: Any) {
        BrainCacheContext.shared.menuAPI.subject.send(.createTextFile)
    }

    @IBAction func createFolder(_ sender: Any) {
        BrainCacheContext.shared.menuAPI.subject.send(.createFolder)
    }

    @IBAction func createTable(_ sender: Any) {
        if let menuItem = sender as? NSMenuItem {
            let columns = Int(menuItem.title.filter { "0" ... "9" ~= $0 }) ?? 2
            BrainCacheContext.shared.menuAPI.subject.send(.createTable(columns: columns))
        }
    }
    
    @IBAction func createList(_ sender: Any) {
        if let menuItem = sender as? NSMenuItem {
            let columns = Int(menuItem.title.filter { "0" ... "9" ~= $0 }) ?? 2
            BrainCacheContext.shared.menuAPI.subject.send(.createList(columns: columns))
        }
    }
}

class AppHostingView<Content>: NSHostingView<Content>, ObservableObject where Content: View {
    override func scrollWheel(with event: NSEvent) {
        NotificationCenter.default.post(name: .didWheelScroll, object: event)
    }
}
