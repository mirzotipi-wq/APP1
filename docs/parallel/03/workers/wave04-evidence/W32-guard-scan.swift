import Foundation

// Compile with unchanged LightingCore at ace9f2eba068bc31dd04bb2f1e2028af315d6bdb.
// Bound: 2,048 poses, 24x16 pixels, 45 s scan deadline, <=8 renderer candidates.
private func dot(_ a: SIMD3<Double>, _ b: SIMD3<Double>) -> Double { a.x*b.x+a.y*b.y+a.z*b.z }
private func vec(_ p: Position) -> SIMD3<Double> { .init(p.x,p.y,p.z) }
private func vec(_ p: UnitDirection) -> SIMD3<Double> { .init(p.x,p.y,p.z) }
private func arr(_ p: SIMD3<Double>) -> [Double] { [p.x,p.y,p.z] }
private func hitJSON(_ h: PortraitGeometry.Hit?, _ o: SIMD3<Double>, _ d: SIMD3<Double>) -> Any {
    guard let h else { return NSNull() }
    return ["distance":h.distance, "position":arr(o+d*h.distance),
            "facing":dot(h.geometricNormal,-d), "region":String(describing:h.region)] as [String:Any]
}
// Diagnostic labels only. Decisions use actual shipped geometry, not this reconstruction.
private func labels(_ h: PortraitGeometry.Hit?, _ o: SIMD3<Double>, _ d: SIMD3<Double>, _ m: Double) -> [String] {
    guard let h else { return [] }
    var out:[String]=[]
    if h.region == .panel { out.append("panel") }
    if let v=PortraitHeadMesh.standard.hit(origin:o,direction:d,minimum:m,maximum:.infinity),
       abs(v.distance-h.distance)<1e-9 { out.append("headMesh") }
    let parts:[(String,SIMD3<Double>,SIMD3<Double>)]=[
        ("earMinusX",.init(-0.087,0.004,-0.015),.init(0.015,0.034,0.023)),
        ("earPlusX",.init(0.087,0.004,-0.015),.init(0.015,0.034,0.023)),
        ("neck",.init(0,-0.175,-0.016),.init(0.053,0.095,0.052)),
        ("torso",.init(0,-0.360,-0.022),.init(0.203,0.205,0.108)),
        ("shoulderMinusX",.init(-0.129,-0.294,-0.020),.init(0.107,0.086,0.090)),
        ("shoulderPlusX",.init(0.129,-0.294,-0.020),.init(0.107,0.086,0.090))]
    for (name,c,r) in parts {
        let a0=(o-c)/r, b0=d/r, a=dot(b0,b0), b=dot(a0,b0), c0=dot(a0,a0)-1
        let disc=b*b-a*c0
        if disc<0 || a<=0 { continue }
        let near=(-b-sqrt(disc))/a, far=(-b+sqrt(disc))/a, t=near>=m ? near:far
        if t>=m && abs(t-h.distance)<1e-9 { out.append(name) }
    }
    return out
}
private struct Scan {
    var clipped=0, masked=0, holes=0, backfaces=0
    var witness:[String:Any]?
    var backface:[String:Any]?
}
private func scan(_ scene:LightingScene,_ camera:CameraFraming) -> Scan {
    let g=PortraitGeometry(center:scene.subject), o=vec(scene.camera)
    let f=vec(camera.forward), r=vec(camera.right), u=vec(camera.up), focal=camera.lens.focalLengthMillimeters
    var out=Scan()
    for y in 0..<16 {
        for x in 0..<24 {
            let px=(2*(Double(x)+0.5)/24-1)*36/(2*focal)
            let py=(1-2*(Double(y)+0.5)/16)*24/(2*focal)
            let v=f+r*px+u*py, d=v/sqrt(dot(v,v)), m=CameraFraming.minimumDepthMeters/dot(d,f)
            let first=g.hit(origin:o,direction:d,minimum:1e-9)
            let retained=g.hit(origin:o,direction:d,minimum:m)
            let before=first.map{$0.region != .panel && $0.distance<m-1e-10} ?? false
            if before { out.clipped+=1 }
            if let retained, dot(retained.geometricNormal,-d)<0 {
                out.backfaces+=1
                if out.backface == nil { out.backface=["pixel":[x,y],"minimumRayMeters":m,
                    "first":hitJSON(first,o,d),"retained":hitJSON(retained,o,d)] }
            }
            guard before, let first, dot(first.geometricNormal,-d)>0 else { continue }
            let masked=retained.map{dot($0.geometricNormal,-d)>=0} ?? false
            if masked { out.masked+=1 }
            if retained == nil { out.holes+=1 }
            guard out.witness == nil, masked || retained == nil else { continue }
            let head=PortraitHeadMesh.standard.hit(origin:o,direction:d,minimum:1e-9,maximum:.infinity)
            let next=head.flatMap{PortraitHeadMesh.standard.hit(origin:o,direction:d,
                minimum:$0.distance+1e-8,maximum:.infinity)}
            var internalHead=false
            if let head, let next, let retained {
                internalHead=abs(head.distance-first.distance)<1e-9 &&
                    dot(head.geometricNormal,-d)>0 && dot(next.geometricNormal,-d)<0 &&
                    retained.distance>head.distance+1e-9 && retained.distance<next.distance-1e-9
            }
            out.witness=["pixel":[x,y],"ray":arr(d),"minimumRayMeters":m,
                "first":hitJSON(first,o,d),"retained":hitJSON(retained,o,d),
                "firstPrimitiveLabels":labels(first,o,d,1e-9),
                "retainedPrimitiveLabels":labels(retained,o,d,m),
                "firstCameraDepthMeters":first.distance*dot(d,f),
                "nextHeadIntersectionDistance":next.map{$0.distance as Any} ?? NSNull(),
                "retainedInsideFirstHeadEntryExitInterval":internalHead]
        }
    }
    return out
}
@main struct W32NearPlaneProbe {
    static func main() throws {
        let azimuths=[15.0,60,105,150,195,240,285,330]
        let elevations=[87.0,82,75,65,50,25,-30,-60]
        let distances=[0.170001,0.1725,0.1775,0.1825,0.1875,0.195,0.215,0.275]
        let lenses=[14.0,28,105,200]
        let start=Date()
        var counts=["plannedPoses":2048,"visitedPoses":0,"preconditionRejectedPoses":0,
            "scannedPoses":0,"pixelsExamined":0,"posesWithClippedFirsts":0,
            "posesWithMaskedEntries":0,"backfaceRejectedPoses":0,
            "guardAcceptedClippedPoses":0,"sampledUncutBackfaceRejects":0,
            "rendererCandidatesExecuted":0]
        var examples:[[String:Any]]=[]
        var firstMasking:[String:Any]?
        var deadline=false
        scanLoop: for elevation in elevations {
            for azimuth in azimuths {
                for distance in distances {
                    for focal in lenses {
                        if Date().timeIntervalSince(start)>45 { deadline=true; break scanLoop }
                        counts["visitedPoses",default:0]+=1
                        let az=azimuth*Double.pi/180, el=elevation*Double.pi/180
                        let position=Position(x:distance*cos(el)*sin(az),y:distance*sin(el),z:distance*cos(el)*cos(az))
                        let scene=LightingScene(subject:.init(x:0,y:0,z:0),camera:position,lights:[],
                            cameraLens:.init(focalLengthMillimeters:focal))
                        let g=PortraitGeometry(center:scene.subject)
                        guard let camera=CameraFraming(scene:scene),position.y>PortraitGeometry.panelOffset+0.01,
                            camera.subjectDistanceMeters>0.17,!g.contains(vec(position)) else {
                            counts["preconditionRejectedPoses",default:0]+=1; continue
                        }
                        let s=scan(scene,camera)
                        counts["scannedPoses",default:0]+=1; counts["pixelsExamined",default:0]+=384
                        if s.clipped>0 { counts["posesWithClippedFirsts",default:0]+=1 }
                        if s.masked>0 { counts["posesWithMaskedEntries",default:0]+=1 }
                        if s.backfaces>0 { counts["backfaceRejectedPoses",default:0]+=1 }
                        var record:[String:Any]=["azimuthDegrees":azimuth,"elevationDegrees":elevation,
                            "distanceMeters":distance,"focalLengthMillimeters":focal,"camera":arr(vec(position)),
                            "width":24,"clippedFirstPixels":s.clipped,"maskedEntryPixels":s.masked,
                            "clippedToBackgroundPixels":s.holes,"backfacingRetainedPixels":s.backfaces,
                            "witness":s.witness as Any? ?? NSNull(),"firstBackface":s.backface as Any? ?? NSNull()]
                        if s.masked>0 && firstMasking == nil { firstMasking=record }
                        let accepted=s.clipped>0 && s.backfaces==0
                        let falseReject=s.clipped==0 && s.backfaces>0
                        if accepted { counts["guardAcceptedClippedPoses",default:0]+=1 }
                        if falseReject { counts["sampledUncutBackfaceRejects",default:0]+=1 }
                        guard accepted || falseReject,examples.count<8 else { continue }
                        record["classification"]=accepted ? "guardAcceptedClippedFirst":"sampledUncutBackfaceReject"
                        var outcomes:[[String:Any]]=[]
                        for width in [24,48,72,120,144] {
                            do {
                                let image=try PortraitStudyRenderer.render(scene:scene,width:width)
                                outcomes.append(["width":width,"outcome":"returnedImage",
                                    "unsupportedPixels":image.unsupportedPixels,
                                    "nonzeroMaskBytes":image.unsupportedPixelMask.filter{$0 != 0}.count])
                            } catch { outcomes.append(["width":width,"outcome":"threw","error":String(describing:error)]) }
                        }
                        counts["rendererCandidatesExecuted",default:0]+=1
                        record["rendererOutcomes"]=outcomes; examples.append(record)
                    }
                }
            }
        }
        let result:[String:Any]=["probe":"W32-geometry-near-plane","canonicalTaskPath":"/root/wave04/geometry",
            "sourceRevision":"ace9f2eba068bc31dd04bb2f1e2028af315d6bdb",
            "privateWorktree":"/tmp/keyfill03-7f4b/workers/W32-geometry",
            "actualSourceExecution":true,"scanWidth":24,"scanHeight":16,
            "azimuthDegrees":azimuths,"elevationDegrees":elevations,"distanceMeters":distances,
            "focalLengthMillimeters":lenses,"scanDeadlineSeconds":45,"deadlineReached":deadline,
            "elapsedSeconds":Date().timeIntervalSince(start),"counts":counts,
            "firstMaskingExample":firstMasking as Any? ?? NSNull(),"counterexamples":examples,
            "limitations":["Finite pixel grids; no exhaustive continuous-view proof.",
                "Zero lights isolate camera geometry; guard acceptance alone is not a visible image defect.",
                "Internal-head interval witness distinguishes newly exposed interior geometry.",
                "Primitive labels reconstruct analytic intervals; hit decisions use shipped Swift.",
                "No Apple, Metal, physical-device or visual-image acceptance claimed."]]
        let data=try JSONSerialization.data(withJSONObject:result,options:[.prettyPrinted,.sortedKeys])
        print(String(decoding:data,as:UTF8.self))
    }
}
