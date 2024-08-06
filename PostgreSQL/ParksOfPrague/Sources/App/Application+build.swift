import FluentPostgresDriver
import Hummingbird
import HummingbirdFluent
import Logging

/// Application arguments protocol. We use a protocol so we can call
/// `buildApplication` inside Tests as well as in the App executable.
/// Any variables added here also have to be added to `App` in App.swift and
/// `TestArguments` in AppTest.swift
public protocol AppArguments {
    var hostname: String { get }
    var port: Int { get }
    var logLevel: Logger.Level? { get }
}

public func buildApplication(_ arguments: some AppArguments) async throws -> some ApplicationProtocol {
    let logger = {
        var logger = Logger(label: "ParksOfPrague")
        logger.logLevel = arguments.logLevel ?? .info
        return logger
    }()
    
    let router = Router()
    
    // Add health route
    router.get("/health") { _,_ -> HTTPResponse.Status in
        return .ok
    }
    
    // Add / route
    router.get("/") { _,_ in
        return "Hello, World! 🌍"
    }
    
    let fluent = Fluent(logger: logger)
    let env = try await Environment.dotEnv()
    
    // Configure database
    let postgreSQLConfig = SQLPostgresConfiguration(hostname: env.get("DATABASE_HOST") ?? "localhost",
                                                    port: env.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? SQLPostgresConfiguration.ianaPortNumber,
                                                    username: env.get("DATABASE_USERNAME") ?? "username",
                                                    password: env.get("DATABASE_PASSWORD") ?? "password",
                                                    database: env.get("DATABASE_NAME") ?? "db",
                                                    tls: .prefer(try .init(configuration: .clientDefault)))
    
    fluent.databases.use(.postgres(configuration: postgreSQLConfig, sqlLogLevel: .warning), as: .psql)
    
    await fluent.migrations.add(CreateParkTableMigration())
    
    // Migration
    try await fluent.migrate()
    
    // Add controller
    ParksController(fluent: fluent).addRoutes(to: router.group("api/v1/parks"))
    
    var app = Application(
        router: router,
        configuration: .init(
            address: .hostname(arguments.hostname, port: arguments.port),
            serverName: "ParksOfPrague"
        ),
        logger: logger
    )
    
    app.addServices(fluent)
    return app
}
