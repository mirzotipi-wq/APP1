import XCTest
import LightingCore
@testable import KeyAndFill

final class StudioSliderTrackingTests: XCTestCase {
    private final class Editor {
        var scene = LightingScene.portrait()
        var history = SceneEditHistory()
        var generation = "A"
        var begins = 0
        var ends = 0
        var writes = 0
        var afterRead: (() -> Void)?
        var afterBegin: (() -> Void)?
        var afterEnd: (() -> Void)?
        var afterWrite: (() -> Void)?

        init(width: Double = 0.6) {
            scene.lights[0].optics = .init(kind: .rectangle, widthMeters: width)
        }

        var width: Double { scene.lights[0].effectiveOptics.widthMeters }

        func adapter() -> StudioSliderEditing {
            let captured = generation
            return StudioSliderEditing(read: {
                let value = self.width
                self.afterRead?()
                return value
            }, write: { value in
                guard self.generation == captured else { return }
                var optics = self.scene.lights[0].effectiveOptics
                optics.widthMeters = value
                guard optics.isValid, optics != self.scene.lights[0].effectiveOptics else { return }
                if !self.history.isEditing { self.history.record(previous: self.scene) }
                self.scene.lights[0].optics = optics
                self.writes += 1
                self.afterWrite?()
            }, onEditingChanged: { editing in
                if editing {
                    guard self.generation == captured else { return }
                    self.begins += 1
                    self.history.begin(scene: self.scene, owner: captured + ".width")
                    self.afterBegin?()
                } else {
                    self.ends += 1
                    self.history.end(scene: self.scene, owner: captured + ".width")
                    self.afterEnd?()
                }
            })
        }
    }

    private let mapping = StudioSliderMapping(bounds: 0.05...4, step: 0.05)!

    func testOutAndBackOptionalSettingsPreserveOriginalSceneAndRedo() throws {
        typealias Setting = (name: String, bounds: ClosedRange<Double>, step: Double,
                             read: (LightingScene) -> Double, write: (inout LightingScene, Double) -> Void)
        let settings: [Setting] = [
            ("exposure", -6...6, 0.25, { $0.effectivePreviewSettings.exposureStops }, { scene, value in
                var settings = scene.effectivePreviewSettings
                settings.exposureStops = value
                scene.previewSettings = settings
            }),
            ("whiteBalance", 2000...10000, 100, { $0.effectivePreviewSettings.whiteBalanceKelvin }, { scene, value in
                var settings = scene.effectivePreviewSettings
                settings.whiteBalanceKelvin = value
                scene.previewSettings = settings
            }),
            ("focalLength", 14...200, 1, { $0.effectiveCameraLens.focalLengthMillimeters }, { scene, value in
                scene.cameraLens = .init(focalLengthMillimeters: value)
            }),
            ("roll", -180...180, 1, { $0.lights[0].effectiveOptics.effectiveRollDegrees }, { scene, value in
                var optics = scene.lights[0].effectiveOptics
                optics.rollDegrees = value
                scene.lights[0].optics = optics
            })
        ]
        for setting in settings {
            for explicitDefaults in [false, true] {
                var scene = LightingScene.portrait()
                scene.lights[0].optics = .init(kind: .rectangle, rollDegrees: explicitDefaults ? 0 : nil)
                if explicitDefaults {
                    scene.previewSettings = .init()
                    scene.cameraLens = .init()
                }
                let original = scene
                var previousEdit = scene
                previousEdit.camera.x += 1
                var history = SceneEditHistory()
                history.record(previous: original)
                scene = try XCTUnwrap(history.undo(current: previousEdit))
                let adapter = StudioSliderEditing(read: { setting.read(scene) }, write: { value in
                    var next = scene
                    setting.write(&next, value)
                    scene = history.preservingOptionalRepresentations(in: next)
                }, onEditingChanged: { editing in
                    if editing { history.begin(scene: scene, owner: setting.name) }
                    else { history.end(scene: scene, owner: setting.name) }
                })
                let mapping = try XCTUnwrap(StudioSliderMapping(bounds: setting.bounds, step: setting.step))
                let originalDisplay = try XCTUnwrap(mapping.normalized(setting.read(scene)))
                let tracking = StudioSliderTracking()
                let token = try XCTUnwrap(tracking.begin(editing: adapter, mapping: mapping, displayedValue: originalDisplay))
                tracking.change(0.9, for: token)
                XCTAssertNotEqual(scene, original, setting.name)
                tracking.finish(token, finalDisplay: originalDisplay)
                XCTAssertEqual(scene, original, setting.name)
                XCTAssertFalse(history.canUndo, setting.name)
                XCTAssertFalse(history.isEditing, setting.name)
                XCTAssertEqual(history.redo(current: scene), previousEdit, setting.name)
            }
        }
    }

