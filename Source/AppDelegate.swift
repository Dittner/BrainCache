//
//  AppDelegate.swift
//  BrainCache
//
//  Created by Alexander Dittner on 20.03.2021.
//

import Cocoa
import SwiftUI

@main
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
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
        window.delegate = self
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        NSApplication.shared.hide(nil)
        return false
    }
}

class AppHostingView<Content>: NSHostingView<Content>, ObservableObject where Content: View {
    override func scrollWheel(with event: NSEvent) {
        NotificationCenter.default.post(name: .didWheelScroll, object: event)
    }
}
