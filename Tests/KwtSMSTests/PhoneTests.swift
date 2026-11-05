import XCTest
@testable import KwtSMS

// 2026-11-05 09:24 +03: Kuwait number literals replaced by TestNumber (KWTSMS_TEST_NUMBER,
// skipped when unset); asserts use TestNumber.assertSame so values are never printed.
// Why: the old sample number belongs to a real person. Task: int-testnumber.
final class PhoneTests: XCTestCase {

    // MARK: - normalizePhone()

    func testStripsPlus() throws {
        TestNumber.assertSame(normalizePhone(try TestNumber.variant(.plus)), try TestNumber.get())
    }

    func testStripsDoubleZero() throws {
        TestNumber.assertSame(normalizePhone(try TestNumber.variant(.doubleZero)), try TestNumber.get())
    }

    func testStripsSpaces() throws {
        TestNumber.assertSame(normalizePhone(try TestNumber.variant(.spaces)), try TestNumber.get())
    }

    func testStripsDashes() throws {
        TestNumber.assertSame(normalizePhone(try TestNumber.variant(.dashes)), try TestNumber.get())
    }

    func testStripsDots() throws {
        TestNumber.assertSame(normalizePhone(try TestNumber.variant(.dots)), try TestNumber.get())
    }

    func testStripsParentheses() throws {
        TestNumber.assertSame(normalizePhone(try TestNumber.variant(.parens)), try TestNumber.get())
    }

    func testStripsSlashes() throws {
        TestNumber.assertSame(normalizePhone(try TestNumber.variant(.slashes)), try TestNumber.get())
    }

    func testStripsMixedSeparators() throws {
        TestNumber.assertSame(normalizePhone(try TestNumber.variant(.mixed)), try TestNumber.get())
    }

    func testArabicIndicDigits() throws {
        TestNumber.assertSame(normalizePhone(try TestNumber.variant(.arabic)), try TestNumber.get())
    }

    func testExtendedArabicIndicDigits() throws {
        TestNumber.assertSame(normalizePhone(try TestNumber.variant(.persian)), try TestNumber.get())
    }

    func testStripsLeadingZeros() throws {
        TestNumber.assertSame(normalizePhone("000" + (try TestNumber.get())), try TestNumber.get())
    }

    func testStripsSingleLeadingZero() throws {
        TestNumber.assertSame(normalizePhone("0" + (try TestNumber.local())), try TestNumber.local())
    }

    func testEmptyString() {
        XCTAssertEqual(normalizePhone(""), "")
    }

    func testOnlySpaces() {
        XCTAssertEqual(normalizePhone("   "), "")
    }

    func testOnlyLetters() {
        XCTAssertEqual(normalizePhone("abcdef"), "")
    }

    func testAlreadyClean() throws {
        TestNumber.assertSame(normalizePhone(try TestNumber.get()), try TestNumber.get())
    }

    // MARK: - Domestic trunk prefix stripping

    func testSaudiTrunkPrefix() {
        // 9660559123456 -> 966559123456 (strip the 0 after 966)
        XCTAssertEqual(normalizePhone("9660559123456"), "966559123456")
    }

    func testSaudiTrunkPrefixWithPlus() {
        XCTAssertEqual(normalizePhone("+9660559123456"), "966559123456")
    }

    func testSaudiTrunkPrefixWith00() {
        XCTAssertEqual(normalizePhone("009660559123456"), "966559123456")
    }

    func testUAETrunkPrefix() {
        // 9710501234567 -> 971501234567
        XCTAssertEqual(normalizePhone("9710501234567"), "971501234567")
    }

    func testEgyptTrunkPrefix() {
        // 20010xxxxxxx -> 2010xxxxxxx
        XCTAssertEqual(normalizePhone("2001012345678"), "201012345678")
    }

    func testKuwaitNoTrunkPrefix() throws {
        // Kuwait numbers don't use trunk prefix, should not be modified
        TestNumber.assertSame(normalizePhone(try TestNumber.get()), try TestNumber.get())
    }

    // MARK: - findCountryCode()

