import XCTest

@testable import BitwardenShared

// MARK: - CaptchaServiceTests

class CaptchaServiceTests: BitwardenTestCase {
    // MARK: Properties

    var subject: DefaultCaptchaService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        subject = DefaultCaptchaService(
            baseUrlService: DefaultBaseUrlService(baseUrl: .example)
        )
    }

    override func tearDown() {
        super.tearDown()
        subject = nil
    }

    // MARK: Tests

    func test_callbackUrlScheme() {
        XCTAssertEqual(subject.callbackUrlScheme, "bitwarden")
    }

    func test_generateCaptchaUrl() throws {
        let url = try subject.generateCaptchaUrl(with: "12345")

        var correctUrlComponents = URLComponents(string: "https://example.com/captcha-mobile-connector.html")
        correctUrlComponents?.queryItems = [
            URLQueryItem(
                name: "data",
                value: "eyJsb2NhbGUiOiJlbiIsImNhbGxiYWNrVXJpIjoiYml0d2FyZGVuOlwvXC9jYXB0Y2hhLWNhbGxiYWNrIiwiY2FwdGNoYVJlcXVpcmVkVGV4dCI6IkNhcHRjaGEgcmVxdWlyZWQiLCJzaXRlS2V5IjoiMTIzNDUifQ==" // swiftlint:disable:this line_length
            ),
            URLQueryItem(name: "parent", value: "bitwarden://captcha-callback"),
            URLQueryItem(name: "v", value: "1"),
        ]
        XCTAssertEqual(URLComponents(url: url, resolvingAgainstBaseURL: false), correctUrlComponents)
    }
}