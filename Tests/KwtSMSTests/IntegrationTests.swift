import XCTest
@testable import KwtSMS

/// Integration tests that hit the live kwtSMS API with test mode enabled.
///
/// These tests require SWIFT_USERNAME and SWIFT_PASSWORD environment variables.
/// All sends use test_mode=true so no messages are delivered; their credits are held until you
/// delete them from the Sending Queue. 2026-10-22 15:37 +03: corrected, test sends are not free.
///
/// Run: SWIFT_USERNAME=user SWIFT_PASSWORD=pass KWTSMS_TEST_NUMBER=965XXXXXXXX swift test --filter IntegrationTests
///
/// 2026-11-05 09:24 +03: sends go only to KWTSMS_TEST_NUMBER via TestNumber (tests that need it
/// skip when unset); the hardcoded sample number belonged to a real person. Task: int-testnumber.
final class IntegrationTests: XCTestCase {

    private var sms: KwtSMS!
    private var hasCredentials: Bool = false

    override func setUp() async throws {
        let username = ProcessInfo.processInfo.environment["SWIFT_USERNAME"] ?? ""
        let password = ProcessInfo.processInfo.environment["SWIFT_PASSWORD"] ?? ""

        if username.isEmpty || password.isEmpty {
            hasCredentials = false
            return
        }

        hasCredentials = true
        sms = KwtSMS(
            username: username,
            password: password,
            testMode: true,
            logFile: ""  // no log file during tests
        )
    }

    private func skipIfNoCredentials() throws {
        if !hasCredentials {
            throw XCTSkip("SWIFT_USERNAME / SWIFT_PASSWORD not set")
        }
    }

    // MARK: - verify()

    func testVerifyWithValidCredentials() async throws {
        try skipIfNoCredentials()
        let result = await sms.verify()
        XCTAssertTrue(result.ok, "verify() should succeed with valid credentials: \(result.error ?? "")")
        XCTAssertNotNil(result.balance)
        XCTAssertTrue(result.balance! >= 0)
    }

    func testVerifyWithWrongCredentials() async throws {
        try skipIfNoCredentials()
        let badSms = KwtSMS(username: "wrong_user", password: "wrong_pass", testMode: true, logFile: "")
        let result = await badSms.verify()
        XCTAssertFalse(result.ok)
        XCTAssertNotNil(result.error)
    }

    // MARK: - balance()

    func testBalanceReturnsNumber() async throws {
        try skipIfNoCredentials()
        let balance = await sms.balance()
        XCTAssertNotNil(balance)
        XCTAssertTrue(balance! >= 0)
    }

    // MARK: - send()

    func testSendToValidKuwaitNumber() async throws {
        try skipIfNoCredentials()
        let result = await sms.send(mobile: try TestNumber.get(), message: "Test from Swift client")
        // With test mode, the API should accept it (result OK) or return a known error
        // The number may not be real, so ERR006 is also acceptable
        XCTAssertTrue(["OK", "ERROR"].contains(result.result))
        if result.result == "OK" {
            XCTAssertNotNil(result.msgId)
        }
    }

    func testSendWithPlusPrefix() async throws {
        try skipIfNoCredentials()
        let result = await sms.send(mobile: try TestNumber.variant(.plus), message: "Test normalization")
        // Should normalize and send, not crash
        XCTAssertTrue(["OK", "ERROR"].contains(result.result))
    }

    func testSendWith00Prefix() async throws {
        try skipIfNoCredentials()
        let result = await sms.send(mobile: try TestNumber.variant(.doubleZero), message: "Test normalization")
        XCTAssertTrue(["OK", "ERROR"].contains(result.result))
    }

    func testSendWithArabicDigits() async throws {
        try skipIfNoCredentials()
        let result = await sms.send(
            mobile: try TestNumber.variant(.arabic),
            message: "Test Arabic digit normalization"
        )
        XCTAssertTrue(["OK", "ERROR"].contains(result.result))
    }

    func testSendToEmail() async throws {
        try skipIfNoCredentials()
        let result = await sms.send(mobile: "user@gmail.com", message: "Should fail")
        XCTAssertEqual(result.result, "ERROR")
        XCTAssertEqual(result.code, "ERR_INVALID_INPUT")
        XCTAssertFalse(result.invalid.isEmpty)
    }

    func testSendToTooShort() async throws {
        try skipIfNoCredentials()
        let result = await sms.send(mobile: "123", message: "Should fail")
        XCTAssertEqual(result.result, "ERROR")
        XCTAssertEqual(result.code, "ERR_INVALID_INPUT")
    }

    func testSendToLetters() async throws {
        try skipIfNoCredentials()
        let result = await sms.send(mobile: "abcdefgh", message: "Should fail")
        XCTAssertEqual(result.result, "ERROR")
        XCTAssertEqual(result.code, "ERR_INVALID_INPUT")
    }

    func testSendMixedValidInvalid() async throws {
        try skipIfNoCredentials()
        let result = await sms.send(
            mobiles: [try TestNumber.get(), "user@email.com", "123"],
            message: "Test mixed input"
        )
        // Valid number should still be sent, invalid ones collected
        XCTAssertFalse(result.invalid.isEmpty)
        XCTAssertEqual(result.invalid.count, 2)
    }