    func testFinalSampleBeforeEndRestoresWholeGestureAndKeepsEmitterCommand() throws {
        let editor = Editor(), tracking = StudioSliderTracking()
        var point = editor.scene
        point.lights[0].optics?.kind = .point
        editor.history.record(previous: point)
        let initial = editor.scene
        let token = try XCTUnwrap(tracking.begin(editing: editor.adapter(), mapping: mapping,
                                               displayedValue: mapping.normalized(editor.width)!))
        tracking.change(mapping.normalized(1.85)!, for: token)
        tracking.finish(token, finalDisplay: mapping.normalized(1.3)!)
        let edited = editor.scene
        XCTAssertEqual(editor.width, 1.3, accuracy: 1e-12)
        XCTAssertFalse(editor.history.isEditing)
        XCTAssertEqual(editor.ends, 1)
        XCTAssertEqual(editor.history.undo(current: edited), initial)
        XCTAssertEqual(editor.history.undo(current: initial), point)
        XCTAssertNil(editor.history.undo(current: point))
        XCTAssertEqual(editor.history.redo(current: point), initial)
        XCTAssertEqual(editor.history.redo(current: initial), edited)
    }

    func testValueAfterEndCannotReopenHistoryOrDisableUndo() throws {
        let editor = Editor(), tracking = StudioSliderTracking()
        let initial = editor.scene
        let token = try XCTUnwrap(tracking.begin(editing: editor.adapter(), mapping: mapping,
                                               displayedValue: mapping.normalized(editor.width)!))
        tracking.change(mapping.normalized(1.85)!, for: token)
        tracking.finish(token, finalDisplay: mapping.normalized(1.3)!)
        let final = editor.scene
        tracking.change(mapping.normalized(2)!, for: token)
        tracking.finish(token, finalDisplay: 1)
        XCTAssertEqual(editor.scene, final)
        XCTAssertFalse(editor.history.isEditing)
        XCTAssertTrue(editor.history.canUndo)
        XCTAssertEqual(editor.ends, 1)
        XCTAssertEqual(editor.history.undo(current: final), initial)
    }

    func testUnchangedThumbPreservesExactImportedDoubleAndRedo() throws {
        for width in [0.723456789, 3.12345678912345, 0.05, 4] {
            let editor = Editor(width: width), tracking = StudioSliderTracking()
            let initial = editor.scene
            editor.adapter().adjust(by: width == 0.05 ? 0.01 : -0.01, in: 0.05...10)
            let previousEdit = editor.scene
            editor.scene = try XCTUnwrap(editor.history.undo(current: previousEdit))
            let writes = editor.writes
            let display = mapping.normalized(editor.width)!
            let token = try XCTUnwrap(tracking.begin(editing: editor.adapter(), mapping: mapping,
                                                   displayedValue: display))
            tracking.change(display, for: token)
            tracking.finish(token, finalDisplay: display)
            XCTAssertEqual(editor.scene, initial)
            XCTAssertEqual(editor.width.bitPattern, width.bitPattern)
            XCTAssertEqual(editor.writes, writes)
            XCTAssertFalse(editor.history.isEditing)
            XCTAssertEqual(editor.history.redo(current: initial), previousEdit)
        }
    }

