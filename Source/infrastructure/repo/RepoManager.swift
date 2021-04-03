//
//  RepoManager.swift
//  BrainCache
//
//  Created by Alexander Dittner on 03.04.2021.
//

import Foundation
class RepoManager {
    let dispatcher: DomainEventDispatcher
    let actualVersion: UInt

    init(actualVersion: UInt, dispatcher: DomainEventDispatcher) {
        self.dispatcher = dispatcher
        self.actualVersion = actualVersion
    }

    func getActualFolderRepo() -> JSONRepository<Folder> {
        // last available version == 2
        let folderSerializer = FolderSerializer_v2(dispatcher: dispatcher)
        return JSONRepository<Folder>(repoID: .folder, dispatcher: dispatcher, storeTo: FileSystemAPI.shared.getFoldersUrl(ver: actualVersion), serialize: folderSerializer.serialize, deserialize: folderSerializer.deserialize)
    }

    func getActualFileRepo() -> JSONRepository<File> {
        // last available version == 2
        let fileSerializer = FileSerializer_v1(dispatcher: dispatcher)
        return JSONRepository<File>(repoID: .file, dispatcher: dispatcher, storeTo: FileSystemAPI.shared.getFilesUrl(ver: actualVersion), serialize: fileSerializer.serialize, deserialize: fileSerializer.deserialize)
    }

    func migrateIfNecessary() {
        let fileSystemRepoVersion = getFileSystemRepoVersion(actualVersion)

        if fileSystemRepoVersion > actualVersion {
            logErr(msg: "RepoManager: fileSystemRepoVersion (\(fileSystemRepoVersion)) > actualVersion (\(actualVersion))!")
        } else if fileSystemRepoVersion < actualVersion {
            logInfo(msg: "RepoManager. migrating... from v\(fileSystemRepoVersion) to v\(actualVersion)")
            migrate(from: fileSystemRepoVersion, to: actualVersion)
        }
    }

    private func getFileSystemRepoVersion(_ actualVersion: UInt) -> UInt {
        var res: UInt = 0
        do {
            let urls = try FileSystemAPI.shared.getProjectContentURLs()
            for url: URL in urls {
                let attributes: URLResourceValues = try url.resourceValues(forKeys: [.isDirectoryKey, .nameKey])
                if attributes.isDirectory ?? false, let dirName = attributes.name {
                    let matches = dirName.firstMatch(regex: "v([0-9]+)")
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
                let success = m.migrate()
                if !success { break }
            } else {
                fatalError("RepoManager: migrator from version \(migratingVer) to version \(migratingVer + 1) is not found!")
            }
            migratingVer += 1
        }
    }
}

protocol Migrator {
    func migrate() -> Bool
}

class MigratorFromV1ToV2: Migrator {
    func migrate() -> Bool {
        let dispatcher = DomainEventDispatcher()
        let oldVer: UInt = 1
        let newVer: UInt = 2

        let folderSerializerV1 = FolderSerializer_v1(dispatcher: dispatcher)
        let foldersRepoV1 = JSONRepository<Folder>(repoID: .folder, dispatcher: dispatcher, storeTo: FileSystemAPI.shared.getFoldersUrl(ver: oldVer), mode: .sync, serialize: folderSerializerV1.serialize, deserialize: folderSerializerV1.deserialize)

        let folderSerializerV2 = FolderSerializer_v2(dispatcher: dispatcher)
        let foldersRepoV2 = JSONRepository<Folder>(repoID: .folder, dispatcher: dispatcher, storeTo: FileSystemAPI.shared.getFoldersUrl(ver: newVer), mode: .sync, serialize: folderSerializerV2.serialize, deserialize: folderSerializerV2.deserialize)

        do {
            let oldProjectDir = FileSystemAPI.shared.projectURL.appendingPathComponent("v\(oldVer)")
            let oldFilesDir = FileSystemAPI.shared.getFilesUrl(ver: oldVer)
            let newFilesDir = FileSystemAPI.shared.getFilesUrl(ver: newVer)
            try FileSystemAPI.shared.copyContent(fromDir: oldFilesDir, toDir: newFilesDir)

            let oldFolders = foldersRepoV1.subject.value
            for f in oldFolders {
                foldersRepoV2.write(f)
            }

            do {
                try FileSystemAPI.shared.deleteFileToTrash(from: oldProjectDir)
            } catch {
                logErr(msg: "MigratorFromV1ToV2 had a problem: unable to move folder v\(oldVer) to trach, details: \(error.localizedDescription)")
            }
        } catch {
            logErr(msg: "MigratorFromV1ToV2 is failed, unable to copy files, details: \(error.localizedDescription)")
            return false
        }
        return true
    }
}

class MigratorFromV2ToV3: Migrator {
    func migrate() -> Bool {
        fatalError("RepoManager: MigratorFromV2ToV3 is not ready!")
    }
}

class MigratorFromV3ToV4: Migrator {
    func migrate() -> Bool {
        fatalError("RepoManager: MigratorFromV3ToV4 is not ready!")
    }
}
