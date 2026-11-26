import Foundation
import XCTest
import LightingCore
#if canImport(KeyAndFill)
@testable import KeyAndFill
#else
@testable import StudioComposition
#endif

@MainActor
final class StudioFeatureWindowTests: XCTestCase {
    func testTwoWindowsKeepRoomOwnersThroughCompetingSaveAndRetireOnlyRecoveredWindow() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let disk = ProjectLibraryFileStore(directory: directory.appendingPathComponent("KeyAndFill"))
        let original = LightingScene.portrait()
        let shared = try ProjectLibrary(name: "Shared setup", scene: original)
        try disk.save(shared, replacing: nil)
        let first = StudioSession(store: ProjectStore(applicationSupportDirectory: directory,
                                                       arguments: [], environment: [:]))
        let second = StudioSession(store: ProjectStore(applicationSupportDirectory: directory,
                                                        arguments: [], environment: [:]))
        try await first.beginLibraryOperation(.load, from: first.generation).value
        try await second.beginLibraryOperation(.load, from: second.generation).value
        XCTAssertEqual(first.library, shared)
        XCTAssertEqual(second.library, shared)
        XCTAssertEqual(first.scene, original)
        XCTAssertEqual(second.scene, original)
        XCTAssertEqual(first.scene.lights.map(\.id), second.scene.lights.map(\.id))
        XCTAssertNotEqual(first.generation, second.generation)
        XCTAssertNotEqual(first.workspaceResetID, second.workspaceResetID)
        XCTAssertNotEqual(first.editOwner("room.width"), second.editOwner("room.width"))

        let firstContext = try XCTUnwrap(first.openFeature(.room, from: first.generation))
        let secondContext = try XCTUnwrap(second.openFeature(.room, from: second.generation))
        XCTAssertEqual(firstContext.scene, secondContext.scene)
        XCTAssertEqual(firstContext.generation, first.workspaceResetID)
        XCTAssertEqual(secondContext.generation, second.workspaceResetID)
        XCTAssertNotEqual(firstContext.id, secondContext.id)
        XCTAssertNotEqual(firstContext.owner, secondContext.owner)
        let firstRoom = ManualRoom(widthMeters: 7, depthMeters: 8, subjectX: 3, subjectZ: 2,
                                   yawDegrees: 15, ceilingHeightMeters: 3)
        let secondRoom = ManualRoom(widthMeters: 9, depthMeters: 10, subjectX: 4, subjectZ: 3,
                                    yawDegrees: -20, ceilingHeightMeters: 4)

        // Equal project and light identities do not authorize another window's callbacks.
        let firstOpenedEditor = first.editor
        let secondOpenedEditor = second.editor
        let firstOpenedFeature = first.feature
        let secondOpenedFeature = second.feature
        XCTAssertFalse(first.acceptsFeature(secondContext))
        XCTAssertFalse(second.acceptsFeature(firstContext))
        XCTAssertFalse(first.applyFeatureRoom(secondRoom, from: secondContext))
        XCTAssertFalse(second.applyFeatureRoom(firstRoom, from: firstContext))
        first.retireFeature(secondContext)
        first.finishFeature(secondContext)
        second.retireFeature(firstContext)
        second.finishFeature(firstContext)
        XCTAssertEqual(first.editor, firstOpenedEditor)
        XCTAssertEqual(second.editor, secondOpenedEditor)
        XCTAssertEqual(first.feature, firstOpenedFeature)
        XCTAssertEqual(second.feature, secondOpenedFeature)

        // The second window has an unsaved, still-presented measurement when the first saves.
        XCTAssertTrue(second.applyFeatureRoom(secondRoom, from: secondContext))
        let secondPendingEditor = second.editor
        let secondPendingFeature = second.feature
        let secondGeneration = second.generation
        XCTAssertTrue(second.history.isEditing)
        XCTAssertTrue(first.applyFeatureRoom(firstRoom, from: firstContext))
        try await first.beginLibraryOperation(.save, from: first.generation).value
        let firstSavedEditor = first.editor
        let firstSavedLibrary = try XCTUnwrap(first.library)
        let firstSavedFeature = first.feature
        let firstGeneration = first.generation
        let firstWorkspace = first.workspaceResetID
        XCTAssertEqual(first.saved, first.scene)
        XCTAssertEqual(first.scene.placementRoom, firstRoom)
        XCTAssertTrue(first.acceptsFeature(firstContext))
        XCTAssertEqual(second.editor, secondPendingEditor)
        XCTAssertEqual(second.feature, secondPendingFeature)
        XCTAssertEqual(second.saved, original)
        XCTAssertEqual(second.library, shared)
        XCTAssertEqual(second.generation, secondGeneration)
        XCTAssertEqual(second.workspaceResetID, secondContext.generation)
        XCTAssertTrue(second.acceptsFeature(secondContext))
        XCTAssertEqual(try disk.load(), firstSavedLibrary)