    func testFindCountryCode3Digit() throws {
        // get() outside the assert: an XCTSkip thrown inside its autoclosure would count as an error.
        let n = try TestNumber.get()
        XCTAssertEqual(findCountryCode(n), "965")
    }

    func testFindCountryCode2Digit() {
        XCTAssertEqual(findCountryCode("201012345678"), "20")
    }

    func testFindCountryCode1Digit() {
        XCTAssertEqual(findCountryCode("12125551234"), "1")
    }

    func testFindCountryCodeUnknown() {
        XCTAssertNil(findCountryCode("99912345678"))
    }

    func testFindCountryCodeLongestMatch() throws {
        // 965 is 3-digit and should match before any 2 or 1-digit code
        let n = try TestNumber.get()
        XCTAssertEqual(findCountryCode(n), "965")
    }

    // MARK: - validatePhoneFormat()

    func testValidKuwaitFormat() throws {
        let result = validatePhoneFormat(try TestNumber.get())
        XCTAssertTrue(result.valid)
    }

    func testInvalidKuwaitLengthTooShort() throws {
        let result = validatePhoneFormat(String(try TestNumber.get().dropLast()))  // 7 local digits, needs 8
        XCTAssertFalse(result.valid)
        XCTAssertTrue(result.error!.contains("Kuwait"))
        XCTAssertTrue(result.error!.contains("8 digits"))
    }

    func testInvalidKuwaitMobilePrefix() {
        let result = validatePhoneFormat("96512345678")  // starts with 1, not valid mobile
        XCTAssertFalse(result.valid)
        XCTAssertTrue(result.error!.contains("Kuwait"))
        XCTAssertTrue(result.error!.contains("must start with"))
    }

    func testValidSaudiFormat() {
        let result = validatePhoneFormat("966559123456")
        XCTAssertTrue(result.valid)
    }

    func testInvalidSaudiMobilePrefix() {
        let result = validatePhoneFormat("966359123456")  // starts with 3, Saudi needs 5
        XCTAssertFalse(result.valid)
        XCTAssertTrue(result.error!.contains("Saudi"))
    }

    func testValidUAEFormat() {
        let result = validatePhoneFormat("971501234567")
        XCTAssertTrue(result.valid)
    }

    func testValidUSFormat() {
        // USA has no mobile prefix restriction, length only
        let result = validatePhoneFormat("12125551234")
        XCTAssertTrue(result.valid)
    }

    func testUnknownCountryPassesThrough() {
        let result = validatePhoneFormat("99912345678")
        XCTAssertTrue(result.valid)
    }

    func testValidEgyptFormat() {
        let result = validatePhoneFormat("201012345678")
        XCTAssertTrue(result.valid)
    }

    func testValidBelgiumLengthOnly() {
        // Belgium has no mobile prefix restriction
        let result = validatePhoneFormat("32412345678")
        XCTAssertTrue(result.valid)
    }

    func testKuwaitAllValidPrefixes() throws {
        // 4x, 5x, 6x, 9x are all valid Kuwait mobile prefixes.
        // Built in memory from the test number's last 7 digits; validated locally only, never sent.
        let tail = String(try TestNumber.get().suffix(7))
        for prefix in ["4", "5", "6", "9"] {
            let result = validatePhoneFormat("965" + prefix + tail)
            XCTAssertTrue(result.valid, "Kuwait prefix \(prefix) should be valid")
        }
    }

    // MARK: - validatePhoneInput() (integrated with format validation)

    func testValidKuwaitNumber() throws {
        let (valid, error, normalized) = validatePhoneInput(try TestNumber.get())
        XCTAssertTrue(valid)
        XCTAssertNil(error)
        TestNumber.assertSame(normalized, try TestNumber.get())
    }

    func testValidWithPlusPrefix() throws {
        let (valid, error, normalized) = validatePhoneInput(try TestNumber.variant(.plus))
        XCTAssertTrue(valid)
        XCTAssertNil(error)
        TestNumber.assertSame(normalized, try TestNumber.get())
    }

    func testValidWith00Prefix() throws {
        let (valid, error, normalized) = validatePhoneInput(try TestNumber.variant(.doubleZero))
        XCTAssertTrue(valid)
        XCTAssertNil(error)
        TestNumber.assertSame(normalized, try TestNumber.get())
    }

