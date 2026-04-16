import Cocoa

final class Logger: @unchecked Sendable {
    static let shared = Logger()

    private let docsDir: URL
    private let queue = DispatchQueue(label: "com.dontbesedentary.logger")
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd"
        return f
    }()
    private let timestampFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return f
    }()

    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        docsDir = docs.appendingPathComponent("DontBeSedentary")
        try? FileManager.default.createDirectory(at: docsDir, withIntermediateDirectories: true)
    }

    private func currentFileURL() -> URL {
        let dateStr = dateFormatter.string(from: Date())
        return docsDir.appendingPathComponent("SittingMonitor-\(dateStr).log")
    }

    func log(_ message: String) {
        let timestamp = timestampFormatter.string(from: Date())
        let entry = "[\(timestamp)] \(message)\n"

        queue.async { [weak self] in
            guard let self = self else { return }
            let fileURL = self.currentFileURL()
            if !FileManager.default.fileExists(atPath: fileURL.path) {
                FileManager.default.createFile(atPath: fileURL.path, contents: nil)
                self.cleanupOldLogs()
            }
            if let handle = try? FileHandle(forWritingTo: fileURL) {
                handle.seekToEndOfFile()
                if let data = entry.data(using: .utf8) {
                    handle.write(data)
                }
                handle.closeFile()
            }
        }
    }

    func openLogFile() {
        NSWorkspace.shared.open(currentFileURL())
    }

    private func cleanupOldLogs() {
        let fm = FileManager.default
        // Keep today and yesterday
        let today = dateFormatter.string(from: Date())
        let yesterday = dateFormatter.string(from: Date().addingTimeInterval(-86400))
        let keepSet: Set<String> = [
            "SittingMonitor-\(today).log",
            "SittingMonitor-\(yesterday).log"
        ]

        guard let files = try? fm.contentsOfDirectory(atPath: docsDir.path) else { return }
        for file in files {
            if file.hasPrefix("SittingMonitor-") && file.hasSuffix(".log") && !keepSet.contains(file) {
                try? fm.removeItem(at: docsDir.appendingPathComponent(file))
            }
        }
    }
}
