//
//  Park.swift
//
//
//  Created by Szabolcs Tóth on 06.04.2024.
//  Copyright © 2024 Szabolcs Tóth. All rights reserved.
//

import FluentKit
import Hummingbird

final class Coordinates: Fields {
    @Field(key: "latitude")
    var latitude: Double
    
    @Field(key: "longitude")
    var longitude: Double
    
    // Initialization
    init() { }
}

final class Park: Model {
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
