import LightingCore
import SwiftUI
import UIKit

/// Session-only text. This flow has no store, project, photo, log, or network access.
struct BetaFeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var problem = BetaFeedbackReport.NoteDraft()
    @State private var reproductionSteps = BetaFeedbackReport.NoteDraft()
    @State private var expectedResult = BetaFeedbackReport.NoteDraft()
    @State private var showDiscardConfirmation = false
    @State private var reviewedReport: BetaFeedbackReport?
    @State private var showReport = false

    private static let lengthErrorMessage = "That entry is too long. Your previous text was kept. Edit it or choose to keep it before reviewing the report."

    private let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    private let buildVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
    private let sourceRevision = BetaFeedbackReport.validatedSourceRevision(
        Bundle.main.object(forInfoDictionaryKey: "KEYFILL_SOURCE_REVISION") as? String
    )
    private let osVersion = ProcessInfo.processInfo.operatingSystemVersion

    var body: some View {
        NavigationStack {
            Form {
                Section { draftHeading }
                Section("What will be shared") {
                    Text(BetaFeedbackReport.contentsNotice)
                    if sourceRevision != nil {
                        Text(BetaFeedbackReport.sourceRevisionNotice)
                    }
                    Text("Your draft stays in memory while this sheet is open. Closing it discards your notes. You choose the destination in the system share sheet; nothing is sent automatically.")
                }
                Section {
                    noteEditor("What happened? Which screen or action?", draft: $problem,
                               label: "Problem or observation, optional", identifier: "betaFeedbackProblem")
                } header: {
                    Text("Problem or observation (optional)")
                }
                Section {
                    noteEditor("1. Open…\n2. Choose…\n3. Observe…", draft: $reproductionSteps,
                               label: "Steps to reproduce, optional", identifier: "betaFeedbackSteps")
                } header: {
                    Text("Steps to reproduce (optional)")
                }
                Section {
                    noteEditor("What did you expect to happen?", draft: $expectedResult,
                               label: "Expected result, optional", identifier: "betaFeedbackExpectedResult")
                } header: {
                    Text("Expected result (optional)")
                } footer: {
                    Text("Keep notes brief. Long text is shortened in the report with a notice. Review the complete report before sharing. Do not include private photographs, project details or personal information in your notes.")
                }
                Section {
                    Button {
                        guard !hasLengthErrors else { return }
                        // Freeze the reviewed value. A later text-field callback
                        // cannot change either the preview or its shared payload.
                        reviewedReport = report
                        showReport = true
                    } label: {
                        Label("Review report", systemImage: "doc.text.magnifyingglass")
                    }
                    .disabled(hasLengthErrors)
                    .accessibilityIdentifier("reviewBetaFeedback")
                    .accessibilityHint("Shows the exact text available to share. All notes are optional.")
                }
                Section("Simulation and calibration") {
                    Text(BetaFeedbackReport.simulationNotice)
                }
            }
            .navigationTitle("Beta feedback")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showReport) {
                if let reviewedReport {
                    BetaFeedbackPreview(report: reviewedReport)
                }
            }
            .confirmationDialog("Discard this feedback draft?", isPresented: $showDiscardConfirmation,
                                titleVisibility: .visible) {
                Button("Discard draft", role: .destructive) {
                    problem = .init()
                    reproductionSteps = .init()
                    expectedResult = .init()
                    reviewedReport = nil
                    dismiss()
                }
                Button("Keep editing", role: .cancel) { }
            } message: {
                Text("Your notes are not saved. Any copy you already shared stays with its chosen destination.")
            }
        }
        .interactiveDismissDisabled(hasNotes)
        .tint(StudioPalette.action)
    }

    /// Match the other editing sheets: Form controls can grow and scroll at
    /// accessibility text sizes without the navigation bar's fixed height.
    private var draftHeading: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(alignment: .center, spacing: 12))
        return layout {
            Text("Feedback draft")
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)
            Button {
                if hasNotes { showDiscardConfirmation = true } else { dismiss() }
            } label: {
                Text("Close")
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .accessibilityIdentifier("closeBetaFeedback")
        }
    }

    @ViewBuilder
    private func noteEditor(_ prompt: String, draft: Binding<BetaFeedbackReport.NoteDraft>,
                            label: String, identifier: String) -> some View {
        TextField(prompt, text: Binding(
            get: { draft.wrappedValue.text },
            set: { draft.wrappedValue.replaceText(with: $0) }
        ), axis: .vertical)
        .lineLimit(3...8)
        .accessibilityLabel(Text(label))
        .accessibilityIdentifier(identifier)
        .accessibilityHint(Text(draft.wrappedValue.hasLengthError ? Self.lengthErrorMessage : "Enter a brief note. All notes are optional."))
        if draft.wrappedValue.hasLengthError {
            Label(Self.lengthErrorMessage, systemImage: "exclamationmark.triangle")
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier(identifier + "LengthError")
            Button {
                draft.wrappedValue.keepPreviousText()
            } label: {
                Text(draft.wrappedValue.text.isEmpty ? "Keep field blank" : "Keep previous text")
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .accessibilityIdentifier(identifier + "KeepPrevious")
        }
    }

    private var hasLengthErrors: Bool {
        problem.hasLengthError || reproductionSteps.hasLengthError || expectedResult.hasLengthError
    }

    private var hasNotes: Bool {
        !problem.text.isEmpty || !reproductionSteps.text.isEmpty || !expectedResult.text.isEmpty
    }

    private var report: BetaFeedbackReport {
        let family: BetaFeedbackReport.DeviceFamily
        switch UIDevice.current.userInterfaceIdiom {
        case .phone: family = .iPhone
        case .pad: family = .iPad
        default: family = .other
        }
        return BetaFeedbackReport(appVersion: appVersion, buildVersion: buildVersion,
                                  operatingSystemVersion: "\(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)",
                                  deviceFamily: family, problem: problem.text,
                                  reproductionSteps: reproductionSteps.text, expectedResult: expectedResult.text,
                                  sourceRevision: sourceRevision)
    }
}

private struct BetaFeedbackPreview: View {
    let report: BetaFeedbackReport

    var body: some View {
        Form {
            Section {
                Text("Review the complete text below. Share report opens system sharing so you can choose a destination. Key & Fill does not choose a recipient or send this draft automatically.")
                if !report.shortenedFields.isEmpty {
                    Text("Text was shortened in: \(report.shortenedFields.map(\.rawValue).joined(separator: ", ")). Go back to edit your notes if needed.")
                        .accessibilityIdentifier("betaFeedbackShortenedNotice")
                }
                if !report.cleanedFields.isEmpty {
                    Text("Some spacing or hidden control characters were cleaned up in: \(report.cleanedFields.map(\.rawValue).joined(separator: ", ")). The text below is the exact report that will be shared.")
                }
            }
            Section("Report preview") {
                Text(report.plainText)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("betaFeedbackReportText")
            }
            Section {
                ShareLink(item: report.plainText, subject: Text("Key & Fill beta feedback")) {
                    Label("Share report", systemImage: "square.and.arrow.up")
                }
                .accessibilityIdentifier("shareBetaFeedbackReport")
                .accessibilityHint("Opens the system share sheet. Choose a destination or cancel.")
            }
        }
        .navigationTitle("Review report")
        .navigationBarTitleDisplayMode(.inline)
    }
}
