import FluentKit
import Foundation
import Hummingbird
import HummingbirdFluent

struct ParksController<Context: RequestContext> {
    
    let fluent: Fluent
    
    func addRoutes(to group:RouterGroup<Context>) {
        group
            .get(use: self.index)
            .get(":id", use: self.show)
            .post(use: self.create)
            .put(":id", use: self.update)
            .delete(":id", use: self.delete)
    }
    
    // MARK: - index
    /// Returns with all parks in the database
    @Sendable func index(_ request: Request, context: Context) async throws -> [Park] {
        try await Park.query(on: self.fluent.db()).all()
    }
    
    
    // MARK: - show
    // Return with park with specified id
    @Sendable func show(_ request: Request, context: Context) async throws -> Park? {
        let id = try context.parameters.require("id", as: UUID.self)
        guard let park = try await Park.find(id, on: fluent.db()) else {
            throw HTTPError(.notFound)
        }
        
        return park
    }
    
    // MARK: - create
    /// Saves park to the database
    //
    // curl --location 'http://127.0.0.1:8080/api/v1/parks' \
    // --header 'Content-Type: application/json' \
    // --data '{
    //     "name" : "Stromovka",
    //     "coordinates": {
    //         "latitude" : 50.105848999999999,
    //         "longitude": 14.413999
    //     }
    // }'
    //'
    @Sendable func create(_ request: Request, context: Context) async throws -> Park {
        let park = try await request.decode(as: Park.self, context: context)
        try await park.save(on: fluent.db())
        return park
    }
    
    // MARK: - update
    /// Updates park with specified id
    //
    //    curl --location --request PUT 'http://127.0.0.1:8080/api/v1/parks/079BAE9C-FCFB-4556-BF02-9C274659E022' \
    //    --header 'Content-Type: application/json' \
    //    --data '   {
    //         "name" : "Stromovka Park",
    //         "coordinates": {
    //                "latitude" : 50.105848999999999,
    //                 "longitude": 14.413999
    //           }
    //     }'
    //
    @Sendable func update(_ request: Request, context: Context) async throws -> HTTPResponse.Status {
        let id = try context.parameters.require("id", as: UUID.self)
        guard let park = try await Park.find(id, on: fluent.db()) else {
            throw HTTPError(.notFound)
        }
        
        let updatedPark = try await request.decode(as: Park.self, context: context)
        
        park.name = updatedPark.name
        park.coordinates.latitude = updatedPark.coordinates.latitude
        park.coordinates.longitude = updatedPark.coordinates.longitude
        
        try await park.save(on: fluent.db())
        
        return .ok
    }
    
    // MARK: - delete
    /// Deletes park with specified
    //
    // curl --location --request DELETE 'http://127.0.0.1:8080/api/v1/parks/079BAE9C-FCFB-4556-BF02-9C274659E022'
    //
    @Sendable func delete(_ request: Request, context: Context) async throws -> HTTPResponse.Status {
        let id = try context.parameters.require("id", as: UUID.self)
        guard let park = try await Park.find(id, on: fluent.db()) else {
            throw HTTPError(.notFound)
        }
        
        try await park.delete(on: fluent.db())
        return .ok
    }
}
