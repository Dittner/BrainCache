//
//  JSONBookRepository.swift
//  MP3Book
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
    case table = "Table Repo"
}

class JSONRepository<E: DomainEntity>: IRepository {
    typealias Entity = E

    let fileExtension = "bcfile"
    let subject = CurrentValueSubject<[Entity], Never>([])

    private let repoID: RepoID
    private let url: URL
    private var hash: [UID: Entity] = [:]
    private let serialize: (Entity) throws -> Data
    private let deserialize: (Data) throws -> Entity
    private let dispatcher: DomainEventDispatcher
    private(set) var isReady: Bool = false

    init(repoID: RepoID, dispatcher: DomainEventDispatcher, storeTo: URL, serialize: @escaping (E) throws -> Data, deserialize: @escaping (Data) throws -> E) {
        logInfo(msg: "JSONRepo <\(repoID)> init")
        self.repoID = repoID

        self.serialize = serialize
        self.deserialize = deserialize

        self.dispatcher = dispatcher
        url = storeTo

        createStorageIfNeeded()
        readFoldersFromDisk()
        subscribeToDispatcher()
    }

    private func createStorageIfNeeded() {
        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.createDirectory(atPath: url.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                logErr(msg: JSONRepoError.createStorageDirFailed(repoID: repoID.rawValue, details: error.localizedDescription).localizedDescription)
            }
        }
    }

    private func readFoldersFromDisk() {
        DispatchQueue.global(qos: .background).async {
            var entities = [Entity]()
            do {
                let urls = try FileManager.default.contentsOfDirectory(at: self.url, includingPropertiesForKeys: nil).filter { $0.pathExtension == self.fileExtension }
                logInfo(msg: "Repo = \(self.repoID.rawValue), entities count on the disk: \(urls.count)")

                for fileURL in urls {
                    do {
                        let data = try Data(contentsOf: fileURL)
                        let entity = try self.deserialize(data)
                        self.hash[entity.uid] = entity
                        entities.append(entity)

                    } catch {
                        logErr(msg: "Repo = \(self.repoID.rawValue), failed to deserialize entity, url = \(fileURL), details: \(error.localizedDescription)")
                    }
                }
            } catch {
                logErr(msg: "Repo = \(self.repoID.rawValue), failed to read entities urls from disk, details: \(error.localizedDescription)")
            }

            DispatchQueue.main.async {
                if entities.count > 0 {
                    self.subject.send(entities)
                }
                self.isReady = true
                self.dispatcher.subject.send(.repoIsReady(repoID: self.repoID))
            }
        }
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

    private var disposeBag: Set<AnyCancellable> = []
    private func subscribeToDispatcher() {
        dispatcher.subject
            .sink { event in
                switch event {
                case let .entityStateChanged(entity):
                    if self.has(entity.uid) {
                        self.pendingEntitiesToStore.append(entity.uid)
                        self.storeChanges()
                    }
                default:
                    break
                }
            }
            .store(in: &disposeBag)
    }

    func getEntityStoreURL(_ e: Entity) -> URL {
        return url.appendingPathComponent(e.uid.description + "." + fileExtension)
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
        storeChanges()
    }

    private var pendingEntitiesToStore: [UID] = []
    func storeChanges() {
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchTimeInterval.milliseconds(3000)) {
            for entityID in self.pendingEntitiesToStore.removeDuplicates() {
                if let entity = self.read(entityID) {
                    self.store(entity)
                }
            }
            self.pendingEntitiesToStore = []
            self.dispatcher.subject.send(.repoStoreComplete(repoID: self.repoID))
        }
    }

    private func store(_ e: Entity) {
        DispatchQueue.global(qos: .utility).sync {
            do {
                let fileUrl = self.getEntityStoreURL(e)
                let data = try self.serialize(e)
                do {
                    try data.write(to: fileUrl)
                } catch {
                    logErr(msg: "Repo = \(repoID.rawValue): Failed to write entity with id = \(e.id) on the disk, details:  \(error.localizedDescription)")
                }
            } catch {
                logErr(msg: "Repo = \(repoID.rawValue): Failed to serialize entity id = \(e.id), details:  \(error.localizedDescription)")
            }
        }
    }
}
