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
    case table = "Table Repo"
}

enum RepoMode: String {
    case sync
    case async
}

class JSONRepository<E: DomainEntity>: IRepository {
    typealias Entity = E

    let fileExtension = "bc"
    let subject = CurrentValueSubject<[Entity], Never>([])

    private let repoID: RepoID
    private let mode: RepoMode
    private let url: URL
    private var hash: [UID: Entity] = [:]
    private let serialize: (Entity) throws -> Data
    private let deserialize: (Data) throws -> Entity
    private let dispatcher: DomainEventDispatcher
    private(set) var isReady: Bool = false

    init(repoID: RepoID, dispatcher: DomainEventDispatcher, storeTo: URL, mode: RepoMode = .async, serialize: @escaping (E) throws -> Data, deserialize: @escaping (Data) throws -> E) {
        logInfo(msg: "JSONRepo <\(repoID)> init")
        self.repoID = repoID
        self.mode = mode

        self.serialize = serialize
        self.deserialize = deserialize

        self.dispatcher = dispatcher
        url = storeTo

        createStorageIfNeeded()
        readEntitiesFromDisk(mode)
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

    private func readEntitiesFromDisk(_ mode: RepoMode) {
        if mode == .async {
            DispatchQueue.global(qos: .background).async {
                let entities = self.readFilesAndDeserializeToEntities()

                DispatchQueue.main.async {
                    if entities.count > 0 {
                        self.subject.send(entities)
                    }
                    self.isReady = true
                    self.dispatcher.subject.send(.repoIsReady(repoID: self.repoID))
                }
            }
        } else {
            let entities = readFilesAndDeserializeToEntities()

            if entities.count > 0 {
                subject.send(entities)
            }
            isReady = true
            dispatcher.subject.send(.repoIsReady(repoID: repoID))
        }
    }

    private func readFilesAndDeserializeToEntities() -> [Entity] {
        var res = [Entity]()
        do {
            let urls = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil).filter { $0.pathExtension == self.fileExtension }
            logInfo(msg: "Repo = \(repoID.rawValue), entities count on the disk: \(urls.count)")

            for fileURL in urls {
                do {
                    let data = try Data(contentsOf: fileURL)
                    let entity = try deserialize(data)
                    hash[entity.uid] = entity
                    res.append(entity)

                } catch {
                    logErr(msg: "Repo = \(repoID.rawValue), failed to deserialize entity, url = \(fileURL), details: \(error.localizedDescription)")
                }
            }
        } catch {
            logErr(msg: "Repo = \(repoID.rawValue), failed to read entities urls from disk, details: \(error.localizedDescription)")
        }

        return res
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
                    if let e = self.read(entity.uid) {
                        if self.mode == .async {
                            self.pendingEntitiesToStore.append(entity.uid)
                            self.storeChangesAsync()
                        } else {
                            self.storeImmediately(e)
                        }
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

        if mode == .async {
            pendingEntitiesToStore.append(entity.uid)
            storeChangesAsync()
        } else {
            storeImmediately(entity)
        }
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
            self.dispatcher.subject.send(.repoStoreComplete(repoID: self.repoID))
        }
    }

    private func store(_ e: Entity) {
        DispatchQueue.global(qos: .utility).sync {
            self.storeImmediately(e)
        }
    }

    private func storeImmediately(_ e: Entity) {
        do {
            let fileUrl = getEntityStoreURL(e)
            let data = try serialize(e)
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