    func testReturnToStartingThumbRestoresExactOffGridValueWithoutHistory() throws {
        let editor = Editor(width: 0.723456789), tracking = StudioSliderTracking()
        let initial = editor.scene, display = mapping.normalized(editor.width)!
        let token = try XCTUnwrap(tracking.begin(editing: editor.adapter(), mapping: mapping,
                                               displayedValue: display))
        tracking.change(0.75, for: token)
        XCTAssertNotEqual(editor.scene, initial)
        tracking.finish(token, finalDisplay: display)
        XCTAssertEqual(editor.scene, initial)
        XCTAssertEqual(editor.width.bitPattern, 0.723456789.bitPattern)
        XCTAssertFalse(editor.history.canUndo)
        XCTAssertFalse(editor.history.isEditing)
    }

    func testNewSessionRetiresOldTokenAndKeepsGesturesSeparate() throws {
        let editor = Editor(), tracking = StudioSliderTracking()
        let initial = editor.scene
        let first = try XCTUnwrap(tracking.begin(editing: editor.adapter(), mapping: mapping,
                                               displayedValue: mapping.normalized(editor.width)!))
        tracking.change(mapping.normalized(1.3)!, for: first)
        let firstResult = editor.scene
        let second = try XCTUnwrap(tracking.begin(editing: editor.adapter(), mapping: mapping,
                                                displayedValue: mapping.normalized(editor.width)!))
        tracking.change(1, for: first)
        tracking.finish(first, finalDisplay: 1)
        XCTAssertEqual(editor.scene, firstResult)
        XCTAssertTrue(editor.history.isEditing)
        tracking.finish(second, finalDisplay: mapping.normalized(2)!)
        XCTAssertEqual(editor.history.undo(current: editor.scene), firstResult)
        XCTAssertEqual(editor.history.undo(current: firstResult), initial)
        XCTAssertEqual(editor.ends, 2)
    }

    func testSessionRetainsOriginalWriterAndRange() throws {
        let original = Editor(), replacement = Editor(width: 1.1)
        let tracking = StudioSliderTracking()
        let replacementInitial = replacement.scene
        var latestAdapter = original.adapter()
        var latestMapping = mapping
        let token = try XCTUnwrap(tracking.begin(editing: latestAdapter, mapping: latestMapping,
                                               displayedValue: latestMapping.normalized(original.width)!))
        latestAdapter = replacement.adapter()
        latestMapping = StudioSliderMapping(bounds: 0.1...2, step: 0.1)!
        tracking.finish(token, finalDisplay: 1)
        XCTAssertEqual(original.width, 4)
        XCTAssertEqual(replacement.scene, replacementInitial)
        let next = try XCTUnwrap(tracking.begin(editing: latestAdapter, mapping: latestMapping,
                                              displayedValue: latestMapping.normalized(replacement.width)!))
        tracking.finish(next, finalDisplay: 1)
        XCTAssertEqual(replacement.width, 2)
        XCTAssertEqual(original.width, 4)
    }

    func testReentrantBeginFromPreviousEndKeepsNewOwnerAndRetiresInterruptedToken() throws {
        let original = Editor(), interrupted = Editor(width: 0.8), replacement = Editor(width: 1.1)
        let tracking = StudioSliderTracking(), mapping = self.mapping
        let originalInitial = original.scene, replacementInitial = replacement.scene
        let first = try XCTUnwrap(tracking.begin(editing: original.adapter(), mapping: mapping,
                                               displayedValue: mapping.normalized(original.width)!))
        tracking.change(mapping.normalized(1.3)!, for: first)
        var replacementToken: StudioSliderTracking.Token?
        original.afterEnd = {
            replacementToken = tracking.begin(editing: replacement.adapter(), mapping: mapping,
                                              displayedValue: mapping.normalized(replacement.width)!)
        }

        let retired = try XCTUnwrap(tracking.begin(editing: interrupted.adapter(), mapping: mapping,
                                                 displayedValue: mapping.normalized(interrupted.width)!))
        let current = try XCTUnwrap(replacementToken)
        XCTAssertEqual(tracking.currentToken, current)
        XCTAssertNotEqual(retired, current)
        XCTAssertEqual(original.ends, 1)
        XCTAssertFalse(original.history.isEditing)
        XCTAssertEqual(original.history.undo(current: original.scene), originalInitial)
        XCTAssertEqual(interrupted.begins, 0)
        XCTAssertEqual(replacement.begins, 1)
        XCTAssertTrue(replacement.history.isEditing)

        for stale in [first, retired] {
            tracking.change(1, for: stale)
            tracking.finish(stale, finalDisplay: 1)
        }
        XCTAssertEqual(tracking.currentToken, current)
        XCTAssertEqual(original.ends, 1)
        XCTAssertEqual(interrupted.writes, 0)
        XCTAssertEqual(interrupted.ends, 0)
        XCTAssertEqual(replacement.scene, replacementInitial)
        XCTAssertEqual(replacement.ends, 0)

        tracking.finish(current, finalDisplay: mapping.normalized(1.85)!)
        XCTAssertEqual(replacement.width, 1.85, accuracy: 1e-12)
        XCTAssertEqual(replacement.ends, 1)
        XCTAssertFalse(replacement.history.isEditing)
        XCTAssertFalse(tracking.isTracking)
        XCTAssertEqual(replacement.history.undo(current: replacement.scene), replacementInitial)
    }

