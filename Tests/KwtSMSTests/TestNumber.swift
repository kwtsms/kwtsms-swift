// FILE:      Tests/KwtSMSTests/TestNumber.swift
// CREATED:   2026-11-05 09:23 +03
// TASK:      int-testnumber
// AUTHOR:    M Alhassoun
// WHAT:      Shared test helper: the test phone number and its format variants.
// WHY:       Tests must not hardcode a phone number. The number comes from the
//            KWTSMS_TEST_NUMBER environment variable (an international Kuwait
//            mobile, digits only, 965XXXXXXXX) and every test that needs one
//            is skipped when it is unset or malformed.
// USAGE:     KWTSMS_TEST_NUMBER=965XXXXXXXX swift test
//            CI reads it from the repository secret of the same name.
//            Tests call `try TestNumber.get()` or `try TestNumber.variant(.plus)`
//            from a throwing test, then compare with TestNumber.assertSame so a
//            failure never prints the number. Never log the value.
// DEPENDS:   XCTest (XCTSkip), Foundation (ProcessInfo).

import Foundation
import XCTest

enum TestNumber {

    /// For values only passed through unchanged (for example a mocked response echo).
    static let placeholder = "965XXXXXXXX"

    private static let skipReason = "KWTSMS_TEST_NUMBER not set (digits only, 965 plus 8 digits)"

    /// KWTSMS_TEST_NUMBER when it is 965 followed by 8 Latin digits, else nil.
    private static let value: String? = {
        guard let raw = ProcessInfo.processInfo.environment["KWTSMS_TEST_NUMBER"] else { return nil }
        let n = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        // Latin digits only: Character.isNumber would also accept Arabic-Indic digits.
        let latinDigits = n.unicodeScalars.allSatisfy { $0.value >= 0x30 && $0.value <= 0x39 }
        guard n.count == 11, n.hasPrefix("965"), latinDigits else { return nil }
        return n
    }()

    /// KWTSMS_TEST_NUMBER, or throws XCTSkip when it is unset or malformed.
    static func get() throws -> String {
        guard let n = value else { throw XCTSkip(skipReason) }
        return n
    }

    /// The 8-digit local part (without 965). Throws XCTSkip when unset.
    static func local() throws -> String {
        String(try get().dropFirst(3))
    }

    enum Kind {
        case plain, plus, doubleZero, spaces, dashes, dots, slashes, parens, mixed, padded, arabic, persian
    }

    /// The test number written in the given format. Throws XCTSkip when unset.
    static func variant(_ kind: Kind) throws -> String {
        let n = try get()
        let digits = Array(n)
        let cc = String(digits[0..<3])
        let a = String(digits[3..<7])
        let b = String(digits[7...])
        switch kind {
        case .plain: return n
        case .plus: return "+\(n)"
        case .doubleZero: return "00\(n)"
        case .spaces: return "\(cc) \(a) \(b)"
        case .dashes: return "\(cc)-\(a)-\(b)"
        case .dots: return "\(cc).\(a).\(b)"
        case .slashes: return "\(cc)/\(a)/\(b)"
        case .parens: return "(\(cc)) \(a)\(b)"
        case .mixed: return "+00\(cc) (\(a))-\(b)"
        case .padded: return "  \(n)  "
        case .arabic: return shift(n, zero: 0x0660)
        case .persian: return shift(n, zero: 0x06F0)
        }
    }

    /// Latin digits to another digit block starting at `zero` (U+0660 Arabic-Indic, U+06F0 Persian).
    private static func shift(_ s: String, zero: UInt32) -> String {
        String(String.UnicodeScalarView(s.unicodeScalars.map { u in
            if u.value >= 0x30 && u.value <= 0x39, let mapped = Unicode.Scalar(zero + (u.value - 0x30)) {
                return mapped
            }
            return u
        }))
    }

    /// Assert equality without printing either value (they may hold the number).
    static func assertSame(_ expected: String?, _ actual: String?, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(expected == actual, "phone number does not match the expected value (values hidden)", file: file, line: line)
    }
}
