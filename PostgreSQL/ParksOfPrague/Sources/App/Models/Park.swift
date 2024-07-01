import FluentKit
import Foundation
import HummingbirdFluent
import Hummingbird


final class Coordinates: Fields, @unchecked Sendable {
    @Field(key: "latitude")
    var latitude: Double
    
    @Field(key: "longitude")
    var longitude: Double
    
    // Initialization
    init() { }
}

final class Park: Model, @unchecked Sendable {
    static let schema = "parks"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Group(key: "coordinates")
    var coordinates: Coordinates
    
    init() {}
    
    init(id: UUID? = nil, name: String, coordinates: Coordinates) {
        self.id = id
        self.name = name
        self.coordinates = coordinates
    }
}

extension Park: ResponseCodable, Codable {}
