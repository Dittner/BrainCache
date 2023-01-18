//
//  NSWindow.swift
//  BrainCache
//
//  Created by Alexander Dittner on 27.01.2020.
//  Copyright © 2020 Alexander Dittner. All rights reserved.
//

import SwiftUI
extension NSWindow {
    open override var acceptsFirstResponder: Bool { return true }

    func moveToCenter() {
        let monitorFrame: NSRect = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 0, height: 0)
        print("monitor, wid = \(monitorFrame.width), hei = \(monitorFrame.height)")

        setFrameOrigin(NSPoint(x: (monitorFrame.width - frame.width) / 2, y: (monitorFrame.height - frame.height) / 2))
    }

    func restoreLastFrame() {
        let x = UserDefaults.standard.integer(forKey: "WindowX")
        let y = UserDefaults.standard.integer(forKey: "WindowY")
        let w = UserDefaults.standard.integer(forKey: "WindowWidth")
        let h = UserDefaults.standard.integer(forKey: "WindowHight")
        if w > 0 && h > 0 {
            let rect = NSRect(x: x, y: y, width: w, height: h)

            // setFrameOrigin(NSPoint(x: x, y: y))
            logInfo(msg: "window restore frame, x,y,w,h = \(x),\(y),\(w),\(h)")
            setFrame(rect, display: true, animate: true)
        }
    }

    func storeFrame() {
        logInfo(msg: "window store frame, x,y,w,h = \(frame.minX), \(frame.minY), \(frame.width), \(frame.height)")

        UserDefaults.standard.set(Int(frame.minX < 10 ? 0 : frame.minX), forKey: "WindowX")
        UserDefaults.standard.set(Int(frame.minY), forKey: "WindowY")
        UserDefaults.standard.set(Int(frame.width), forKey: "WindowWidth")
        UserDefaults.standard.set(Int(frame.height), forKey: "WindowHight")
    }
}

extension Notification.Name {
    static let didWheelScroll = Notification.Name("didWheelScroll")
    static let didKeyDownScroll = Notification.Name("didKeyDownScroll")
    static let didKeyDownSearch = Notification.Name("didKeyDownSearch")
}
