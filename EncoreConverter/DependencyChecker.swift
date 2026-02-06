import Foundation

struct DependencyStatus {
    var goEnc2lyPath: String?
    var python3Path: String?
    var pythonLyInstalled: Bool = false

    var goEnc2lyAvailable: Bool { goEnc2lyPath != nil }
    var pythonLyAvailable: Bool { python3Path != nil && pythonLyInstalled }
    var allInstalled: Bool { goEnc2lyAvailable && pythonLyAvailable }
}

struct DependencyChecker {

    static func check() -> DependencyStatus {
        let goEnc2ly = findExecutable("go-enc2ly")
        let python3 = findExecutable("python3")
        let lyInstalled = checkPythonLy(python3Path: python3)
        return DependencyStatus(
            goEnc2lyPath: goEnc2ly,
            python3Path: python3,
            pythonLyInstalled: lyInstalled
        )
    }

    /// Checks that `python3 -m ly --version` works
    private static func checkPythonLy(python3Path: String?) -> Bool {
        guard let python3 = python3Path else { return false }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: python3)
        process.arguments = ["-m", "ly", "--version"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }

    private static func findExecutable(_ name: String) -> String? {
        // Check common locations first
        let commonPaths = [
            "\(NSHomeDirectory())/go/bin/\(name)",
            "/usr/local/bin/\(name)",
            "/opt/homebrew/bin/\(name)",
            "/usr/local/go/bin/\(name)",
            "\(NSHomeDirectory())/.local/bin/\(name)",
            "/usr/bin/\(name)",
        ]

        for path in commonPaths {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }

        // Try `which` as fallback
        return whichExecutable(name)
    }

    private static func whichExecutable(_ name: String) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-l", "-c", "which \(name)"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
                if let path, !path.isEmpty {
                    return path
                }
            }
        } catch {
            // Silently fail
        }

        return nil
    }
}
