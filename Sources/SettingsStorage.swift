//
//  SettingsStorage.swift
//  SettingsRecords
//
//  Created by sugarbaron on 08.11.2022.
//

import Foundation
import Combine
import GRDB
import StorageSolutions
import CoreToolkit

// MARK: constructor
@dynamicMemberLookup
public final class SettingsStorage<Record:SettingsRecord> {
    
    private let database: GrdbStorage
    private var cache: Record
    private let cacheAccess: NSRecursiveLock
    
    public init?(name: String, at folder: URL, _ versions: [GrdbSchemaVersion]) async {
        let sqliteFile: URL = folder/name.sqlite
        guard let database: GrdbStorage = .init(sqliteFile, versions, .config(name)) else { return nil }
        
        self.database = database
        self.cache = await database.read { try $0.readRecord() } ?? .empty
        self.cacheAccess = NSRecursiveLock()
    }
    
}

// MARK: interface
public extension SettingsStorage {
    
    subscript<T>(dynamicMember field: KeyPath<Record, T>) -> T {
        readCache(field)
    }

    subscript<T>(dynamicMember field: WritableKeyPath<Record, T>) -> T {
        get { readCache(field) }
        set { update(field: field, with: newValue) }
    }
    
    func save(_ new: Record) {
        updateCache(with: new)
        database.write { try $0.update(single: Record.self, with: new) }
                catch: { log(error: "[SettingsStorage][save] \($0)") }
    }
    
    func update<T>(_ field: WritableKeyPath<Record, T>, with new: T) {
        update(field: field, with: new)
    }
    
    func read<T>(_ field: KeyPath<Record, T>) -> T {
        readCache(field)
    }

    func keepInformed() -> Downstream<Record> {
        database.keepInformed { try $0.readRecord() }
    }

    func erase() {
        updateCache(with: .empty)
        database.write { try $0.update(single: Record.self, with: Record.empty) }
                catch: { log(error: "[SettingsStorage][erase] \($0)") }
    }
    
}

// MARK: tools
private extension SettingsStorage {
    
    func update<T>(field: WritableKeyPath<Record, T>, with new: T) {
        let updated: Record = updateCache(field, with: new)
        database.write { try $0.update(single: Record.self, with: updated) }
                catch: { log(error: "[SettingsStorage][update] \($0)") }
    }

    func updateCache(with updated: Record) {
        cacheAccess.lock()
        cache = updated
        cacheAccess.unlock()
    }
    
    func updateCache<T>(_ field: WritableKeyPath<Record, T>, with new: T) -> Record {
        cacheAccess.lock()
        cache[keyPath: field] = new
        let updated: Record = cache
        cacheAccess.unlock()
        return updated
    }
    
    func readCache<T>(_ certainField: KeyPath<Record, T>) -> T {
        cacheAccess.lock()
        let field: T = cache[keyPath: certainField]
        cacheAccess.unlock()
        return field
    }
    
}

private extension Database {

    func update<R:GrdbRecord>(single: R.Type, with record: R) throws {
        try delete(all: R.self)
        try insert(record)
    }
    
    // just for more expressive name
    func readRecord<Record:SettingsRecord>() throws -> Record {
        try select(all: Record.self).first ?? .empty
    }

}
