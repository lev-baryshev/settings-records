# settings-records
easy-to-use, type-safe, high-performance, persistent settings storage for Swift with RAM speed and variable-like r/w access interface

### you can use your any custom parameters set to store:

```swift
// custom parameters set
sturct Parameters {

    var isDetailed: Bool
    var apiUrl: URL?
    var armedAt: Date?

}
```
### easy usage with RAM-speed access:

```swift
typealias Settings = SettingsStorage<Parameters>

let settings: Settings = ...       // see initialisation below

let detailed = settings.isDetailed // read from persistent storage
settings.armedAt = .now            // write into persistent storage

// and that's it! extremely simple and excellent!
```
### constructing storage instance:

```swift
// name of your settings storage
let storageName: String = "Settings"

// url of folder, where your storage file is located
// (or where you want it to be created, in case of first run)
let folder: URL = FileManager.default.documentFolder

// (see step 3 of adjustments below). you can add 
// new versions of database schema if you need to modify
// storage structure or make some migrations of data
let migration: [GrdbSchemaVersion] = [V01] 
let instance = Settings(name: storageName, at: folder, migration)

// important!
// you can have a number of such storages, for example
// BrandingSettings, NetworkSettings and so on, but every
// instance should be a singleton. it is recommended to
// store this singletones inside of some dependency injection
// system.
final class ViewModel : ObservableObject {
   
   private let settings: Settings?
   
   init() {
       self.settings = Di.inject(Settings?.self)
   }
   
}
```

### a few steps of adjustments before usage:

```swift
// 1. specify database column names for every parameter
final class Columns {

    static let isDetailed: = "isDetailed"
    static let apiUrl:     = "apiUrl"
    static let armedAt     = "armedAt"
    
}

// 2. specify parameters mapping into columns of table row
extension Parameters : SettingsRecord {

    static let tableName = "settings"
    
    static let empty = Parameters(isDetailed: false, apiUrl: nil, armedAt: nil)
    
    func save(into row: inout PersistenceContainer) throws {
        row[Columns.isDetailed] = isDetailed
        row[Columns.apiUrl] = apiUrl?.absoluteString
        row[Columns.armedAt] = armedAt?.timeIntervalSince1970
    }
    
    static func load(from row: Row) throws -> Parameters {
        let isDetailed: Bool?      = row[Columms.isDetailed]
        let apiUrl: String?        = row[Columns.apiUrl]
        let armedAt: TimeInterval? = row[Columns.armedAt]
        return Parameters(
            isDetailed: isDetailed                              ?? Parameters.empty.isDetailed,
            apiUrl:     unwrap(apiUrl)  { URL($0) }             ?? Parameters.empty.apiUrl,
            armedAt:    unwrap(armedAt) { Date(since1970: $0) } ?? Parameters.empty.armedAt
        )
    }

}

// 3. describe database table parameters
final class V01 : GrdbSchemaVersion {
        
    let id: String = "v01"
        
    let upgrade: (Database) throws -> Void = { database in
        try database.create(table: SettingsExample.tableName) { table in
            let nilBoolean: Bool?   = nil
            let nilString: String?  = nil
            let nilDouble: Double?  = nil
                
            table.column(Columns.isDetailed, .boolean).defaults(to: nilBoolean)
            table.column(Columns.apiUrl,     .text).defaults(to: nilString)
            table.column(Columns.armedAt,    .timeInterval).defaults(to: nilDouble)
        }
    }

}
```