    func testReadThatFinishesSessionCannotReopenHistory() throws {
        let editor = Editor(), tracking = StudioSliderTracking()
        let initial = editor.scene
        let token = try XCTUnwrap(tracking.begin(editing: editor.adapter(), mapping: mapping,
                                               displayedValue: mapping.normalized(editor.width)!))
        editor.afterRead = { tracking.finish(token) }

        tracking.change(mapping.normalized(1.85)!, for: token)

        XCTAssertFalse(tracking.isTracking)
        XCTAssertFalse(editor.history.isEditing)
        XCTAssertEqual(editor.begins, 1)
        XCTAssertEqual(editor.ends, 1)
        XCTAssertEqual(editor.writes, 0)
        XCTAssertEqual(editor.scene, initial)
        XCTAssertFalse(editor.history.canUndo)
        tracking.finish(token, finalDisplay: 1)
        XCTAssertEqual(editor.begins, 1)
        XCTAssertEqual(editor.ends, 1)
    }

    func testReadThatReplacesSessionCannotReopenRetiredOwner() throws {
        let original = Editor(), replacement = Editor(width: 1.1)
        let tracking = StudioSliderTracking(), mapping = self.mapping
        let originalInitial = original.scene, replacementInitial = replacement.scene
        let retired = try XCTUnwrap(tracking.begin(editing: original.adapter(), mapping: mapping,
                                                 displayedValue: mapping.normalized(original.width)!))
        var replacementToken: StudioSliderTracking.Token?
        original.afterRead = {
            replacementToken = tracking.begin(editing: replacement.adapter(), mapping: mapping,
                                              displayedValue: mapping.normalized(replacement.width)!)
        }

        tracking.change(mapping.normalized(1.85)!, for: retired)

        let current = try XCTUnwrap(replacementToken)
        XCTAssertEqual(tracking.currentToken, current)
        XCTAssertNotEqual(current, retired)
        XCTAssertEqual(original.scene, originalInitial)
        XCTAssertEqual(original.begins, 1)
        XCTAssertEqual(original.ends, 1)
        XCTAssertEqual(original.writes, 0)
        XCTAssertFalse(original.history.isEditing)
        XCTAssertTrue(replacement.history.isEditing)
        XCTAssertEqual(replacement.begins, 1)
        XCTAssertEqual(replacement.ends, 0)
        tracking.change(1, for: retired)
        tracking.finish(retired, finalDisplay: 1)
        XCTAssertEqual(replacement.scene, replacementInitial)
        XCTAssertEqual(tracking.currentToken, current)

        tracking.finish(current, finalDisplay: mapping.normalized(1.8)!)
        XCTAssertFalse(tracking.isTracking)
        XCTAssertFalse(replacement.history.isEditing)
        XCTAssertEqual(replacement.ends, 1)
        XCTAssertEqual(replacement.history.undo(current: replacement.scene), replacementInitial)
    }

