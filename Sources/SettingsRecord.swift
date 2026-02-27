//
//  SettingsRecord.swift
//  SettingsRecords
//
//  Created by sugarbaron on 16.10.2022.
//

import StorageSolutions

public protocol SettingsRecord : GrdbRecord {
    
    static var empty: Self { get }
    
}
