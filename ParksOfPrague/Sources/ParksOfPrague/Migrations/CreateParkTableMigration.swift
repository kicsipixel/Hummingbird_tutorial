//
//  CreateParkTableMigration.swift
//
//
//  Created by Szabolcs Tóth on 06.04.2024.
//  Copyright © 2024 Szabolcs Tóth. All rights reserved.
//

import FluentKit

struct CreateParkTableMigration: AsyncMigration {
    func prepare(on database: Database) async throws {
        return try await database.schema("parks")
            .id()
            .field("name", .string, .required)
            .field("coordinates_latitude", .double, .required)
            .field("coordinates_longitude", .double, .required)
            .unique(on: "name")
            .create()
    }

    func revert(on database: Database) async throws {
        return try await database.schema("parks").delete()
    }
}
