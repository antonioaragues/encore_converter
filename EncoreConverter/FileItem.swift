import Foundation
import SwiftUI

enum ConversionStatus: Equatable {
    case pending
    case converting
    case done
    case error(String)
}

struct FileItem: Identifiable {
    let id = UUID()
    let sourceURL: URL
    var status: ConversionStatus = .pending

    var fileName: String {
        sourceURL.lastPathComponent
    }

    var statusIcon: String {
        switch status {
        case .pending: return "circle"
        case .converting: return "arrow.triangle.2.circlepath"
        case .done: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        }
    }

    var statusColor: Color {
        switch status {
        case .pending: return .secondary
        case .converting: return .blue
        case .done: return .green
        case .error: return .red
        }
    }

    var errorMessage: String? {
        if case .error(let msg) = status { return msg }
        return nil
    }
}

@MainActor
class ConversionState: ObservableObject {
    @Published var files: [FileItem] = []
    @Published var outputDirectory: URL?
    @Published var isConverting = false
    @Published var isCancelled = false

    var completedCount: Int {
        files.filter { $0.status == .done }.count
    }

    var processedCount: Int {
        files.filter {
            if case .done = $0.status { return true }
            if case .error = $0.status { return true }
            return false
        }.count
    }

    var hasErrors: Bool {
        files.contains { if case .error = $0.status { return true } else { return false } }
    }

    func addFiles(_ urls: [URL]) {
        let encURLs = urls.filter { $0.pathExtension.lowercased() == "enc" }
        let existingPaths = Set(files.map { $0.sourceURL.path })
        let newFiles = encURLs
            .filter { !existingPaths.contains($0.path) }
            .map { FileItem(sourceURL: $0) }
        files.append(contentsOf: newFiles)
    }

    func removeFile(_ item: FileItem) {
        files.removeAll { $0.id == item.id }
    }

    func clearAll() {
        files.removeAll()
    }

    func updateStatus(for id: UUID, to status: ConversionStatus) {
        if let index = files.firstIndex(where: { $0.id == id }) {
            files[index].status = status
        }
    }

    func resetAll() {
        for i in files.indices {
            files[i].status = .pending
        }
        isCancelled = false
    }

    func cancelConversion() {
        isCancelled = true
    }
}
