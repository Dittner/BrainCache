//
//  RepoManager.swift
//  BrainCache
//
//  Created by Alexander Dittner on 03.04.2021.
//

import Foundation

enum MigrationError: DetailedError {
    case copyFilesFailed(fromVersion: UInt, toVersion: UInt, details: String)
    case moveDirToTrashFailed(fromVersion: UInt, toVersion: UInt, details: String)
    case invalidVersion(fromVersion: UInt, toVersion: UInt, details: String)
}

protocol Migrator {
    func migrate() throws
}

class Migration {
    let dispatcher: DomainEventDispatcher
    let modelVersion: UInt

    init(modelVersion: UInt, dispatcher: DomainEventDispatcher) {
        self.modelVersion = modelVersion
        self.dispatcher = dispatcher
    }

    func migrateIfNecessary() {
        let fileSystemRepoVersion = getFileSystemRepoVersion(modelVersion)

        if fileSystemRepoVersion > modelVersion {
            logErr(msg: "RepoManager: fileSystemRepoVersion (\(fileSystemRepoVersion)) > actualVersion (\(modelVersion))!")
        } else if fileSystemRepoVersion < modelVersion {
            logInfo(msg: "RepoManager. migrating... from v\(fileSystemRepoVersion) to v\(modelVersion)")
            migrate(from: fileSystemRepoVersion, to: modelVersion)
        }
    }

    private func getFileSystemRepoVersion(_ actualVersion: UInt) -> UInt {
        var res: UInt = 0
        do {
            let urls = try FileSystemAPI.shared.getProjectContentURLs()
            for url: URL in urls {
                let attributes: URLResourceValues = try url.resourceValues(forKeys: [.isDirectoryKey, .nameKey])
                if attributes.isDirectory ?? false, let dirName = attributes.name {
                    let matches = dirName.firstMatch(regex: "^v([0-9]+)")
                    if matches.count > 1, let verNum = UInt(matches[1]) {
                        res = verNum > res ? verNum : res
                    }
                }
            }
        } catch {
            logErr(msg: "RepoManager.getFileSystemRepoVersion: Failed to read file urls in project dir, details: \(error.localizedDescription)")
        }

        return res == 0 ? actualVersion : res
    }

    private func migrate(from oldVer: UInt, to actualVer: UInt) {
        var migrators: [UInt: Migrator] = [:]
        migrators[1] = MigratorFromV1ToV2()
        migrators[2] = MigratorFromV2ToV3()
        migrators[3] = MigratorFromV3ToV4()

        var migratingVer = oldVer
        while migratingVer < actualVer {
            if let m = migrators[migratingVer] {
                do {
                    try m.migrate()
                } catch {
                    fatalError("Migration is failed, details: \(error.localizedDescription)")
                    break
                }
            } else {
                fatalError("Migration has not available migrator of version \(migratingVer)")
            }
            migratingVer += 1
        }
    }
}
