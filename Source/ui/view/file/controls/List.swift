//
//  ListController.swift
//  BrainCache
//
//  Created by Alexander Dittner on 27.01.2020.
//  Copyright © 2020 Alexander Dittner. All rights reserved.
//

import SwiftUI

class ListController: ObservableObject {
    @Published var lines: [ColumnLine] = []
    @Published var list: ListFileBody

    @Published var curDragOffset: CGFloat = 0
    @Published var curDragLine: ColumnLine? = nil
    private let minRatio: CGFloat = 0.05

    init(list: ListFileBody) {
        self.list = list

        var total: CGFloat = 0
        for (index, c) in list.columns.enumerated() {
            if index < list.columns.count - 1 {
                total += c.ratio
                let line = ColumnLine(position: total, leftColumn: list.columns[index], rightColumn: list.columns[index + 1])
                lines.append(line)
            }
        }
    }

    func dragDidEnd(with relativeOffset: CGFloat) {
        if let curDragLine = curDragLine {
            var offset: CGFloat = 0
            if curDragLine.leftColumn.ratio + relativeOffset < minRatio {
                offset = minRatio - curDragLine.leftColumn.ratio
            } else if curDragLine.rightColumn.ratio - relativeOffset < minRatio {
                offset = curDragLine.rightColumn.ratio - minRatio
            } else {
                offset = relativeOffset
            }
            curDragLine.position += offset
            curDragLine.leftColumn.ratio += offset
            curDragLine.rightColumn.ratio -= offset
        }
        curDragLine = nil
        curDragOffset = 0
    }

    func isDragEnabled(with relativeOffset: CGFloat) -> Bool {
        if let curDragLine = curDragLine {
            return curDragLine.leftColumn.ratio + relativeOffset > minRatio && curDragLine.rightColumn.ratio - relativeOffset > minRatio
        }
        return false
    }

    func updateListView() {
        curDragLine = nil
    }
}

struct ListLinesView: View {
    @ObservedObject private var lc: ListController

    init(_ lc: ListController) {
        self.lc = lc
    }

    var body: some View {
        GeometryReader { geometry in
            ForEach(lc.lines, id: \.id) { line in
                ColumnLineView()
                    .offset(x: line.uid == self.lc.curDragLine?.uid ? line.position * geometry.size.width + self.lc.curDragOffset : line.position * geometry.size.width)
                    .gesture(DragGesture()
                        .onChanged { gesture in
                            if line.uid != self.lc.curDragLine?.uid {
                                self.lc.curDragLine = line
                            }

                            if self.lc.isDragEnabled(with: gesture.translation.width / geometry.size.width) {
                                self.lc.curDragOffset = gesture.translation.width
                            }
                        }
                        .onEnded { _ in
                            self.lc.dragDidEnd(with: self.lc.curDragOffset / geometry.size.width)
                        }
                    )
            }
        }
    }
}

class ColumnLine: ObservableObject, Identifiable {
    let uid = UID()
    @Published var position: CGFloat
    @Published var leftColumn: ListColumn
    @Published var rightColumn: ListColumn

    init(position: CGFloat, leftColumn: ListColumn, rightColumn: ListColumn) {
        self.position = position
        self.leftColumn = leftColumn
        self.rightColumn = rightColumn
    }
}

struct ColumnLineView: View {
    var body: some View {
        ZStack {
            Color.white.opacity(0.1)
                .frame(width: 1)
                .frame(maxHeight: .infinity)

            Colors.clear.color
                .frame(width: 10)
                .frame(maxHeight: .infinity)
                .onHover { inside in
                    if inside {
                        NSCursor.resizeLeftRight.set()
                    } else {
                        NSCursor.arrow.set()
                    }
                }
        }
        .frame(width: 1)
        .zIndex(1)
    }
}
