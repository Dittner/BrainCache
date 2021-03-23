//
//  Buttons.swift
//  MP3Book
//
//  Created by Alexander Dittner on 08.02.2021.
//

import SwiftUI

struct IconButton: View {
    var name: FontIcon
    var size: CGFloat
    var color: Color
    var width: CGFloat = 25
    var height: CGFloat = 25
    var text: String? = nil
    let onAction: () -> Void

    @State private var onPressed = false

    var body: some View {
        if let text = text {
            HStack(alignment: .center, spacing: 2) {
                Text(name.rawValue)
                    .lineLimit(1)
                    .font(Font.custom(.icons, size: size))

                Text(text)
                    .lineLimit(1)
                    .font(Font.custom(.pragmatica, size: SizeConstants.fontSize))

            }.frame(height: height)
                .contentShape(Rectangle())
                .foregroundColor(onPressed ? color.opacity(0.5) : color)
                .onTapGesture {
                    self.onAction()
                }
                .pressAction {
                    self.onPressed = true
                } onRelease: {
                    self.onPressed = false
                }

        } else {
            Text(name.rawValue)
                .lineLimit(1)
                .font(Font.custom(.icons, size: size))
                .frame(width: width, height: height)
                .contentShape(Rectangle())
                .foregroundColor(onPressed ? color.opacity(0.5) : color)
                .onTapGesture {
                    self.onAction()
                }
                .pressAction {
                    self.onPressed = true
                } onRelease: {
                    self.onPressed = false
                }
        }
    }
}

struct TextButton: View {
    var text: LocalizedStringKey
    var textColor: Color
    var font: Font
    var height: CGFloat = 50
    let onAction: () -> Void

    @State private var onPressed = false

    var body: some View {
        Text(text)
            .lineLimit(1)
            .font(font)
            .foregroundColor(onPressed ? textColor.opacity(0.5) : textColor)
            .frame(height: height)
            .onTapGesture {
                self.onAction()
            }
            .pressAction {
                self.onPressed = true
            } onRelease: {
                self.onPressed = false
            }
    }
}

struct PressActions: ViewModifier {
    var onPress: () -> Void
    var onRelease: () -> Void

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged({ _ in
                        onPress()
                    })
                    .onEnded({ _ in
                        onRelease()
                    })
            )
    }
}

extension View {
    func pressAction(onPress: @escaping (() -> Void), onRelease: @escaping (() -> Void)) -> some View {
        modifier(PressActions(onPress: {
            onPress()
        }, onRelease: {
            onRelease()
        }))
    }
}
