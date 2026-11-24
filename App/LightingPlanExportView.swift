import CoreTransferable
import PDFKit
import SwiftUI
import UniformTypeIdentifiers
import LightingCore

struct LightingPlanPDFItem: Transferable, Sendable {
    let data: Data
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .pdf) { item in item.data }
            .suggestedFileName("Key-and-Fill-lighting-plan.pdf")
    }
}

/// Snapshot is captured from the current editor; no project save is required to export.
struct LightingPlanExportMenu: View {
    let scene: LightingScene
    let title: String
    let textSettings: String?
    @State private var snapshot: LightingPlanExportSnapshot?

    var body: some View {
        Button {
            snapshot = .init(name: title, scene: scene, textSettings: textSettings)
        } label: {
            Image(systemName: "square.and.arrow.up").font(.headline).frame(width: 44, height: 44)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .accessibilityLabel("Export lighting plan")
        .accessibilityIdentifier("exportLightingPlan")
        .sheet(item: $snapshot) { snapshot in
            LightingPlanExportFlow(snapshot: snapshot).id(snapshot.id)
        }
    }
}

private struct LightingPlanExportSnapshot: Identifiable {
    let id = UUID()
    let name: String
    let scene: LightingScene
    let textSettings: String?
}

/// One stable sheet owns the format choice and the chosen document screen.
/// Format buttons change its content, avoiding a Menu dismissal racing a new
/// sheet presentation. The item and its scene remain unchanged until dismissal.
private struct LightingPlanExportFlow: View {
    let snapshot: LightingPlanExportSnapshot
    @Environment(\.dismiss) private var dismiss
    @State private var destination = Destination.formats

    private enum Destination { case formats, pdf, editableCopy }

    var body: some View {
        switch destination {
        case .formats:
            NavigationStack {
                Form {
                    Section("Lighting setup") {
                        Text(StudioDisplayName.label(snapshot.name, fallback: "Unnamed project"))
                            .font(.headline)
                            .accessibilityIdentifier("exportSnapshotProjectName")
                        Label("\(snapshot.scene.lights.count) lights", systemImage: "lightbulb")
                            .accessibilityIdentifier("exportSnapshotLightCount")
                    }
                    Section {
                        Button("Lighting plan (PDF)", systemImage: "doc.richtext") { destination = .pdf }
                            .frame(minHeight: 44)
                            .accessibilityIdentifier("prepareLightingPlanPDF")
                        Button("Editable project copy", systemImage: "doc.badge.arrow.up") { destination = .editableCopy }
                            .frame(minHeight: 44)
                            .accessibilityIdentifier("prepareEditableProjectCopy")
                        if let textSettings = snapshot.textSettings {
                            ShareLink(item: textSettings) {
                                Label("Share text settings", systemImage: "text.alignleft")
                                    .frame(minHeight: 44)
                            }
                        }
                    } footer: {
                        Text("Export includes your current studio settings and unsaved changes. Your project and edit history stay unchanged.")
                    }
                }
                .navigationTitle("Export lighting plan")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                            .accessibilityIdentifier("closeLightingPlanExportFormats")
                    }
                }
            }
        case .pdf:
            LightingPlanExportView(scene: snapshot.scene, title: snapshot.name)
        case .editableCopy:
            ProjectBackupView(name: snapshot.name, scene: snapshot.scene)
        }
    }
}

struct LightingPlanExportView: View {
    let scene: LightingScene
    let title: String
    @Environment(\.dismiss) private var dismiss
    @State private var units: PlanUnits
    @State private var paper = PlanPaper.letter
    @State private var prepared: Prepared?
    @State private var failed = false
    @State private var retry = 0

    init(scene: LightingScene, title: String) {
        self.scene = scene
        self.title = title
        // Start with the studio preference, then keep this export's picker
        // independent so choosing another report unit does not edit settings.
        let storedUnits = StudioPreferences.defaults.string(forKey: StudioPreferences.unitsKey)
            ?? PlanUnits.metric.rawValue
        _units = State(initialValue: StudioPreferences.units(from: storedUnits))
    }

    private struct Options: Equatable { let units: PlanUnits; let paper: PlanPaper; let retry: Int }
    private struct Prepared { let options: Options; let item: LightingPlanPDFItem; let pages: Int }
    private var options: Options { .init(units: units, paper: paper, retry: retry) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                HStack {
                    Picker("Paper", selection: $paper) {
                        ForEach(PlanPaper.allCases, id: \.self) { Text($0.title).tag($0) }
                    }.accessibilityIdentifier("exportPaper")
                    Spacer()
                    Picker("Units", selection: $units) {
                        Text("Meters").tag(PlanUnits.metric)
                        Text("Feet").tag(PlanUnits.imperial)
                    }.accessibilityIdentifier("exportUnits")
                }.padding(.horizontal)
                if let prepared, prepared.options == options {
                    LightingPlanPDFPreview(data: prepared.item.data)
                        .accessibilityLabel("Lighting plan PDF preview")
                        .accessibilityIdentifier("lightingPlanPDFPreview")
                    Text("\(prepared.pages) pages · Vector diagram & equipment list")
                        .font(.footnote).foregroundStyle(.secondary)
                        .accessibilityIdentifier("lightingPlanPDFPages")
                    ShareLink(item: prepared.item, preview: SharePreview("Key & Fill lighting plan")) {
                        Label("Share PDF", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }.buttonStyle(.borderedProminent).padding(.horizontal)
                        .accessibilityIdentifier("shareLightingPlanPDF")
                } else if failed {
                    ContentUnavailableView {
                        Label("PDF could not be created", systemImage: "doc.text")
                    } description: {
                        Text("Your project has not been changed.")
                    } actions: {
                        Button("Try again") { retry += 1 }
                    }
                } else {
                    Spacer(); ProgressView("Preparing lighting plan"); Spacer()
                }
                Text("Only scene settings and geometry are included. No reference photos or network processing.")
                    .font(.footnote).foregroundStyle(.secondary).padding([.horizontal, .bottom])
            }
            .navigationTitle("Export lighting plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .accessibilityIdentifier("closeLightingPlanPDF")
                }
            }
            .task(id: options) { await prepare(options) }
        }
    }

    @MainActor private func prepare(_ selection: Options) async {
        prepared = nil; failed = false
        await Task.yield()
        guard !Task.isCancelled, selection == options else { return }
        do {
            let plan = try LightingPlan(scene: scene, title: title, units: selection.units, paper: selection.paper)
            let data = try LightingPlanPDF.make(plan)
            guard !Task.isCancelled, selection == options else { return }
            prepared = Prepared(options: selection, item: .init(data: data), pages: plan.pageCount)
        } catch {
            if !Task.isCancelled, selection == options { failed = true }
        }
    }
}

private struct LightingPlanPDFPreview: UIViewRepresentable {
    let data: Data
    final class Coordinator { var data: Data? }
    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.backgroundColor = .secondarySystemBackground
        return view
    }
    func updateUIView(_ view: PDFView, context: Context) {
        guard context.coordinator.data != data else { return }
        view.document = PDFDocument(data: data)
        view.autoScales = true
        context.coordinator.data = data
    }
}
