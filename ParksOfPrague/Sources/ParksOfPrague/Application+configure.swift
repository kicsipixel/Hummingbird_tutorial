//
//  Application+configure.swift
//
//
//  Created by Szabolcs Tóth on 06.04.2024.
//  Copyright © 2024 Szabolcs Tóth. All rights reserved.
//

import FluentSQLiteDriver
import Hummingbird
import HummingbirdFluent

func buildApplication(configuration: ApplicationConfiguration) async throws -> some ApplicationProtocol {
    // Router
    let router = Router()
    
    router.get("/") { _, _ in
        return  "The server is running...🚀"
    }
        
    // Database
    let logger = Logger(label: "Parks of Prague")
    let fluent = Fluent(logger: logger)
 
    // SQLite database file name
    fluent.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)

    // Database migration
    await fluent.migrations.add(CreateParkTableMigration())
 
    try await fluent.migrate()
    
    // Add controller
    ParksController(fluent: fluent).addRoutes(to: router.group("api/v1/parks"))
    
    // Application
    var app = Application(
        router: router,
        configuration: configuration
    )
        
    app.addServices(fluent)
    return app
}
