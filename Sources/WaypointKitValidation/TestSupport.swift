import Foundation

func XCTAssertEqual<T: Equatable>(_ lhs: T, _ rhs: T, _ message: String = "") {
    Validation.check(lhs == rhs, message.isEmpty ? "Expected \(lhs) == \(rhs)" : message)
}

func XCTAssertEqual(_ lhs: Double, _ rhs: Double, accuracy: Double, _ message: String = "") {
    Validation.check(abs(lhs - rhs) <= accuracy, message.isEmpty ? "Expected \(lhs) ~= \(rhs)" : message)
}

func XCTAssertNotEqual<T: Equatable>(_ lhs: T, _ rhs: T, _ message: String = "") {
    Validation.check(lhs != rhs, message.isEmpty ? "Expected \(lhs) != \(rhs)" : message)
}

func XCTAssertTrue(_ expression: Bool, _ message: String = "") {
    Validation.check(expression, message.isEmpty ? "Expected true" : message)
}

func XCTAssertFalse(_ expression: Bool, _ message: String = "") {
    Validation.check(!expression, message.isEmpty ? "Expected false" : message)
}

func XCTAssertNil<T>(_ value: T?, _ message: String = "") {
    Validation.check(value == nil, message.isEmpty ? "Expected nil" : message)
}

func XCTFail(_ message: String = "") {
    Validation.check(false, message.isEmpty ? "Explicit failure" : message)
}

enum Validation {
    static func check(_ condition: Bool, _ message: String) {
        guard condition else {
            fatalError(message)
        }
    }
}
