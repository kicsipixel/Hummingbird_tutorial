//
//  App.swift
//
//
//  Created by Szabolcs Tóth on 06.04.2024.
//  Copyright © 2024 Szabolcs Tóth. All rights reserved.
//

import ArgumentParser

@main
struct HummingbirdArguments: AsyncParsableCommand {
    @Option(name: .shortAndLong)
    var hostname: String = "127.0.0.1"

    @Option(name: .shortAndLong)
    var port: Int = 8080

    func run() async throws {
        let app = try await buildApplication(
            configuration: .init(
                address: .hostname(self.hostname, port: self.port),
                serverName: "Parks of Prague"
            )
        )
        
        try await app.runService()
    }
}
