import XCTest
@testable import NetworkLayer

final class NetworkLayerTests: XCTestCase {
    func testHTTPMethodRawValues() {
        XCTAssertEqual(HTTPMethod.get.rawValue, "GET")
        XCTAssertEqual(HTTPMethod.post.rawValue, "POST")
        XCTAssertEqual(HTTPMethod.put.rawValue, "PUT")
        XCTAssertEqual(HTTPMethod.patch.rawValue, "PATCH")
        XCTAssertEqual(HTTPMethod.delete.rawValue, "DELETE")
    }

    func testNetworkErrorDescriptions() {
        let invalidURLError = NetworkError.invalidURL
        XCTAssertNotNil(invalidURLError.errorDescription)

        let httpError = NetworkError.httpError(statusCode: 404, data: nil)
        XCTAssertTrue(httpError.errorDescription?.contains("404") ?? false)
    }
}
