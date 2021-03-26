//
//  VScrollBar.swift
//  Faustus
//
//  Created by Alexander Dittner on 30.04.2020.
//  Copyright © 2020 Alexander Dittner. All rights reserved.
//

import Combine
import SwiftUI

class VScrollBarController: ObservableObject {
    @Published private(set) var contentHeight: CGFloat = CGFloat.zero
    @Published private(set) var windowHeight: CGFloat = CGFloat.zero
    @Published var scrollPosition = CGFloat.zero
    @Published var scaleY: CGFloat = 1
    var contentUID: UID
    static var scrollPositionCache: [UID: CGFloat] = [:]

    let scrollerWidth: CGFloat = 15
    let scrollFactor: CGFloat = 15
    let debugInfo = true

    init(contentUID: UID) {
        if debugInfo { logInfo(msg: "[VScrollBarController], contentUID = \(contentUID): init") }
        self.contentUID = contentUID

        if let cachedPosition = VScrollBarController.scrollPositionCache[contentUID] {
            DispatchQueue.main.asyncAfter(deadline: .now() + DispatchTimeInterval.milliseconds(100)) { [weak self] in
                withAnimation(.easeInOut(duration: 0.2)) {
                    self?.scrollPosition = cachedPosition
                }
            }

            if debugInfo { logInfo(msg: "[VScrollBarController], new contentUID = \(contentUID): update, read pos = \(cachedPosition)") }
        }

        NotificationCenter.default.addObserver(self, selector: #selector(onDidWheelScroll(_:)), name: .didWheelScroll, object: nil)
    }

    @objc func onDidWheelScroll(_ notification: Notification) {
        guard let event = notification.object as? NSEvent else { return }
        guard let windowFrame = (NSApplication.shared.delegate as! AppDelegate).window?.frame else { return }

        if event.locationInWindow.x > SizeConstants.folderListWidth && windowFrame.height - event.locationInWindow.y > SizeConstants.appHeaderHeight + SizeConstants.windowHeaderHeight {
            updateScrollPosition(with: event.deltaY * scrollFactor)
        }
    }

    func updateFrame(contentHeight: CGFloat, windowHeight: CGFloat) {
        guard contentHeight > 0 && windowHeight > 0 else { return }

        if self.contentHeight != contentHeight || self.windowHeight != windowHeight {
            let difference = self.contentHeight - contentHeight

            self.contentHeight = contentHeight
            self.windowHeight = windowHeight
            scaleY = contentHeight > 0 ? min(1, windowHeight / contentHeight) : 1

            if abs(difference) > 0 && abs(difference) < 50 {
                updateScrollPosition(with: difference)
            }

            if debugInfo { logInfo(msg: "[VScrollBarController], contentUID = \(contentUID): contentHeight = \(contentHeight)") }

            if contentHeight < windowHeight {
                scrollPosition = CGFloat.zero
            }
        }
    }

    func updateScrollPosition(with offset: CGFloat) {
        
        
        withAnimation(.easeInOut(duration: 0.2)) {
            let maxScrollOffset = windowHeight - contentHeight
            if maxScrollOffset > 0 {
                scrollPosition = CGFloat.zero
            } else if scrollPosition + offset > 0 {
                scrollPosition = CGFloat.zero
            } else if scrollPosition + offset < maxScrollOffset {
                scrollPosition = maxScrollOffset
            } else {
                scrollPosition += offset
            }
        }
        
        VScrollBarController.scrollPositionCache[contentUID] = scrollPosition
    }

    //
    // handlers
    //

    func onScrolled(_ deltaY: CGFloat) {
        updateScrollPosition(with: deltaY)
    }

    func onClicked(_ ratio: CGFloat) {
        if windowHeight < contentHeight {
            let maxPos = windowHeight - contentHeight
            let pos = -ratio * windowHeight / scaleY
            withAnimation {
                scrollPosition = maxPos > pos ? maxPos : pos
            }
        }
    }

    var startLocationPosY: CGFloat = 0
    var thumbDownOffset: CGFloat = 0
    func onDragged(_ value: DragGesture.Value) {
        if windowHeight < contentHeight {
            let maxPos = windowHeight - contentHeight
            if startLocationPosY != value.startLocation.y {
                startLocationPosY = value.startLocation.y
                thumbDownOffset = value.startLocation.y + scrollPosition * scaleY
            }
            let pos = (thumbDownOffset - value.location.y) / scaleY
            withAnimation {
                scrollPosition = maxPos > pos ? maxPos : pos > 0 ? 0 : pos
            }
        }
    }
}

struct VScrollBar<Content>: View where Content: View {
    @ObservedObject var controller: VScrollBarController

    let content: Content
    let scrollerBGColor = Color(rgb: 0x37383A)
    let scrollerThumbColor = Color(rgb: 0x737475)

    init(uid: UID, @ViewBuilder content: () -> Content) {
        print("CustomScrollView init \(uid)")
        controller = VScrollBarController(contentUID: uid)
        self.content = content()
    }

    func updateFrameHeight(contentHeight: CGFloat, windowHeight: CGFloat) -> CGFloat {
        if contentHeight != windowHeight {
            controller.updateFrame(contentHeight: contentHeight, windowHeight: windowHeight)
        }
        return contentHeight
    }

    var body: some View {
        GeometryReader { window in
            self.content
                .frame(width: window.size.width, alignment: .topLeading)
                .background(GeometryReader { proxy in
                    Color.clear.frame(height: updateFrameHeight(contentHeight: proxy.size.height, windowHeight: window.size.height))
                })
                .offset(y: self.controller.scrollPosition)
                .clipped()

            ZStack(alignment: .topLeading) {
                MouseWheelDetector(onScrolled: self.controller.onScrolled, onClicked: self.controller.onClicked)

                RoundedRectangle(cornerRadius: 4)
                    .fill(scrollerThumbColor)
                    .frame(width: 7, height: window.size.height * self.controller.scaleY)
                    .offset(x: 4, y: -self.controller.scrollPosition * self.controller.scaleY)
                    .allowsHitTesting(true)
                    .gesture(DragGesture().onChanged { value in
                        self.controller.onDragged(value)
                    }).opacity(self.controller.scaleY == 1 ? 0 : 1)

            }.background(scrollerBGColor)
                .frame(width: controller.scrollerWidth, height: window.size.height, alignment: .topLeading)
                .offset(x: window.size.width - controller.scrollerWidth)
        }.zIndex(-1)
    }
}

struct MouseWheelDetector: NSViewRepresentable {
    public let onScrolled: (_ deltaY: CGFloat) -> Void
    public var onClicked: ((_ ration: CGFloat) -> Void)?

    func updateNSView(_ nsView: MouseWheelDetectorView, context: Context) {
        nsView.parent = self
    }

    func makeNSView(context: Context) -> MouseWheelDetectorView {
        let view = MouseWheelDetectorView()
        view.parent = self
        return view
    }
}

class MouseWheelDetectorView: NSView {
    var parent: MouseWheelDetector!

    override func scrollWheel(with event: NSEvent) {
        parent?.onScrolled(event.deltaY)
    }

    override func mouseDown(with event: NSEvent) {
        let ration = bounds.height == 0 ? 0 : (bounds.height - event.locationInWindow.y) / bounds.height
        parent?.onClicked?(ration)
    }
}
