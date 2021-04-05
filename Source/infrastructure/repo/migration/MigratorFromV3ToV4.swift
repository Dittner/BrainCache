//
//  RepoManager.swift
//  BrainCache
//
//  Created by Alexander Dittner on 03.04.2021.
//

import Foundation

class MigratorFromV3ToV4: Migrator {
    func migrate() throws {
        throw MigrationError.invalidVersion(fromVersion: 3, toVersion: 4, details: "MigratorFromV3ToV4 is not ready!")
    }
}
