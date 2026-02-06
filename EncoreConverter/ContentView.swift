import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var state = ConversionState()
    @State private var dependencyStatus: DependencyStatus?
    @State private var isDropTargeted = false
    @State private var errorPopoverFileId: UUID?

    var body: some View {
        VStack(spacing: 0) {
            // Dependency warning banner
            if let status = dependencyStatus, !status.allInstalled {
                dependencyBanner(status)
            }

            // Drop zone + file list
            dropZoneAndList
                .padding()

            Divider()

            // Bottom toolbar
            bottomBar
                .padding()
        }
        .frame(minWidth: 500, minHeight: 400)
        .onAppear {
            dependencyStatus = DependencyChecker.check()
        }
    }

    // MARK: - Dependency Banner

    private func dependencyBanner(_ status: DependencyStatus) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Faltan dependencias", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundColor(.orange)

            if !status.goEnc2lyAvailable {
                Text("go-enc2ly no encontrado. Instalar con: go install github.com/hanwen/go-enc2ly@latest")
                    .font(.caption)
                    .textSelection(.enabled)
            }
            if !status.pythonLyAvailable {
                Text("python-ly no encontrado. Instalar con: pip3 install python-ly")
                    .font(.caption)
                    .textSelection(.enabled)
            }

            Button("Comprobar de nuevo") {
                dependencyStatus = DependencyChecker.check()
            }
            .font(.caption)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1))
    }

    // MARK: - Drop Zone and File List

    private var dropZoneAndList: some View {
        Group {
            if state.files.isEmpty {
                emptyDropZone
            } else {
                fileList
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
            handleDrop(providers)
            return true
        }
    }

    private var emptyDropZone: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(isDropTargeted ? .accentColor : .secondary)

            Text("Arrastra archivos .enc aqui")
                .font(.title2)
                .foregroundColor(.secondary)

            Text("o pulsa para seleccionar")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    style: StrokeStyle(lineWidth: 2, dash: [8])
                )
                .foregroundColor(isDropTargeted ? .accentColor : .secondary.opacity(0.4))
        )
        .contentShape(Rectangle())
        .onTapGesture {
            selectFiles()
        }
    }

    private var fileList: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("\(state.files.count) archivo(s)")
                    .font(.headline)
                Spacer()
                Button("Anadir archivos") {
                    selectFiles()
                }
                Button("Limpiar lista") {
                    state.clearAll()
                }
                .disabled(state.isConverting)
            }
            .padding(.bottom, 8)

            // File list
            List {
                ForEach(state.files) { item in
                    fileRow(item)
                }
                .onDelete { indexSet in
                    if !state.isConverting {
                        state.files.remove(atOffsets: indexSet)
                    }
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
        }
    }

    private func fileRow(_ item: FileItem) -> some View {
        HStack {
            Image(systemName: item.statusIcon)
                .foregroundColor(item.statusColor)
                .frame(width: 20)

            if item.status == .converting {
                ProgressView()
                    .scaleEffect(0.5)
                    .frame(width: 16, height: 16)
            }

            Text(item.fileName)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            if let error = item.errorMessage {
                Button {
                    if errorPopoverFileId == item.id {
                        errorPopoverFileId = nil
                    } else {
                        errorPopoverFileId = item.id
                    }
                } label: {
                    Label("Error", systemImage: "exclamationmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .help("Pulsa para ver el error completo")
                .popover(isPresented: Binding(
                    get: { errorPopoverFileId == item.id },
                    set: { if !$0 { errorPopoverFileId = nil } }
                )) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Error en \(item.fileName)")
                                .font(.headline)
                            Spacer()
                            Button {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(error, forType: .string)
                            } label: {
                                Label("Copiar", systemImage: "doc.on.doc")
                                    .font(.caption)
                            }
                            .buttonStyle(.bordered)
                        }

                        ScrollView {
                            Text(error)
                                .font(.system(.caption, design: .monospaced))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 200)
                    }
                    .padding()
                    .frame(width: 450)
                }
            }

            if item.status == .done {
                Text("OK")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: 10) {
            // Row 1: Output folder
            HStack {
                Text("Carpeta destino:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(state.outputDirectory?.path ?? "Sin seleccionar")
                    .lineLimit(1)
                    .truncationMode(.head)
                    .foregroundColor(state.outputDirectory != nil ? .primary : .secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button("Seleccionar...") {
                    selectOutputFolder()
                }
            }

            // Row 2: Progress + action buttons (aligned right)
            HStack {
                // Progress (left side when converting)
                if state.isConverting {
                    ProgressView(
                        value: Double(state.processedCount),
                        total: Double(state.files.count)
                    )
                    .frame(maxWidth: 150)

                    Text("\(state.processedCount)/\(state.files.count)")
                        .font(.caption)
                        .monospacedDigit()
                }

                Spacer()

                // Stop button
                if state.isConverting {
                    Button(role: .destructive, action: {
                        state.cancelConversion()
                    }) {
                        Label("Parar", systemImage: "stop.fill")
                    }
                    .buttonStyle(.bordered)
                }

                // Convert button
                Button(action: startConversion) {
                    Label("Convertir", systemImage: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canConvert)
            }
        }
    }

    private var canConvert: Bool {
        !state.files.isEmpty &&
        state.outputDirectory != nil &&
        !state.isConverting &&
        (dependencyStatus?.allInstalled ?? false)
    }

    // MARK: - Actions

    private func selectFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [UTType(filenameExtension: "enc") ?? .data]
        panel.message = "Selecciona archivos Encore (.enc)"

        if panel.runModal() == .OK {
            state.addFiles(panel.urls)
        }
    }

    private func selectOutputFolder() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.message = "Selecciona la carpeta de destino"

        if panel.runModal() == .OK {
            state.outputDirectory = panel.url
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                DispatchQueue.main.async {
                    state.addFiles([url])
                }
            }
        }
    }

    private func startConversion() {
        guard let deps = dependencyStatus, deps.allInstalled,
              let outputDir = state.outputDirectory else { return }

        state.isConverting = true
        state.resetAll()

        let engine = ConversionEngine(
            goEnc2lyPath: deps.goEnc2lyPath!,
            python3Path: deps.python3Path!
        )

        Task {
            for i in state.files.indices {
                // Check cancellation before starting next file
                if state.isCancelled {
                    // Mark remaining files back to pending
                    for j in i..<state.files.count {
                        let remaining = state.files[j]
                        if case .pending = remaining.status {
                            // already pending, leave it
                        }
                    }
                    break
                }

                let file = state.files[i]
                state.updateStatus(for: file.id, to: .converting)

                do {
                    _ = try await engine.convert(
                        sourceURL: file.sourceURL,
                        outputDirectory: outputDir
                    )
                    state.updateStatus(for: file.id, to: .done)
                } catch {
                    if state.isCancelled {
                        state.updateStatus(for: file.id, to: .error("Cancelado por el usuario"))
                    } else {
                        state.updateStatus(for: file.id, to: .error(error.localizedDescription))
                    }
                }
            }
            state.isConverting = false
        }
    }
}
