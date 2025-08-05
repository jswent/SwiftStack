//
//  SavedItemSchemas.swift
//  Features
//
//  Created by James Swent on 8/5/25.
//

import Foundation
import SwiftData

// MARK: - V1 Schema (Current State - No Type Field)

public enum SavedItemSchemaV1: VersionedSchema {
    public static var versionIdentifier = Schema.Version(1, 0, 0)
    
    public static var models: [any PersistentModel.Type] {
        [SavedItem.self, Photo.self]
    }
}

// MARK: - Migration Plan (V1 Only For Now)

public enum SavedItemMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        [SavedItemSchemaV1.self]
    }
    
    public static var stages: [MigrationStage] {
        []
    }
}