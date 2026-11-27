import Foundation
import Dispatch
import LightingCore

// Exactly 100 ordinary full-facing rectangularIlluminance calls; no warmup calls.
let count = 100
let emitter = LambertianRectangle(
    center: Position(x: 0, y: 0, z: 0),
    right: UnitDirection(x: 1, y: 0, z: 0)!,
    up: UnitDirection(x: 0, y: 1, z: 0)!,
    widthMeters: 1, heightMeters: 0.6, onAxisCandela: 1000)!
let receiver = Position(x: 0, y: 0, z: 2)
let receiverNormal = UnitDirection(x: 0, y: 0, z: -1)!
var checksum = 0.0
var lastLux = 0.0
let start = DispatchTime.now().uptimeNanoseconds
for _ in 0..<count {
    guard let lux = Photometry.rectangularIlluminance(
        emitter: emitter, receiver: receiver, receiverNormal: receiverNormal) else {
        fatalError("ordinary supported fixture unexpectedly returned nil")
    }
    precondition(lux.isFinite && lux > 0)
    checksum += lux
    lastLux = lux
}
let loopNanoseconds = DispatchTime.now().uptimeNanoseconds - start
print("source_sha=f75aa2758b4c14714e7517c4c0df4adb9f1a8b9b")
print("workload=100 full-facing rectangle calls; no warmup; 102400 midpoint cells")
print("fixture=center(0,0,0); right(1,0,0); up(0,1,0); width1m; height0.6m; intensity1000cd; receiver(0,0,2)m; normal(0,0,-1)")
print("calls=\(count)")
print("last_lux=\(lastLux)")
print("checksum_lux=\(checksum)")
print("loop_elapsed_ns=\(loopNanoseconds)")
