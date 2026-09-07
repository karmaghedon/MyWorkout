import Foundation

final class ThreadSafeBox<Value>:
    @unchecked Sendable {

    private let lock = NSLock()
    private var value: Value

    init(
        _ value: Value
    ) {
        self.value = value
    }

    func read<T>(
        _ operation: (Value) throws -> T
    ) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }

        return try operation(value)
    }

    func mutate<T>(
        _ operation: (inout Value) throws -> T
    ) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }

        return try operation(&value)
    }
}
