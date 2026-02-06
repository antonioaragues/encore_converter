import Foundation

struct ConversionEngine {

    let goEnc2lyPath: String
    let python3Path: String

    struct ConversionError: LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }

    /// Converts a single .enc file to .musicxml in the given output directory.
    /// Returns the path of the generated .musicxml file.
    func convert(sourceURL: URL, outputDirectory: URL) async throws -> URL {
        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        let lyURL = outputDirectory.appendingPathComponent("\(baseName).ly")
        let musicxmlURL = outputDirectory.appendingPathComponent("\(baseName).musicxml")

        // Step 1: .enc → .ly using go-enc2ly
        try await runEnc2Ly(source: sourceURL, output: lyURL)

        // Step 2: .ly → .musicxml using python3 -m ly musicxml
        try await runLy2MusicXML(source: lyURL, output: musicxmlURL)

        // Cleanup: remove intermediate .ly file
        try? FileManager.default.removeItem(at: lyURL)

        return musicxmlURL
    }

    private func runEnc2Ly(source: URL, output: URL) async throws {
        // go-enc2ly writes LilyPond to stdout
        let result = try await runProcess(
            executablePath: goEnc2lyPath,
            arguments: [source.path]
        )

        guard result.exitCode == 0 else {
            let errorInfo = result.stderr.isEmpty ? "Exit code \(result.exitCode)" : result.stderr
            throw ConversionError(message: "go-enc2ly error: \(errorInfo)")
        }

        guard !result.stdout.isEmpty else {
            let errorInfo = result.stderr.isEmpty ? "No output produced" : result.stderr
            throw ConversionError(message: "go-enc2ly no genero salida: \(errorInfo)")
        }

        guard let data = result.stdout.data(using: .utf8) else {
            throw ConversionError(message: "go-enc2ly produjo datos invalidos")
        }

        try data.write(to: output)
    }

    private func runLy2MusicXML(source: URL, output: URL) async throws {
        // python3 -m ly "musicxml" input.ly -o output.musicxml
        let result = try await runProcess(
            executablePath: python3Path,
            arguments: ["-m", "ly", "musicxml", source.path, "-o", output.path]
        )

        guard result.exitCode == 0 else {
            let errorInfo = result.stderr.isEmpty
                ? (result.stdout.isEmpty ? "Exit code \(result.exitCode)" : result.stdout)
                : result.stderr
            throw ConversionError(message: "ly musicxml error: \(errorInfo)")
        }

        // Verify output file was actually created
        guard FileManager.default.fileExists(atPath: output.path) else {
            // Include stdout which may contain warnings/errors from python-ly
            let info = result.stdout.isEmpty ? "Archivo de salida no generado" : result.stdout
            throw ConversionError(message: "ly musicxml: \(info)")
        }
    }

    private struct ProcessResult {
        let stdout: String
        let stderr: String
        let exitCode: Int32
    }

    private func runProcess(
        executablePath: String,
        arguments: [String]
    ) async throws -> ProcessResult {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: executablePath)
            process.arguments = arguments

            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe

            process.terminationHandler = { proc in
                let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
                let stderr = String(data: stderrData, encoding: .utf8) ?? ""

                let result = ProcessResult(
                    stdout: stdout,
                    stderr: stderr,
                    exitCode: proc.terminationStatus
                )

                continuation.resume(returning: result)
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: ConversionError(message: "No se pudo ejecutar \(executablePath): \(error.localizedDescription)"))
            }
        }
    }
}