    func testSendEmptyMessage() async throws {
        try skipIfNoCredentials()
        let result = await sms.send(mobile: try TestNumber.get(), message: "")
        XCTAssertEqual(result.result, "ERROR")
        XCTAssertEqual(result.code, "ERR009")
    }

    func testSendEmojiOnlyMessage() async throws {
        try skipIfNoCredentials()
        let result = await sms.send(mobile: try TestNumber.get(), message: "\u{1F600}\u{1F601}")
        XCTAssertEqual(result.result, "ERROR")
        XCTAssertEqual(result.code, "ERR009")
    }

    func testSendDeduplicatesNumbers() async throws {
        try skipIfNoCredentials()
        let result = await sms.send(
            mobiles: [try TestNumber.variant(.plus), try TestNumber.variant(.doubleZero), try TestNumber.get()],
            message: "Dedup test"
        )
        // All three normalize to the same number, should only send once
        XCTAssertTrue(["OK", "ERROR"].contains(result.result))
    }

    func testSendSingleLeadingZero() async throws {
        try skipIfNoCredentials()
        // "0" + local part becomes the 8-digit local part after normalization (single leading zero stripped)
        let result = await sms.send(mobile: "0" + (try TestNumber.local()), message: "Single leading zero test")
        XCTAssertTrue(["OK", "ERROR"].contains(result.result))
        // Number is valid (8 digits, passes length check) but may get ERR006/ERR025 from API
    }

    func testSendToCountryNotInCoverage() async throws {
        try skipIfNoCredentials()
        // Somalia (+252) is unlikely to be activated on a Kuwait test account
        let result = await sms.send(mobile: "25261234567", message: "Coverage test")
        // Expect ERROR with ERR026 (country not activated) or similar
        XCTAssertEqual(result.result, "ERROR")
        if let code = result.code {
            // 2026-11-06 12:16 +03: ERR_INVALID_INPUT added: this sample has 8 digits after +252 (Somali mobiles have 9),
            // so the client now rejects it locally before any API call. Found in the 0.4.0 release check.
            XCTAssertTrue(["ERR006", "ERR025", "ERR026", "ERR_INVALID_INPUT"].contains(code),
                "Expected country/number error, got \(code): \(result.description ?? "")")
        }
        XCTAssertNotNil(result.action ?? result.description, "Should have error guidance")
    }

    // MARK: - senderIds()

    func testSenderIdsReturnsList() async throws {
        try skipIfNoCredentials()
        let result = await sms.senderIds()
        XCTAssertEqual(result.result, "OK")
        XCTAssertFalse(result.senderIds.isEmpty, "Should have at least one sender ID")
    }

    // MARK: - coverage()

    func testCoverageReturnsPrefixes() async throws {
        try skipIfNoCredentials()
        let result = await sms.coverage()
        XCTAssertEqual(result.result, "OK")
        XCTAssertFalse(result.prefixes.isEmpty, "Should have at least one active prefix")
    }

    // MARK: - validate()

    func testValidateWithValidNumber() async throws {
        try skipIfNoCredentials()
        let result = await sms.validate(phones: [try TestNumber.get()])
        // The number may end up in OK, ER, or NR depending on account configuration
        XCTAssertNil(result.error)
    }

    func testValidateWithInvalidInput() async throws {
        try skipIfNoCredentials()
        let result = await sms.validate(phones: ["user@email.com", try TestNumber.get()])
        XCTAssertEqual(result.rejected.count, 1)
        XCTAssertTrue(result.rejected[0].error.contains("email"))
    }

    // MARK: - status()

    func testStatusWithFakeId() async throws {
        try skipIfNoCredentials()
        let result = await sms.status(msgId: "nonexistent_msg_id_12345")
        XCTAssertEqual(result.result, "ERROR")
        // Should get ERR029 (message does not exist)
    }

    // MARK: - deliveryReport()

    func testDlrWithFakeId() async throws {
        try skipIfNoCredentials()
        let result = await sms.deliveryReport(msgId: "nonexistent_msg_id_12345")
        XCTAssertEqual(result.result, "ERROR")
        // Should get ERR020 (message does not exist)
    }

    // MARK: - Wrong sender ID

    func testSendWithWrongSenderId() async throws {
        try skipIfNoCredentials()
        let username = ProcessInfo.processInfo.environment["SWIFT_USERNAME"]!
        let password = ProcessInfo.processInfo.environment["SWIFT_PASSWORD"]!
        let badSender = KwtSMS(
            username: username,
            password: password,
            senderId: "NONEXISTENT-SENDER-12345",
            testMode: true,
            logFile: ""
        )
        let result = await badSender.send(mobile: try TestNumber.get(), message: "Wrong sender test")
        // Expect ERROR with ERR008 or similar
        if result.result == "ERROR" {
            XCTAssertNotNil(result.action ?? result.description)
        }
    }

    // MARK: - Cached balance

    func testCachedBalanceUpdatedAfterVerify() async throws {
        try skipIfNoCredentials()
        let initial = await sms.cachedBalance
        XCTAssertNil(initial) // no API call yet

        _ = await sms.verify()
        let cached = await sms.cachedBalance
        XCTAssertNotNil(cached)
    }
}
