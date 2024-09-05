import Combine
import Foundation
import SwiftUI
import XCTest

extension XCTestCase {
    func unwrap<O>(_ obj: O?, file: StaticString = #filePath, line: UInt = #line) throws -> O {
        try XCTUnwrap(obj, file: file, line: line)
    }

    @MainActor func wait<T, U: Equatable>(for keyPath: KeyPath<T, U>, in parent: T, toBeTrue expected: @escaping (U) -> Bool, timeout: Double = 5.0) {
        let exp = expectation(description: #function)

        if expected(parent[keyPath: keyPath]) {
            exp.fulfill()
        }

        withObservationTracking {
            _ = parent[keyPath: keyPath]
        } onChange: {
            if expected(parent[keyPath: keyPath]) {
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: timeout)
    }
}

class AsyncObserver {
    init() {}

    private var subscriber: Cancellable?
    private var resumed: Bool = false
    private var timer: Timer?

    func wait<Value>(
        for model: Published<Value>.Publisher,
        toBeTrue condition: @escaping (Value) -> Bool,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        return try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self = self else {
                return continuation.resume(throwing: WaitError.timeout)
            }
            self.timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { [weak self] _ in
                guard let self = self, self.resumed == false else {
                    return continuation.resume(throwing: WaitError.timeout)
                }
                self.resumed = true
                XCTFail(
                    "Async timout",
                    file: file,
                    line: line
                )
                continuation.resume(throwing: WaitError.timeout)
                self.subscriber?.cancel()
            }

            self.subscriber = model.sink { [weak self] value in
                print("⏸️ AsyncObserver: received value", value)
                guard
                    let self = self,
                    self.resumed == false,
                    condition(value)
                else { return }
                self.resumed = true
                self.timer?.invalidate()
                self.timer = nil
                self.subscriber?.cancel()
                continuation.resume()
            }
        }
    }

    public enum WaitError: Error {
        case timeout
    }
}