        var continuedRoom = secondRoom
        continuedRoom.yawDegrees = -35
        let competingSave = try second.beginLibraryOperation(.save, from: secondGeneration)
        // Reservation closes the undo group, but keeps the live feature and its receipt.
        let secondReservedEditor = second.editor
        XCTAssertFalse(second.history.isEditing)
        XCTAssertTrue(second.isBusy)
        XCTAssertFalse(second.applyFeatureRoom(continuedRoom, from: secondContext))
        do {
            try await competingSave.value
            XCTFail("The second window must not overwrite the first window's saved room")
        } catch ProjectLibraryError.staleSnapshot { }
        XCTAssertEqual(second.editor, secondReservedEditor)
        XCTAssertEqual(second.scene.placementRoom, secondRoom)
        XCTAssertEqual(second.feature, secondPendingFeature)
        XCTAssertEqual(second.feature?.context, secondContext)
        XCTAssertEqual(second.feature?.acceptedRevision, second.revision)
        XCTAssertEqual(second.saved, original)
        XCTAssertEqual(second.library, shared)
        XCTAssertEqual(second.generation, secondGeneration)
        XCTAssertEqual(second.workspaceResetID, secondContext.generation)
        XCTAssertTrue(second.saveConflict)
        XCTAssertFalse(second.saveBlocked)
        XCTAssertFalse(second.isBusy)
        XCTAssertNil(second.operationTask)
        XCTAssertEqual(try disk.load(), firstSavedLibrary)

        // The exact pre-conflict owner can continue; reopening the sheet is unnecessary.
        XCTAssertTrue(second.acceptsFeature(secondContext))
        XCTAssertTrue(second.applyFeatureRoom(continuedRoom, from: secondContext))
        XCTAssertEqual(second.scene.placementRoom, continuedRoom)
        XCTAssertEqual(second.feature?.context, secondContext)
        XCTAssertEqual(second.feature?.acceptedRevision, second.revision)
        XCTAssertNotEqual(second.revision, secondReservedEditor.revision)
        XCTAssertTrue(second.history.isEditing)
        let recoveryScene = second.scene
        try await second.beginLibraryOperation(.recover(name: "Second window recovery", replacing: nil),
                                               from: secondGeneration).value
        XCTAssertEqual(second.scene, recoveryScene)
        XCTAssertEqual(second.saved, recoveryScene)
        XCTAssertNotEqual(second.library?.activeID, shared.activeID)
        XCTAssertNotEqual(second.generation, secondGeneration)
        XCTAssertNotEqual(second.workspaceResetID, secondContext.generation)
        XCTAssertNil(second.feature)
        XCTAssertFalse(second.history.isEditing)
        XCTAssertFalse(second.history.canUndo)
        XCTAssertFalse(second.history.canRedo)
        XCTAssertFalse(second.saveConflict)
        XCTAssertFalse(second.isBusy)
        XCTAssertNil(second.operationTask)

        let recoveredEditor = second.editor
        let nextContext = try XCTUnwrap(second.openFeature(.room, from: second.generation))
        XCTAssertNotEqual(nextContext.id, secondContext.id)
        XCTAssertFalse(second.acceptsFeature(secondContext))
        XCTAssertFalse(second.applyFeatureRoom(secondRoom, from: secondContext))
        second.retireFeature(secondContext)
        second.finishFeature(secondContext)
        XCTAssertEqual(second.editor, recoveredEditor)
        XCTAssertEqual(second.feature?.context, nextContext)
        XCTAssertTrue(second.acceptsFeature(nextContext))

        // Recovery changes only the second workspace and appends to the actual latest library.
        XCTAssertEqual(first.editor, firstSavedEditor)
        XCTAssertEqual(first.library, firstSavedLibrary)
        XCTAssertEqual(first.saved, firstSavedEditor.scene)
        XCTAssertEqual(first.feature, firstSavedFeature)
        XCTAssertEqual(first.generation, firstGeneration)
        XCTAssertEqual(first.workspaceResetID, firstWorkspace)
        XCTAssertTrue(first.acceptsFeature(firstContext))
        let stored = try XCTUnwrap(disk.load())
        XCTAssertEqual(stored, second.library)
        XCTAssertEqual(stored.projects.count, 2)
        XCTAssertEqual(stored.projects.first { $0.id == shared.activeID }, firstSavedLibrary.activeProject)
        XCTAssertEqual(stored.activeProject?.scene, recoveryScene)
        XCTAssertEqual(stored.activeProject?.name, "Second window recovery")
    }
}
