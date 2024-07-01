import Hummingbird
import HummingbirdTesting
import Logging
import XCTest

@testable import App

final class AppTests: XCTestCase {
    struct TestArguments: AppArguments {
        let hostname = "127.0.0.1"
        let port = 0
        let logLevel: Logger.Level? = .trace
    }
    
    func testApp() async throws {
        let args = TestArguments()
        let app = try await buildApplication(args)
        try await app.test(.router) { client in
            try await client.execute(uri: "/health", method: .get) { response in
                XCTAssertEqual(response.status, .ok)
            }
        }
    }
    
    func test_list_all_parks_on_empty_db() async throws {
        let args = TestArguments()
        let app = try await buildApplication(args)
        try await app.test(.router) { client in
            try await client.execute(uri: "/api/v1/parks", method: .get) { response in
                let parks = try JSONDecoder().decode([Park].self, from: response.body)
                
                XCTAssertTrue(parks.isEmpty, "The parks array is not empty")
            }
        }
    }
}
