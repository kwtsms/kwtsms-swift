// FILE:      Tests/KwtSMSTests/UserAgentTests.swift
// CREATED:   2026-11-05 14:22 +03
// TASK:      #939 (int-measure-signups)
// AUTHOR:    M Alhassoun
// WHAT:      Unit tests for the User-Agent the client sends.
// WHY:       kwtSMS counts accounts per integration from the User-Agent; it must be
//            kwtsms-swift/<version> and a caller's app token must never inject headers.
// USAGE:     swift test --filter UserAgentTests
// DEPENDS:   no network, no credentials.

import XCTest
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import KwtSMS

final class UserAgentTests: XCTestCase {

    func testDefaultUserAgentIsLibraryToken() {
        let sms = KwtSMS(username: "swift_username", password: "swift_password", logFile: "")
        XCTAssertEqual(sms.userAgent, "kwtsms-swift/\(KwtSMS.version)")
        XCTAssertNotNil(sms.userAgent.range(of: "^kwtsms-swift/[0-9][0-9A-Za-z.+-]*$", options: .regularExpression))
    }

    func testAppTokenPrepended() {
        let sms = KwtSMS(username: "swift_username", password: "swift_password", logFile: "",
                         appName: "kwtsms-wordpress/3.5.2")
        XCTAssertEqual(sms.userAgent, "kwtsms-wordpress/3.5.2 kwtsms-swift/\(KwtSMS.version)")
    }

    func testSanitizerRemovesCRLFNonASCIIAndLimitsLength() {
        let ua = KwtSMS.buildUserAgent(appName: "my app\r\nX-Injected: 1")
        XCTAssertFalse(ua.contains("\r") || ua.contains("\n"))
        XCTAssertFalse(ua.contains(" X-Injected"))
        XCTAssertEqual(ua, "my-appX-Injected:-1 kwtsms-swift/\(KwtSMS.version)")
        let long = KwtSMS.buildUserAgent(appName: String(repeating: "a", count: 200))
        XCTAssertEqual(long.split(separator: " ")[0].utf8.count, 64)
        XCTAssertEqual(KwtSMS.buildUserAgent(appName: " \r\n "), "kwtsms-swift/\(KwtSMS.version)")
        XCTAssertEqual(KwtSMS.buildUserAgent(appName: "\u{0643}\u{0648}shop/1.0"),
                       "shop/1.0 kwtsms-swift/\(KwtSMS.version)")
    }

    func testHeaderIsSetOnURLRequest() {
        let request = makeAPIRequest(url: URL(string: "https://www.kwtsms.com/API/balance/")!,
                                     userAgent: "my-shop/2.1.0 kwtsms-swift/\(KwtSMS.version)")
        XCTAssertEqual(request.value(forHTTPHeaderField: "User-Agent"),
                       "my-shop/2.1.0 kwtsms-swift/\(KwtSMS.version)")
        XCTAssertEqual(request.httpMethod, "POST")
    }
}