    func testCapturedGenerationCannotWriteOrCloseNewProjectEdit() throws {
        let editor = Editor(), old = StudioSliderTracking(), current = StudioSliderTracking()
        let oldToken = try XCTUnwrap(old.begin(editing: editor.adapter(), mapping: mapping,
                                              displayedValue: mapping.normalized(editor.width)!))
        old.change(mapping.normalized(1.3)!, for: oldToken)
        editor.history.end(scene: editor.scene) // Existing lifecycle force-close.
        editor.generation = "B"
        editor.scene.lights[0].optics?.widthMeters = 1.2
        editor.history.reset()
        let newInitial = editor.scene
        let currentToken = try XCTUnwrap(current.begin(editing: editor.adapter(), mapping: mapping,
                                                       displayedValue: mapping.normalized(editor.width)!))
        old.change(1, for: oldToken)
        old.finish(oldToken, finalDisplay: 1)
        XCTAssertEqual(editor.scene, newInitial)
        XCTAssertTrue(editor.history.isEditing, "Old owner end must not close the new project")
        current.finish(currentToken, finalDisplay: mapping.normalized(1.8)!)
        XCTAssertEqual(editor.history.undo(current: editor.scene), newInitial)
    }

    func testParentForceCloseKeepsSubsequentActiveValuesInOneOwnedEdit() throws {
        let editor = Editor(), tracking = StudioSliderTracking()
        let initial = editor.scene
        let token = try XCTUnwrap(tracking.begin(editing: editor.adapter(), mapping: mapping,
                                               displayedValue: mapping.normalized(editor.width)!))
        tracking.change(mapping.normalized(1.3)!, for: token)
        editor.history.end(scene: editor.scene)
        let boundary = editor.scene
        tracking.change(mapping.normalized(1.8)!, for: token)
        tracking.finish(token, finalDisplay: mapping.normalized(2)!)
        XCTAssertFalse(editor.history.isEditing)
        XCTAssertEqual(editor.history.undo(current: editor.scene), boundary,
                       "Values after an explicit parent boundary must not become per-write commands")
        XCTAssertEqual(editor.history.undo(current: boundary), initial)
        XCTAssertNil(editor.history.undo(current: initial))
    }

    func testAnotherOwnerCannotAbsorbAnActiveTokenValue() throws {
        let editor = Editor(), tracking = StudioSliderTracking()
        let token = try XCTUnwrap(tracking.begin(editing: editor.adapter(), mapping: mapping,
                                               displayedValue: mapping.normalized(editor.width)!))
        tracking.change(mapping.normalized(1.3)!, for: token)
        let beforeOther = editor.scene
        editor.history.begin(scene: editor.scene, owner: "A.height")
        editor.scene.lights[0].optics?.heightMeters = 0.8
        let otherResult = editor.scene
        tracking.finish(token, finalDisplay: mapping.normalized(2)!)
        XCTAssertEqual(editor.history.undo(current: editor.scene), otherResult,
                       "The width write must not merge into the intervening height owner's command")
        XCTAssertEqual(editor.history.undo(current: otherResult), beforeOther)
    }

    func testCancellationCommitsLastPublishedValueWithoutFloatRewrite() throws {
        let editor = Editor(), tracking = StudioSliderTracking()
        let initial = editor.scene
        let token = try XCTUnwrap(tracking.begin(editing: editor.adapter(), mapping: mapping,
                                               displayedValue: mapping.normalized(editor.width)!))
        tracking.change(mapping.normalized(1.3)!, for: token)
        let published = editor.scene
        tracking.finish(token)
        tracking.change(1, for: token)
        XCTAssertEqual(editor.scene, published)
        XCTAssertFalse(editor.history.isEditing)
        XCTAssertEqual(editor.history.undo(current: published), initial)
    }

    func testInvalidSamplesDoNotWriteOrLeaveEditingOpen() throws {
        let editor = Editor(), tracking = StudioSliderTracking()
        let initial = editor.scene
        let token = try XCTUnwrap(tracking.begin(editing: editor.adapter(), mapping: mapping,
                                               displayedValue: mapping.normalized(editor.width)!))
        for value in [Float.nan, .infinity, -.infinity] { tracking.change(value, for: token) }
        tracking.finish(token, finalDisplay: .nan)
        XCTAssertEqual(editor.scene, initial)
        XCTAssertEqual(editor.writes, 0)
        XCTAssertFalse(editor.history.canUndo)
        XCTAssertFalse(editor.history.isEditing)
        XCTAssertNil(tracking.begin(editing: editor.adapter(), mapping: mapping, displayedValue: .nan))
    }

