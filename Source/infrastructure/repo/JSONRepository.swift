//
//  JSONBookRepository.swift
//  BrainCache
//
//  Created by Alexander Dittner on 11.02.2021.
//

import Combine
import Foundation

enum JSONRepoError: DetailedError {
    case createStorageDirFailed(repoID: String, details: String)
    case writeEntityOnDiskFailed(repoID: String, details: String)
    case readEntityFromDiskFailed(repoID: String, details: String)
    case removeEntityFromDiskFailed(repoID: String, details: String)
}

enum RepoID: String {
    case folder = "Folder Repo"
    case file = "File Repo"
}

class LoadDirectoryContentService {
    func load(url: URL, fileExtension: String) -> [Data] {
        var res: [Data] = []
        do {
            let urls = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil).filter { $0.pathExtension == fileExtension }

            for fileURL in urls {
                do {
                    let data = try Data(contentsOf: fileURL)
                    res.append(data)

                } catch {
                    logErr(msg: "LoadDirectoryContentService.load, failed to read data, url = \(fileURL), details: \(error.localizedDescription)")
                }
            }
        } catch {
            logErr(msg: "LoadDirectoryContentService.load, failed to read file urls from disk, details: \(error.localizedDescription)")
        }

        return res
    }
}

class JSONRepository<E: DomainEntity>: IRepository {
    typealias Entity = E
    
    let subject = CurrentValueSubject<[Entity], Never>([])

    private let repoID: RepoID
    private let url: URL
    private let fileExtension: String
    private let dispatcher: DomainEventDispatcher
    
    private var hash: [UID: Entity] = [:]
    private var serialize: ((Entity) throws -> Data)?

    init(repoID: RepoID, url: URL, fileExtension:String, dispatcher: DomainEventDispatcher) {
        logInfo(msg: "JSONRepo <\(repoID)> init")
        self.repoID = repoID
        self.url = url
        self.fileExtension = fileExtension
        self.dispatcher = dispatcher
        
        createDirectoriesIfNeeded()
    }

    private func createDirectoriesIfNeeded() {
        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.createDirectory(atPath: url.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                logErr(msg: JSONRepoError.createStorageDirFailed(repoID: repoID.rawValue, details: error.localizedDescription).localizedDescription)
            }
        }
    }

    func loadFromDisk() -> [Data] {
        let loadService = LoadDirectoryContentService()
        return loadService.load(url: url, fileExtension: self.fileExtension)
    }

    func deserialize<S: ISerializer>(data: [Data], serializer: S) -> [Entity] where S.Entity == Entity {
        serialize = serializer.serialize
        var entities: [Entity] = []
        for d in data {
            do {
                let entity = try serializer.deserialize(data: d)
                hash[entity.uid] = entity
                entities.append(entity)

            } catch {
                logErr(msg: "Repo = \(repoID.rawValue), failed to deserialize entity, details: \(error.localizedDescription)")
            }
        }

        if entities.count > 0 {
            DispatchQueue.main.async {
                self.subject.send(entities)
            }
        }

        return entities
    }

    private var disposeBag: Set<AnyCancellable> = []
    func listenToEntitiesChanged() {
        dispatcher.subject
            .sink { event in
                switch event {
                case let .entityStateChanged(entity):
                    self.pendingEntitiesToStore.append(entity.uid)
                    self.storeChangesAsync()
                }
            }
            .store(in: &disposeBag)
    }

    func getEntityStoreURL(_ e: Entity) -> URL {
        return url.appendingPathComponent(e.uid.description + "." + fileExtension)
    }

    private func destroyEntity(_ e: Entity) throws {
        try destroyEntity(storeURL: getEntityStoreURL(e))
    }

    private func destroyEntity(storeURL: URL) throws {
        if FileManager.default.fileExists(atPath: storeURL.path) {
            do {
                try FileManager.default.trashItem(at: storeURL, resultingItemURL: nil)
            } catch {
                throw JSONRepoError.removeEntityFromDiskFailed(repoID: repoID.rawValue, details: error.localizedDescription)
            }
        }
    }

    func has(_ uid: UID) -> Bool {
        return hash[uid] != nil
    }

    func read(_ uid: UID) -> Entity? {
        return hash[uid]
    }

    func remove(_ uid: UID) {
        guard let entity = read(uid) else { return }
        do {
            try destroyEntity(entity)
            hash[entity.uid] = nil
            var entities = subject.value
            if let index = entities.firstIndex(of: entity) {
                entities.remove(at: index)
            }

            logInfo(msg: "Repo = \(repoID.rawValue): Entity uid = \(uid) is successful deleted")

            subject.send(entities)

        } catch {
            logErr(msg: "Repo = \(repoID.rawValue): Failed to destroy an entity uid = \(uid), details:  \(error.localizedDescription)")
        }
    }

    func write(_ entity: Entity) {
        if !has(entity.uid) {
            hash[entity.uid] = entity
            subject.send(subject.value + [entity])
        }

        pendingEntitiesToStore.append(entity.uid)
        storeChangesAsync()
    }

    private var pendingEntitiesToStore: [UID] = []
    private var isStorePending: Bool = false
    func storeChangesAsync() {
        guard !isStorePending else { return }

        isStorePending = true
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchTimeInterval.milliseconds(3000)) {
            for entityID in self.pendingEntitiesToStore.removeDuplicates() {
                if let entity = self.read(entityID) {
                    self.store(entity)
                }
            }
            self.pendingEntitiesToStore = []
            self.isStorePending = false
        }
    }

    private func store(_ e: Entity) {
        DispatchQueue.global(qos: .utility).sync {
            do {
                let fileUrl = getEntityStoreURL(e)
                let data = try serialize?(e)
                do {
                    try data?.write(to: fileUrl)
                    print("Repo = \(repoID.rawValue): Entity(\(e.uid)) is written on the disk")
                } catch {
                    logErr(msg: "Repo = \(repoID.rawValue): Failed to write entity with id = \(e.id) on the disk, details:  \(error.localizedDescription)")
                }
            } catch {
                logErr(msg: "Repo = \(repoID.rawValue): Failed to serialize entity id = \(e.id), details:  \(error.localizedDescription)")
            }
        }
    }
}
