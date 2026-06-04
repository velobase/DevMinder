import Foundation

public struct CommandResult: Sendable {
    public let stdout: String
    public let stderr: String
    public let status: Int32
}

public enum CommandRunnerError: Error, LocalizedError {
    case launchFailed(String)

    public var errorDescription: String? {
        switch self {
        case .launchFailed(let command):
            "Failed to launch \(command)."
        }
    }
}

public struct CommandRunner: Sendable {
    public init() {}

    @discardableResult
    public func run(_ executable: String, arguments: [String]) throws -> CommandResult {
        let task = Foundation.Process()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()

        task.executableURL = URL(fileURLWithPath: executable)
        task.arguments = arguments
        task.standardOutput = stdoutPipe
        task.standardError = stderrPipe

        let stdoutData = DataBox()
        let stderrData = DataBox()
        let group = DispatchGroup()
        let queue = DispatchQueue.global(qos: .utility)

        do {
            try task.run()
        } catch {
            throw CommandRunnerError.launchFailed(([executable] + arguments).joined(separator: " "))
        }

        group.enter()
        queue.async {
            stdoutData.set(stdoutPipe.fileHandleForReading.readDataToEndOfFile())
            group.leave()
        }

        group.enter()
        queue.async {
            stderrData.set(stderrPipe.fileHandleForReading.readDataToEndOfFile())
            group.leave()
        }

        task.waitUntilExit()
        group.wait()

        return CommandResult(
            stdout: String(data: stdoutData.value, encoding: .utf8) ?? "",
            stderr: String(data: stderrData.value, encoding: .utf8) ?? "",
            status: task.terminationStatus
        )
    }
}

private final class DataBox: @unchecked Sendable {
    private let lock = NSLock()
    private var data = Data()

    var value: Data {
        lock.withLock { data }
    }

    func set(_ data: Data) {
        lock.withLock {
            self.data = data
        }
    }
}