    func testReentrantFinishDuringFinalWriteClosesOnlyOnce() throws {
        let editor = Editor(), tracking = StudioSliderTracking()
        let initial = editor.scene
        let token = try XCTUnwrap(tracking.begin(editing: editor.adapter(), mapping: mapping,
                                               displayedValue: mapping.normalized(editor.width)!))
        editor.afterWrite = { tracking.finish(token) }
        tracking.finish(token, finalDisplay: mapping.normalized(1.3)!)
        XCTAssertFalse(tracking.isTracking)
        XCTAssertFalse(editor.history.isEditing)
        XCTAssertEqual(editor.ends, 1)
        XCTAssertEqual(editor.history.undo(current: editor.scene), initial)
    }

    func testOwnerReassertionCannotWriteAfterReentrantCancellation() throws {
        let editor = Editor(), tracking = StudioSliderTracking()
        let initial = editor.scene
        let token = try XCTUnwrap(tracking.begin(editing: editor.adapter(), mapping: mapping,
                                               displayedValue: mapping.normalized(editor.width)!))
        editor.afterBegin = { tracking.finish(token) }
        tracking.change(mapping.normalized(1.3)!, for: token)
        tracking.finish(token, finalDisplay: 1)
        XCTAssertEqual(editor.scene, initial)
        XCTAssertEqual(editor.writes, 0)
        XCTAssertEqual(editor.ends, 1)
        XCTAssertFalse(editor.history.isEditing)
        XCTAssertFalse(editor.history.canUndo)
    }

    func testReentrantInvalidationAtBeginRejectsSubsequentValues() throws {
        let tracking = StudioSliderTracking()
        var value = 0.723456789, begins = 0, ends = 0
        let adapter = StudioSliderEditing(read: { value }, write: { value = $0 }, onEditingChanged: { editing in
            if editing {
                begins += 1
                if let token = tracking.currentToken { tracking.finish(token) }
            } else { ends += 1 }
        })
        let token = try XCTUnwrap(tracking.begin(editing: adapter, mapping: mapping,
                                               displayedValue: mapping.normalized(value)!))
        tracking.change(1, for: token)
        tracking.finish(token, finalDisplay: 1)
        XCTAssertEqual(value, 0.723456789)
        XCTAssertFalse(tracking.isTracking)
        XCTAssertEqual(begins, 1)
        XCTAssertEqual(ends, 1)
    }

    func testMappingRejectsInvalidConfigurationAndKeepsEndpointsAndSteps() throws {
        XCTAssertNil(StudioSliderMapping(bounds: 1...1, step: 0.1))
        XCTAssertNil(StudioSliderMapping(bounds: 0...1, step: 0))
        XCTAssertNil(StudioSliderMapping(bounds: 0...1, step: .nan))
        XCTAssertNil(StudioSliderMapping(bounds: 0...Double.infinity, step: 1))
        XCTAssertNil(StudioSliderMapping(bounds: -Double.greatestFiniteMagnitude...Double.greatestFiniteMagnitude, step: 1))
        XCTAssertNil(mapping.normalized(.nan))
        XCTAssertNil(mapping.modelValue(.infinity))
        XCTAssertEqual(mapping.modelValue(-1), 0.05)
        XCTAssertEqual(mapping.modelValue(2), 4)
        for value in [0.05, 0.6, 1.3, 1.85, 3.95, 4] {
            XCTAssertEqual(try XCTUnwrap(mapping.modelValue(mapping.normalized(value)!)), value, accuracy: 1e-12)
        }
        let retained = try XCTUnwrap(StudioSliderMapping(bounds: -4...80.123456789, step: 0.05))
        XCTAssertEqual(retained.normalized(80.123456789), 1)
        XCTAssertEqual(retained.modelValue(1), 80.123456789)
        let unrepresentableGrid = try XCTUnwrap(StudioSliderMapping(bounds: 0...1, step: .leastNonzeroMagnitude))
        XCTAssertNil(unrepresentableGrid.modelValue(0.5))
    }
}
