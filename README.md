# Simple Hummingbird tutorial

The source code is [here]().

The tutorial text is below:


# Park of Prague API - Server side Swift with Hummingbird 2

**The [original article](https://medium.com/better-programming/park-api-server-side-swift-with-hummingbird-a9be304f22a5) was written in June 2023. However, since then, several changes have occurred, rendering the article less relevant(or not relevant at all) in its original state.**

Server side Swift has been available since end of 2015. The idea was behind the development that you can use the same language for RESTful APIs, desktop and mobile applications. With the evolution of the Swift language, the different Swift web frameworks got more robust and complex. 

That's why I was happy to read [Tib's excellent article](https://theswiftdev.com/beginners-guide-to-server-side-swift-using-the-hummingbird-framework) about a new HTTP server library written in Swift, [Hummingbird](https://github.com/hummingbird-project/hummingbird). I immediately liked the concept of modularity, so decided to create a tutorial to show its simplicity.

We will build a swift server running on SQLite database, which will store parks around the city with name and coordinates. A simple JSON response will look like this:

```json
[
    {
        "name": "Stromovka",
        "coordinates": {
            "latitude": 50.105849,
            "longitude": 14.413999
        }
    },
    {
        "name": "Letenské sady",
        "coordinates": {
            "latitude": 50.0959721,
            "longitude": 14.4202892
        }
    },
    {
        "name": "Žernosecká - Čumpelíkova",
        "coordinates": {
            "latitude": 50.132259369,
            "longitude": 14.46098423
        }
    }
]
```

## Step 1. - Init the project

```shell
mkdir parkAPI && cd $_
swift package init --type executable
```

This creates the backbones of our project. One of the most important file and initial point of our project is the  `Package.swift`, the Swift manifest file. [Here](https://theswiftdev.com/the-swift-package-manifest-file/) you can read more about it.

## Step 2. - Create the folder structure
We need to follow a certain guidelines about folder structure, otherwise the compiler won't be able to handle our project. On the picture below, you can find the simplest structure, which follow the [Hummingbird template](https://github.com/hummingbird-project/template). 

```shell
.
├── Package.swift
├── README.md
└── Sources
    └── ParksOfPrague
        ├── App.swift
        └── Application+configure.swift
```

We will add the `Tests` folder later, when we will have something to test.

## Step 3. - Configure the server

Before we are able to run our server, we need to add two packages to the `Package.swift` file:

- [Hummingbird](https://github.com/hummingbird-project/hummingbird.git)
- [Swift Argument Parser](https://github.com/apple/swift-argument-parser.git)

```swift
import PackageDescription

let package = Package(
    name: "ParksOfPrague",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.0.0-beta.2"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
    ],
    targets: [
        .executableTarget(
            name: "ParksOfPrague",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Hummingbird", package: "hummingbird"),
            ],
            swiftSettings: [
                .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release)),
            ]
        ),
    ]
)
```

Using `.executableTarget` the `@main` will be the enrty point of our application and we can rename `main.swift` to `App.swift`. Paul Hudson wrote a [short article](https://www.hackingwithswift.com/swift/5.4/spm-executable-targets) about it. 

Define the hostname and port in the `App.swift`.

```swift
import ArgumentParser

@main
struct HummingbirdArguments: AsyncParsableCommand {
    @Option(name: .shortAndLong)
    var hostname: String = "127.0.0.1"

    @Option(name: .shortAndLong)
    var port: Int = 8080

    func run() async throws {
        let app = buildApplication(
            configuration: .init(
                address: .hostname(self.hostname, port: self.port),
                serverName: "Parks of Prague"
            )
        )
        
        try await app.runService()
    }
}
```

  We need to use [`AsyncParsableCommand`](https://apple.github.io/swift-argument-parser/documentation/argumentparser/asyncparsablecommand/)protocol.

One last thing remained before we can run our application is to define the `route` in the `Application+configuration.swift`.

```swift
import Hummingbird

func buildApplication(configuration: ApplicationConfiguration) -> some ApplicationProtocol {
    // Router
    let router = Router()
    
    router.get("/") { _, _ in
        return  "The server is running...🚀"
    }

    // Application
    let app = Application(
        router: router,
        configuration: configuration
    )
    return app
}
```

Run our first Hummingbird server:

```
swift run ParksOfPrague
```


## Step 4. Create API response
Our server will be accessible on the following routes, using different [HTTP methods](https://www.freecodecamp.org/news/http-request-methods-explained/).

- `GET` - `http://hostname/api/v1/parks`: Lists all the parks in the database
- `GET` - `http://hostname/api/v1/parks/:id`: Shows a single park with given id
- `POST` - `http://hostname/api/v1/parks`: Creates a new park
- `PATCH` - `http://hostname/api/v1/parks/:id`: Updates the park with the given id
- `DELETE` - `http://hostname/api/v1/parks/:id`: Removes the park with id from database

### Step 4.1 Add database dependency

Our server will use SQLite database to store all data, so we need to add two database dependencies:
- [Fluent driver for SQLite](https://github.com/vapor/fluent-sqlite-driver.git)
- [Hummingbird Fluent](https://github.com/hummingbird-project/hummingbird-fluent.git)

to our manifest file. This will allow the server to communicate to the database.

The updated `Package.swift` file will look like this:

```swift
import PackageDescription

let package = Package(
    name: "ParksOfPrague",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.0.0-beta.2"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
        // Database dependencies 
        .package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.6.0"),
        .package(url: "https://github.com/hummingbird-project/hummingbird-fluent.git", from: "2.0.0-beta.1")
    ],
    targets: [
        .executableTarget(
            name: "ParksOfPrague",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Hummingbird", package: "hummingbird"),
                // Database dependencies 
                .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
                .product(name: "HummingbirdFluent", package: "hummingbird-fluent")
            ],
            swiftSettings: [
                .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release)),
            ]
        ),
    ]
)
```

### Step 4.2 Add `Park` model
Inside the database, the data are organised by our `Park` model, which contains:
- `name`
- `Coordinates`
	- `latitude`
	- `longitude`

Create a `Models` folder under `Sources/ParksOfPrague` 

```shell
.
├── Package.swift
├── README.md
└── Sources
   └── ParksOfPrague
       ├── App.swift
       ├── Application+configure.swift
       └── Models
           └── Park.swift
```

Add `Park.swift` file:

```swift
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
```

`ResponseEncodable` protocol is all about making your Swift types work nicely with HTTP responses.

### Step 4.3 Create a database migration file 

To represent our `Park` model in database, we need to create a migration file. For better organisation it is recommended to create `Migrations` folder under `Sources/ParksOfPrague`.

```shell
.
├── Package.swift
├── README.md
└──  Sources
   └── ParksOfPrague
       ├── App.swift
       ├── Application+configure.swift
       ├── Migrations
       │   └── CreateParkTableMigration.swift
       └── Models
           └── Park.swift
```
 
 Add `CreateParkTableMigration.swift` file: 
 
```swift
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
```
 

### Step 4.4 Call database migration

In our `Application+configure.swift` import the following libraries:
-  FluentSQLiteDriver
-  HummingbirdFluent

Define the name of the SQLite database:

```
fluent.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)
```

Add database migration, we have just created:

```swift
await fluent.migrations.add(CreateParkTableMigration())
```

Execute migration:

```swift
 try await fluent.migrate()
```

Add `fluent` to `appServices` at the end:

```swift
app.addServices(fluent)
```

As the newly added calls use `await` and they can fail and throw errors, we need to add `async throws` to our `buildApplication` function.

The update `Application+configure.swift` file:

```swift
import FluentSQLiteDriver
import Foundation
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
 
    fluent.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)

    await fluent.migrations.add(CreateParkTableMigration())
 
    try await fluent.migrate()
    
    
    // Application
    var app = Application(
        router: router,
        configuration: configuration
    )
    
    app.addServices(fluent)
    return app
}
```



### Step 4.4 Use concurrency in `App.swift`

Call `let app = buildApplication` with `try await` as we have already added `async throws` to it.

```swift
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
```
  
 ### Step 4.5 Create the park controller
 
 The `Controller` receives an input from the users, then processes the user's data with the help of `Model` and passes the results back. Add `ParksController.swift` to a new `Controllers` folder under `Source/ParksOfPrague`.
 
 ```shell
 .
├── Package.swift
├── README.md
├── Sources
│   └── ParksOfPrague
│       ├── App.swift
│       ├── Application+configure.swift
│       ├── Controllers
│       │   └── ParksController.swift
│       ├── Migrations
│       │   └── CreateParkTableMigration.swift
│       └── Models
│           └── Park.swift
└── db.sqlite
 ```
 
 #### GET - all parks
Start with listing all elements: `.get(use: self.index)` Where `get` refers to `GET` method and `use` to the function where you describe what supposed to happen, if you call that endpoint.

The `index()` function returns with the array of `Park` model.  
 
 ```swift
import FluentKit
import Hummingbird
import HummingbirdFluent

struct ParksController<Context: RequestContext> {
    
    let fluent: Fluent
    
    func addRoutes(to group:RouterGroup<Context>) {
        group
            .get(use: self.index)
    }
    
     // MARK: - index
    /// Returns with all parks in the database
    @Sendable func index(_ request: Request, context: Context) async throws -> [Park] {
        try await Park.query(on: self.fluent.db()).all()
    }
}
 ```
 
Use [`RouterGroup`](https://docs.hummingbird.codes/2.0/documentation/hummingbird/routergroup) to collect all routes under single path.

#### GET - park with {id}
Show park with specified id: `.get(":id", use: self.show)`.

 ``` swift
@Sendable func show(_ request: Request, context: Context) async throws -> Park? {
    let id = try context.parameters.require("id", as: UUID.self)
    guard let park = try await Park.find(id, on: fluent.db()) else {
        throw HTTPError(.notFound)
    }
    
    return park
}
```


#### POST - create park
Create new park: `.post(use: self.create)`.

```swift
@Sendable func create(_ request: Request, context: Context) async throws -> Park {
    let park = try await request.decode(as: Park.self, context: context)
    try await park.save(on: fluent.db())
    return park
}
```

#### PUT - update park with {id}
Update park with specified id: `.put(":id", use: self.update)`

```swift
@Sendable func update(_ request: Request, context: Context) async throws -> HTTPResponse.Status {
    let id = try context.parameters.require("id", as: UUID.self)
    guard let park = try await Park.find(id, on: fluent.db()) else {
        throw HTTPError(.notFound)
    }
    
    let updatedPark = try await request.decode(as: Park.self, context: context)
    
    park.name = updatedPark.name
    park.latitude = updatedPark.latitude
    park.longitude = updatedPark.longitude
    
    try await park.save(on: fluent.db())
    
    return .ok
}
```

As in the `DatabaseSetup.swift` file we defined that none of table columns can be `NULL`, we need to check that the request contains all values of only some of them and update the columns respectively. 

#### DELETE - delete park with {id}
Delete park with specified id: `.delete(":id", use: deletePark)`

```swift
@Sendable func delete(_ request: Request, context: Context) async throws -> HTTPResponse.Status {
    let id = try context.parameters.require("id", as: UUID.self)
    guard let park = try await Park.find(id, on: fluent.db()) else {
        throw HTTPError(.notFound)
    }
    
    try await park.delete(on: fluent.db())
    return .ok
}
```


Our final folder structure looks like this:

```shell
.
├── Package.resolved
├── Package.swift
├── README.md
├── Sources
│   └── ParksOfPrague
│       ├── App.swift
│       ├── Application+configure.swift
│       ├── Controllers
│       │   └── ParksController.swift
│       ├── Migrations
│       │   └── CreateParkTableMigration.swift
│       └── Models
│           └── Park.swift
└── db.sqlite
```

### Step 4.5 Add `ParksController` to `Application+configure`
Above `var app = Application` add the following:

```swift
    // Add controller
    ParksController(fluent: fluent).addRoutes(to: router.group("api/v1/parks"))
```
### Step 5: Run the API server:
`swift run parkAPI`

You can reach the server on: `http://127.0.0.1:8080`

Your API endpoint will be on:  `http://127.0.0.1:8080/api/v1/parks`

### Summary
I was impressed how easily and quickly I could build a working API server using [Hummingbird](https://github.com/hummingbird-project/hummingbird). 

Building and running the project took very minimal time comparing to Vapor. I highly recommend to try Hummingbird project in case you want something light and modular on Server side Swift.