//
//  Logger.swift
//  BrainCache
//
//  Created by Alexander Dittner on 13.02.2020.
//  Copyright © 2020 Alexander Dittner. All rights reserved.
//

import Foundation
import SwiftUI

func logInfo(msg: String) {
    Logger.shared?.info(msg: msg)
}

func logWarn(msg: String) {
    Logger.shared?.warn(msg: msg)
}

func logErr(msg: String) {
    Logger.shared?.err(msg: msg)
}

class Logger {
    private(set) static var shared: Logger?

    private let keepLogsInDays: Int = 2
    private var log: String = ""
    private var logFileURL: URL?

    private let timeFormatter: DateFormatter = {
        var formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    static func run() {
        if shared == nil {
            shared = Logger()
        }
    }

    init() {
        if !FileSystemAPI.shared.existDir(.logs) { try? FileSystemAPI.shared.createDir(.logs) }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH-mm-ss"

        let logsFilePath = StorageDirectory.logs.rawValue + "/" + formatter.string(from: Date()) + ".clientLog"
        logFileURL = FileSystemAPI.shared.projectURL.appendingPathComponent(logsFilePath)

        removeExpiredLogs()
    }

    func info(msg: String) {
        let txt = timeFormatter.string(from: Date()) + " [INFO] " + msg
        print(txt)
        write2file(txt)
    }

    func warn(msg: String) {
        let txt = timeFormatter.string(from: Date()) + " [WARN] " + msg
        print(txt)
        write2file(txt)
    }

    func err(msg: String) {
        let txt = timeFormatter.string(from: Date()) + " [ERROR] " + msg
        print(txt)
        write2file(txt)
    }

    func write2file(_ txt: String) {
        log += txt + "\n"
        if let url = logFileURL {
            do {
                try log.write(to: url, atomically: false, encoding: .utf8)
            } catch {
                print("Failed write logs on the disk")
            }
        }
    }

    private func removeExpiredLogs() {
        do {
            let urls = try FileSystemAPI.shared.getURLs(dir: .logs, filesWithExtension: "clientLog")
            let curDateTime = Int(Date().timeIntervalSinceReferenceDate)
            let expireTimeInSecs = curDateTime - keepLogsInDays * 24 * 60 * 60
            var countOfExpiredFiles: Int = 0

            for url: URL in urls {
                do {
                    let attributes: URLResourceValues = try url.resourceValues(forKeys: [.creationDateKey])

                    if let creationDate = attributes.creationDate {
                        if Int(creationDate.timeIntervalSinceReferenceDate) < expireTimeInSecs {
                            do {
                                try FileManager.default.removeItem(at: url)
                                countOfExpiredFiles += 1
                            } catch {
                                err(msg: "Logger.removeExpiredLogs failed: \(error.localizedDescription), with url: \(url.description)")
                            }
                        }
                    }
                } catch {
                    err(msg: "Logger.removeExpiredLogs failed: \(error.localizedDescription)")
                }
            }

            if countOfExpiredFiles > 1 {
                info(msg: "\(countOfExpiredFiles) logfiles were removed")
            } else if countOfExpiredFiles > 0 {
                info(msg: "\(countOfExpiredFiles) logfile was removed")
            }
        } catch {
            err(msg: "Logger.removeExpiredLogs failed: \(error.localizedDescription)")
        }
    }
}