    func testValidGenericNumber() {
        // Unknown country code, passes generic validation (7-15 digits)
        let (valid, error, _) = validatePhoneInput("9991234567")
        XCTAssertTrue(valid)
        XCTAssertNil(error)
    }

    func testEmptyInput() {
        let (valid, error, _) = validatePhoneInput("")
        XCTAssertFalse(valid)
        XCTAssertEqual(error, "Phone number is required")
    }

    func testBlankInput() {
        let (valid, error, _) = validatePhoneInput("   ")
        XCTAssertFalse(valid)
        XCTAssertEqual(error, "Phone number is required")
    }

    func testEmailAddress() {
        let (valid, error, _) = validatePhoneInput("user@gmail.com")
        XCTAssertFalse(valid)
        XCTAssertTrue(error!.contains("email address"))
    }

    func testNoDigitsFound() {
        let (valid, error, _) = validatePhoneInput("abcdef")
        XCTAssertFalse(valid)
        XCTAssertTrue(error!.contains("no digits found"))
    }

    func testTooShort() {
        let (valid, error, _) = validatePhoneInput("123")
        XCTAssertFalse(valid)
        XCTAssertTrue(error!.contains("too short"))
        XCTAssertTrue(error!.contains("3 digits"))
    }

    func testTooShortSingularDigit() {
        let (valid, error, _) = validatePhoneInput("1")
        XCTAssertFalse(valid)
        XCTAssertTrue(error!.contains("1 digit"))
    }

    func testTooLong() {
        let (valid, error, _) = validatePhoneInput("1234567890123456")
        XCTAssertFalse(valid)
        XCTAssertTrue(error!.contains("too long"))
        XCTAssertTrue(error!.contains("16 digits"))
    }

    func testArabicDigitsValidation() throws {
        let (valid, error, normalized) = validatePhoneInput(try TestNumber.variant(.arabic))
        XCTAssertTrue(valid)
        XCTAssertNil(error)
        TestNumber.assertSame(normalized, try TestNumber.get())
    }

    func testLeadingAndTrailingWhitespace() throws {
        let (valid, _, normalized) = validatePhoneInput(try TestNumber.variant(.padded))
        XCTAssertTrue(valid)
        TestNumber.assertSame(normalized, try TestNumber.get())
    }

    func testSaudiWithTrunkPrefix() {
        // 9660559123456 should normalize to 966559123456 and pass validation
        let (valid, error, normalized) = validatePhoneInput("9660559123456")
        XCTAssertTrue(valid)
        XCTAssertNil(error)
        XCTAssertEqual(normalized, "966559123456")
    }

    func testSaudiWithPlusTrunkPrefix() {
        let (valid, error, normalized) = validatePhoneInput("+9660559123456")
        XCTAssertTrue(valid)
        XCTAssertNil(error)
        XCTAssertEqual(normalized, "966559123456")
    }

    func testInvalidKuwaitPrefixViaValidateInput() {
        // 96512345678: prefix 1 is not valid for Kuwait mobile
        let (valid, error, _) = validatePhoneInput("96512345678")
        XCTAssertFalse(valid)
        XCTAssertTrue(error!.contains("Kuwait"))
    }

    func testInvalidSaudiLengthViaValidateInput() {
        // 96655912345: only 8 local digits, Saudi needs 9
        let (valid, error, _) = validatePhoneInput("96655912345")
        XCTAssertFalse(valid)
        XCTAssertTrue(error!.contains("Saudi"))
    }

    // MARK: - deduplicatePhones()

    func testDeduplicatePreservesOrder() {
        let result = deduplicatePhones(["111", "222", "111", "333", "222"])
        XCTAssertEqual(result, ["111", "222", "333"])
    }

    func testDeduplicateNoDuplicates() {
        let result = deduplicatePhones(["111", "222", "333"])
        XCTAssertEqual(result, ["111", "222", "333"])
    }

    func testDeduplicateEmpty() {
        let result = deduplicatePhones([])
        XCTAssertEqual(result, [])
    }
}
