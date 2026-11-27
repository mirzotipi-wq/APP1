import Foundation
@main struct W018Probe {
 static func main() throws {
  var checks = 0
  func check(_ test: @autoclosure () -> Bool, _ label: String) {
   checks += 1
   guard test() else { print("FAIL: \(label)"); exit(1) }
  }
  let duplicate = "نور\u{202E}\n👩🏽‍💻"
  let lights = [
   StudioLight(name: duplicate, position: .init(x: -2.0000005, y: 0.3048, z: 0), candela: 4321.125, kelvin: 5600.25),
   StudioLight(name: duplicate, position: .init(x: -1.5000005, y: 1, z: 0), candela: 4321.125, kelvin: 5600.25, optics: .init(kind: .rectangle, aimTarget: .init(x: -1.5000005, y: 1, z: 1), widthMeters: 1, heightMeters: 1, rollDegrees: 0)),
   StudioLight(name: "\u{200D}", position: .init(x: 0, y: 1, z: 2), candela: 900, kelvin: 5600, optics: .init(kind: .directional))
  ]
  var scene = LightingScene(subject: .init(x: 0, y: 1, z: 0), camera: .init(x: 0, y: 1, z: 3.048), lights: lights, placementRoom: .init(widthMeters: 4, depthMeters: 8, subjectX: 2, subjectZ: 2, ceilingHeightMeters: 2.5))
  let original = scene
  let metric = try LightingPlan(scene: scene, title: "測定\n\u{2067}Plan", units: .metric)
  let imperial = try LightingPlan(scene: scene, title: "測定\n\u{2067}Plan", units: .imperial)
  for plan in [metric, imperial] {
   check(plan.scene == original, "SI scene preserved")
   check(plan.lights.map(\.number) == [1,2,3], "equipment identity")
   check(plan.roomPlacementItems.map(\.marker) == ["S","C","1","2","3"], "room markers align")
   check(plan.roomPlacementItems[3].point.id == lights[1].id.uuidString, "footprint identity")
   check(plan.roomPlacementItems[3].modifierFootprint?.id == lights[1].id, "footprint id")
   check(plan.lights[0].name == plan.lights[1].name, "duplicate normalized names")
   check(plan.lights[2].name == "Light 3", "invisible fallback")
   check(!plan.plainText.contains("\u{202E}") && !plan.plainText.contains("\u{2067}"), "bidi controls removed")
   check(plan.plainText.contains("4321.125 cd · 5600.25 K"), "output unit precision")
   check(plan.plainText.contains("Rectangular softbox") && plan.plainText.contains("Roll 0°"), "kind and explicit zero roll")
   check(!plan.lights[0].settings(units: plan.units).contains("Roll"), "point has no roll")
   check(plan.lights[1].aim(units: plan.units).contains("manual target"), "manual aim")
   check(plan.lights[2].aim(units: plan.units).contains("follows subject"), "subject aim")
   check(plan.roomPlacement!.outsideCount == 1, "subprecision outside preserved")
   check(plan.roomPlacement!.crossingModifierCount == 1, "subprecision overhang preserved")
   check(plan.roomPlacementItems[3].hasWarning, "overhang remains warning")
   check(plan.plainText.contains("not calibrated photometry"), "scope limitation")
  }
  check(metric.cameraSettings.contains("3.05 m to subject"), "metric derived distance")
  check(imperial.cameraSettings.contains("10.00 ft to subject"), "imperial derived distance")
  check(metric.roomPlacementText!.contains("X from left wall: between -0.000001 and 0 m"), "metric signed subprecision")
  check(imperial.roomPlacementText!.contains("X from left wall: -0.000002 ft"), "imperial converted signed precision")
  check(metric.roomPlacementText!.contains("Projected wall overhang: less than 0.000001 m"), "metric positive bound")
  check(imperial.roomPlacementText!.contains("Projected wall overhang: 0.000002 ft"), "imperial visible bound")
  check(imperial.lights[0].placement(units: .imperial).contains(", 1.00, 0.00) ft"), "SI height converted exactly")
  let notes = metric.roomPlacement!.textSummary(locale: Locale(identifier: "fr_FR"))
  check(notes.contains("Room width: 4,00 m"), "room notes locale and explicit metric")
  check(notes.contains("3. \(metric.lights[0].name)\n") && notes.contains("4. \(metric.lights[1].name)\n"), "notes duplicate identity")
  scene.lights[0].position.x = 50
  scene.placementRoom?.widthMeters = 20
  check(metric.scene == original && imperial.scene == original, "snapshot excludes later edits")
  print("PASS: \(checks) held-out text/units/identity/snapshot assertions")
  print("metric: \(metric.roomPlacementItems[3].projectedFaceStatus(units: .metric)!)")
  print("imperial: \(imperial.roomPlacementItems[3].projectedFaceStatus(units: .imperial)!)")
 }
}
