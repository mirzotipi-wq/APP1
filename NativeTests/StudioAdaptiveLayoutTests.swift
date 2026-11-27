import SwiftUI
import UIKit
import XCTest
@testable import KeyAndFill

@MainActor
final class StudioAdaptiveLayoutTests: XCTestCase {
    func testNestedLayoutsRetainChildStateThroughWidthForcedColumnAndAccessibilityChanges() async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive },
            "This regression requires a real app-hosted foreground scene")
        let previousKeyWindow = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(x: 0, y: 0, width: 1_800, height: 1_800)
        let configuration = Configuration()
        let host = UIHostingController(rootView: Fixture(configuration: configuration))
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer {
            window.isHidden = true
            window.rootViewController = nil
            previousKeyWindow?.makeKeyAndVisible()
        }

        let phases: [Phase] = [
            .init(revision: 0, width: 900),
            .init(revision: 1, width: 160),
            .init(revision: 2, width: 900),
            .init(revision: 3, width: 900, forceVertical: true),
            .init(revision: 4, width: 900),
            .init(revision: 5, width: 1_800, dynamicTypeSize: .accessibility5),
            .init(revision: 6, width: 160, dynamicTypeSize: .accessibility5),
            .init(revision: 7, width: 900)
        ]
        var observations: [Snapshot] = []
        let pixel = 1 / scene.screen.scale
        for phase in phases {
            configuration.phase = phase
            let snapshot = try await observe(phase, host: host, window: window)
            observations.append(snapshot)
            XCTAssertEqual(snapshot.identities.count, 3, "Each stateful child must be mounted")
            XCTAssertEqual(Set(snapshot.identities.values).count, 3,
                           "The three children must own distinct State locations")
            XCTAssertEqual(snapshot.identities, observations[0].identities,
                           "Phase \(phase.revision) replaced a child's installed @State")
            assertGeometry(snapshot, phase: phase, pixel: pixel)
        }

        // Compare actual Text bounds, not a padded control or a copied text
        // measuring algorithm. The narrow column must allow multiline content.
        for role in [Role.heading, .tools] {
            XCTAssertGreaterThan(observations[1].frame(role).height,
                                 observations[0].frame(role).height + pixel,
                                 "Narrow \(role) text must wrap instead of clipping")
            XCTAssertGreaterThan(observations[5].frame(role).height,
                                 observations[4].frame(role).height + pixel,
                                 "The real accessibility environment must grow \(role) text")
            XCTAssertGreaterThan(observations[6].frame(role).height,
                                 observations[5].frame(role).height + pixel,
                                 "Accessibility text must still wrap at narrow widths")
            XCTAssertEqual(observations[7].frame(role).height,
                           observations[0].frame(role).height, accuracy: pixel)
        }
    }

    private func observe(_ phase: Phase, host: UIHostingController<Fixture>,
                         window: UIWindow) async throws -> Snapshot {
        var current: [Role: Sample] = [:]
        // Explicit layout/main-queue turns, with a bounded pass count, let
        // SwiftUI commit both the environment update and its UIKit placement.
        // No timer or arbitrary sleep determines when an assertion may pass.
        for pass in 0..<12 {
            await withCheckedContinuation { continuation in
                DispatchQueue.main.async { continuation.resume() }
            }
            window.setNeedsLayout()
            window.layoutIfNeeded()
            host.view.setNeedsLayout()
            host.view.layoutIfNeeded()
            let views = probes(in: host.view)
            current = [:]
            for role in Role.allCases {
                let matches = views.filter {
                    $0.role == role && $0.revision == phase.revision &&
                    $0.dynamicTypeSize == phase.dynamicTypeSize && $0.window === window
                }
                guard matches.count == 1, let view = matches.first else { continue }
                // Read the attached UIView now. An ancestor can move it
                // without another updateUIView or layoutSubviews callback.
                let frame = view.convert(view.bounds, to: host.view)
                guard frame.minX.isFinite, frame.minY.isFinite,
                      frame.width.isFinite, frame.height.isFinite,
                      frame.width > 0, frame.height > 0 else { continue }
                current[role] = Sample(frame: frame, identity: view.identity)
            }
            if pass >= 2, views.count == Role.allCases.count,
               current.count == Role.allCases.count,
               let header = current[.header], abs(header.frame.width - phase.width) < 0.01 {
                return Snapshot(samples: current)
            }
        }
        XCTFail("Phase \(phase.revision) did not mount one current, finite probe per role; saw \(current.keys)")
        throw ObservationFailure.incompleteLayout
    }

    private func assertGeometry(_ snapshot: Snapshot, phase: Phase, pixel: CGFloat,
                                file: StaticString = #filePath, line: UInt = #line) {
        let header = snapshot.frame(.header)
        let headingSlot = snapshot.frame(.headingSlot)
        let actions = snapshot.frame(.actions)
        let projects = snapshot.frame(.projects)
        let tools = snapshot.frame(.tools)
        XCTAssertEqual(header.width, phase.width, accuracy: pixel, file: file, line: line)
        for role in Role.allCases where role != .header {
            XCTAssertTrue(header.insetBy(dx: -pixel, dy: -pixel).contains(snapshot.frame(role)),
                          "Phase \(phase.revision): \(role) escaped the allocated layout", file: file, line: line)
        }
        XCTAssertTrue(headingSlot.insetBy(dx: -pixel, dy: -pixel).contains(snapshot.frame(.heading)),
                      file: file, line: line)
        for frame in [projects, tools] {
            XCTAssertTrue(actions.insetBy(dx: -pixel, dy: -pixel).contains(frame), file: file, line: line)
        }
        let outerColumn = phase.width == 160 || phase.forceVertical || phase.dynamicTypeSize.isAccessibilitySize
        if outerColumn {
            XCTAssertEqual(actions.minY - headingSlot.maxY, 8, accuracy: pixel, file: file, line: line)
            XCTAssertEqual(actions.minX, headingSlot.minX, accuracy: pixel, file: file, line: line)
        } else {
            XCTAssertEqual(actions.minX - headingSlot.maxX, 8, accuracy: pixel, file: file, line: line)
            XCTAssertEqual(actions.midY, headingSlot.midY, accuracy: pixel, file: file, line: line)
            XCTAssertEqual(actions.maxX, header.maxX, accuracy: pixel,
                           "The flexible heading must keep wide-row actions trailing", file: file, line: line)
        }
        // The inner actions remain governed by width, even when the outer
        // header is forced into a column. Both supplied wide sizes fit them.
        if phase.width == 160 {
            XCTAssertEqual(tools.minY - projects.maxY, 8, accuracy: pixel, file: file, line: line)
            XCTAssertEqual(tools.minX, projects.minX, accuracy: pixel, file: file, line: line)
        } else {
            XCTAssertEqual(tools.minX - projects.maxX, 8, accuracy: pixel, file: file, line: line)
            XCTAssertEqual(tools.midY, projects.midY, accuracy: pixel, file: file, line: line)
        }
    }

    private func probes(in view: UIView) -> [GeometryView] {
        (view as? GeometryView).map { [$0] } ?? view.subviews.flatMap { probes(in: $0) }
    }

    private enum ObservationFailure: Error { case incompleteLayout }
    private enum Role: CaseIterable, Hashable { case header, headingSlot, heading, actions, projects, tools }

    private struct Phase {
        let revision: Int
        let width: CGFloat
        var forceVertical = false
        var dynamicTypeSize: DynamicTypeSize = .large
    }

    private struct Sample {
        let frame: CGRect
        let identity: UUID?
    }

    private struct Snapshot {
        // Constructed only after observe verifies every role exactly once.
        let samples: [Role: Sample]
        func frame(_ role: Role) -> CGRect { samples[role]!.frame }
        var identities: [Role: UUID] { samples.compactMapValues(\.identity) }
    }

    private final class Configuration: ObservableObject {
        @Published var phase = Phase(revision: 0, width: 900)
    }

    private struct Fixture: View {
        @ObservedObject var configuration: Configuration

        var body: some View {
            Header(phase: configuration.phase)
                .environment(\.dynamicTypeSize, configuration.phase.dynamicTypeSize)
                .environment(\.layoutDirection, .leftToRight)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .transaction { $0.animation = nil }
        }
    }

    private struct Header: View {
        @Environment(\.dynamicTypeSize) private var dynamicTypeSize
        let phase: Phase

        var body: some View {
            let forceVertical = phase.forceVertical || dynamicTypeSize.isAccessibilitySize
            // Match StudioView's header/action nesting and flexible heading.
            // The tested helper is imported from the app, never reimplemented.
            StudioAdaptiveLayout(forceVertical: forceVertical) {
                StatefulText(role: .heading, title: "Portrait session lighting setup", revision: phase.revision)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(GeometryProbe(role: .headingSlot, revision: phase.revision))
                StudioAdaptiveLayout() {
                    StatefulText(role: .projects, title: "Projects", revision: phase.revision)
                    StatefulText(role: .tools, title: "Export lighting plan and equipment", revision: phase.revision)
                }
                .background(GeometryProbe(role: .actions, revision: phase.revision))
            }
            .frame(width: phase.width, alignment: .leading)
            .background(GeometryProbe(role: .header, revision: phase.revision))
        }
    }

    private struct StatefulText: View {
        let role: Role
        let title: String
        let revision: Int
        @State private var identity = UUID()

        var body: some View {
            Text(title)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
                .background(GeometryProbe(role: role, revision: revision, identity: identity))
        }
    }

    private final class GeometryView: UIView {
        var role: Role?
        var revision = -1
        var identity: UUID?
        var dynamicTypeSize: DynamicTypeSize = .large
    }

    private struct GeometryProbe: UIViewRepresentable {
        let role: Role
        let revision: Int
        var identity: UUID? = nil

        func makeUIView(context: Context) -> GeometryView {
            let view = GeometryView()
            view.isUserInteractionEnabled = false
            view.isAccessibilityElement = false
            updateUIView(view, context: context)
            return view
        }

        func updateUIView(_ view: GeometryView, context: Context) {
            view.contentScaleFactor = context.environment.displayScale
            view.role = role
            view.revision = revision
            view.identity = identity
            view.dynamicTypeSize = context.environment.dynamicTypeSize
        }

        func sizeThatFits(_ proposal: ProposedViewSize, uiView: GeometryView, context: Context) -> CGSize? {
            guard let width = proposal.width, let height = proposal.height,
                  width.isFinite, height.isFinite, width >= 0, height >= 0 else { return nil }
            return CGSize(width: width, height: height)
        }
    }
}
