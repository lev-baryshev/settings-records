//
//  SettingsStorageTests.swift
//  SettingsRecords
//
//  Created by sugarbaron on 26.02.2026.
//

@testable
import SettingsRecords
import XCTest
import GRDB
import CoreToolkit
import StorageSolutions



// MARK: tests
final class SettingsStorageTests : XCTestCase {
    
    func testRegularUsage() async {
        await test {
            settings.isOn = true
            XCTAssertEqual(settings.isOn, true)
            
            settings.api = URL(string: "https://swift.org")
            XCTAssertEqual(settings.api, URL(string: "https://swift.org"))
        }
    }
    
    func testInitialState() async {
        await test {
            XCTAssertEqual(settings.isOn,       SettingsExample.empty.isOn)
            XCTAssertEqual(settings.api,        SettingsExample.empty.api)
            XCTAssertEqual(settings.armedAt,    SettingsExample.empty.armedAt)
        }
    }
    
    func testUpdate() async {
        await test {
            settings.update(\.isOn, with: true)
            XCTAssertEqual(settings.isOn, true)
            
            settings.update(\.api, with: URL(string: "https://example.com"))
            XCTAssertEqual(settings.api, URL(string: "https://example.com"))
        }
    }
    
    func testErase() async {
        await test {
            let nonEmpty: SettingsExample = .init(isOn: true,
                                                  api: URL(string: "https://foo.bar"),
                                                  armedAt: Date(since1970: 999))
            settings.save(nonEmpty)
            settings.erase()
            XCTAssertEqual(settings.isOn,       SettingsExample.empty.isOn)
            XCTAssertEqual(settings.api,        SettingsExample.empty.api)
            XCTAssertEqual(settings.armedAt,    SettingsExample.empty.armedAt)
        }
    }
    
    func testRead() async {
        await test {
            let custom: SettingsExample = .init(isOn: true,
                                                api: URL(string: "https://zombo.com"),
                                                armedAt: Date(since1970: 42))
            settings.save(custom)
            XCTAssertEqual(settings.read(\.isOn), true)
            XCTAssertEqual(settings.read(\.api), URL(string: "https://zombo.com"))
            XCTAssertEqual(settings.read(\.armedAt), Date(since1970: 42))
        }
    }
    
}

// MARK: tools
private extension SettingsStorageTests {
    
    func test(_ test: () -> Void) async {
        await setup()
        test()
        reset()
    }
    
    func setup() async {
        guard settings == nil else { return }
        let file: String = "settings"
        let path: FileSystem.Path = "Storages".path
        let fileSystem: FileSystem.Service = FileSystem.ServiceEngine(root: "UnitTests")!
        try! fileSystem.createFolder(at: path)
        let folder: URL = fileSystem.dynamicRoot/path
        Self.instance = await Settings(name: file, at: folder, [Settings.V01()])
    }
    
    func reset() {
        settings.erase()
    }
    
    var settings: Settings! { Self.instance }
    
    static var instance: Settings? = nil
    
}

// MARK: record example
private struct SettingsExample {
    
    var isOn: Bool
    var api: URL?
    var armedAt: Date
    
    init(
        isOn: Bool,
        api: URL? = nil,
        armedAt: Date
    ) {
        self.isOn = isOn
        self.api = api
        self.armedAt = armedAt
    }
    
}

extension SettingsExample : SettingsRecord {
    
    static let tableName: String = "settings"
    
    static let empty: SettingsExample = .init(isOn: false,
                                              api: nil,
                                              armedAt: Date(since1970: 0))
    
    func save(into row: inout PersistenceContainer) throws {
        row[Columns.isOn] = isOn
        row[Columns.api] = api?.absoluteString
        row[Columns.armedAt] = armedAt
    }
    
    static func load(from row: Row) throws -> SettingsExample {
        let isOn: Bool?             = row[Columns.isOn]
        let api: String?            = row[Columns.api]
        let armedAt: TimeInterval?  = row[Columns.armedAt]
        return SettingsExample(isOn:    isOn                                    ?? Self.empty.isOn,
                               api:     unwrap(api)     { URL($0) }             ?? Self.empty.api,
                               armedAt: unwrap(armedAt) { Date(since1970: $0) } ?? Self.empty.armedAt)
    }
    
}

// MARK: storage example
private typealias Settings = SettingsStorage<SettingsExample>

private extension Settings {
    
    final class V01 : GrdbSchemaVersion {
        
        let id: String = "v01"
        
        let upgrade: (Database) throws -> Void = { database in
            try database.create(table: SettingsExample.tableName) { table in
                let nilBoolean: Bool?   = nil
                let nilString: String?  = nil
                let nilDouble: Double?  = nil
                
                table.column(Columns.isOn,      .boolean).defaults(to: nilBoolean)
                table.column(Columns.api,       .text).defaults(to: nilString)
                table.column(Columns.armedAt,   .timeInterval).defaults(to: nilDouble)
            }
        }
        
    }
    
}

private final class Columns {
    static let isOn:    String = "isOn"
    static let api:     String = "api"
    static let armedAt: String = "armedAt"
}
