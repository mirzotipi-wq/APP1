import CoreGraphics
import Foundation
import PDFKit
import UIKit
import LightingCore

/// Native vector PDF; no rendered reference photograph is passed into the exporter.
@MainActor enum LightingPlanPDF {
    private static let ink = UIColor(red: 0.09, green: 0.12, blue: 0.15, alpha: 1)
    private static let muted = UIColor(white: 0.33, alpha: 1)
    private static let rule = UIColor(white: 0.85, alpha: 1)
    private static let amber = UIColor(red: 0.55, green: 0.30, blue: 0.05, alpha: 1)
    private static let blue = UIColor(red: 0.12, green: 0.32, blue: 0.48, alpha: 1)

    enum ExportError: Error { case invalidPDF }

    static func make(_ plan: LightingPlan) throws -> Data {
        let bounds = CGRect(x: 0, y: 0, width: plan.paper.width, height: plan.paper.height)
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [kCGPDFContextTitle as String: "Key & Fill - Lighting plan",
                               kCGPDFContextCreator as String: "Key & Fill"]
        let renderer = UIGraphicsPDFRenderer(bounds: bounds, format: format)
        let data = renderer.pdfData { context in
            context.beginPage()
            let cg = context.cgContext
            base(cg, plan: plan, bounds: bounds, section: "Overhead lighting plan", page: 1)
            overview(cg, plan: plan, bounds: bounds)
            for (index, lights) in plan.equipmentPages.enumerated() {
                context.beginPage()
                base(cg, plan: plan, bounds: bounds, section: "Equipment & placement", page: index + 2)
                equipment(cg, plan: plan, lights: lights, bounds: bounds)
            }
        }
        guard let document = PDFDocument(data: data), document.pageCount == plan.pageCount else { throw ExportError.invalidPDF }
        return data
    }

    private static func base(_ cg: CGContext, plan: LightingPlan, bounds: CGRect, section: String, page: Int) {
        cg.setFillColor(UIColor.white.cgColor); cg.fill(bounds)
        let width = bounds.width - 80
        text("KEY & FILL  /  STUDIO DOCUMENT", x: 40, y: 32, width: width, height: 16, size: 10, color: amber, weight: .semibold)
        text(section, x: 40, y: 51, width: width, height: 38, size: 25, weight: .semibold)
        text(plan.title, x: 40, y: 92, width: width, height: 42, size: 15, minimum: 10, color: muted)
        stroke(cg, from: CGPoint(x: 40, y: 137), to: CGPoint(x: bounds.width - 40, y: 137), color: rule)
        let footer = bounds.height - 41
        stroke(cg, from: CGPoint(x: 40, y: footer - 8), to: CGPoint(x: bounds.width - 40, y: footer - 8), color: rule)
        text("Plan v\(LightingPlan.reportVersion) · Scene v\(plan.scene.schemaVersion) · \(plan.paper.title)", x: 40, y: footer, width: width - 80, height: 20, size: 9, color: muted)
        text("\(page) / \(plan.pageCount)", x: bounds.width - 106, y: footer, width: 66, height: 20, size: 9, color: muted, alignment: .right)
    }

    private static func overview(_ cg: CGContext, plan: LightingPlan, bounds: CGRect) {
        let diagram = plan.diagram()
        let rect = CGRect(x: 40, y: 150, width: diagram.width, height: diagram.height)
        func point(_ p: PlanPoint) -> CGPoint { CGPoint(x: rect.minX + CGFloat(p.x), y: rect.minY + CGFloat(p.y)) }
        cg.saveGState(); cg.clip(to: rect)
        cg.setFillColor(UIColor(white: 0.975, alpha: 1).cgColor); cg.fill(rect)
        for line in diagram.grid {
            stroke(cg, from: point(line.from), to: point(line.to), color: line.isAxis ? UIColor(white: 0.64, alpha: 1) : rule, width: line.isAxis ? 0.8 : 0.45)
        }
        for line in diagram.lines {
            let points = line.points.map(point)
            guard points.count >= 2 else { continue }
            switch line.kind {
            case .camera: path(cg, points: points, color: blue, width: 1.2, dash: [5, 3]); arrow(cg, points: points, color: blue)
            case .aim: path(cg, points: points, color: amber, width: 1.2, dash: [4, 3]); arrow(cg, points: points, color: amber)
            case .modifier: path(cg, points: points, color: amber, width: 2)
            }
        }
        // Draw all exact anchors/leaders before placing the readable badges.
        for marker in diagram.markers {
            let a = point(marker.anchor), b = point(marker.center)
            if marker.anchor != marker.center { stroke(cg, from: a, to: b, color: muted, width: 0.8) }
            cg.setFillColor(ink.cgColor); cg.fillEllipse(in: CGRect(x: a.x - 2, y: a.y - 2, width: 4, height: 4))
        }
        for marker in diagram.markers {
            let p = point(marker.center)
            let badge = CGRect(x: p.x - 10, y: p.y - 10, width: 20, height: 20)
            let color: UIColor = marker.kind == .subject ? ink : marker.kind == .camera ? blue : amber
            cg.setFillColor(color.cgColor); cg.fillEllipse(in: badge)
            cg.setStrokeColor(UIColor.white.cgColor); cg.setLineWidth(1); cg.strokeEllipse(in: badge)
            text(marker.label, x: badge.minX, y: badge.minY + 3, width: 20, height: 15, size: 10, color: .white, weight: .bold, alignment: .center)
        }
        cg.restoreGState()
        cg.setStrokeColor(rule.cgColor); cg.setLineWidth(0.8); cg.stroke(rect)
        let width = bounds.width - 80
        text("S  Subject    C  Camera    1–12  Lights    Solid outline  Diffuser    Dashed arrows  Aim", x: 40, y: 544, width: width, height: 18, size: 10, minimum: 8.5, weight: .medium)
        text("\(diagram.scaleLabel) · +X right / +Z down · Y is elevation · Leaders mark displaced labels", x: 40, y: 566, width: width, height: 24, size: 9.5, color: muted)
        stroke(cg, from: CGPoint(x: 40, y: 594), to: CGPoint(x: bounds.width - 40, y: 594), color: rule)
        text("SUBJECT   \(plan.units.parameterCoordinates(plan.scene.subject))", x: 40, y: 605, width: width, height: 18, size: 11, weight: .semibold)
        text("CAMERA    \(plan.units.parameterCoordinates(plan.scene.camera))", x: 40, y: 626, width: width, height: 18, size: 11, weight: .semibold)
        text(plan.cameraSettings, x: 40, y: 647, width: width, height: 18, size: 10.5, color: muted)
        text(plan.previewSettings, x: 40, y: 668, width: width, height: 18, size: 10.5, color: muted)
        text("Planning geometry only. Output in cd is ideal luminous intensity, not electrical watts or a measured fixture profile. Camera framing and exposure are ideal/relative. No reference images are embedded.", x: 40, y: 692, width: width, height: 38, size: 9.5, color: muted)
    }

    private static func equipment(_ cg: CGContext, plan: LightingPlan, lights: [PlanLight], bounds: CGRect) {
        let width = bounds.width - 80
        if lights.isEmpty { text("No lights in this setup.", x: 40, y: 160, width: width, height: 32, size: 13, color: muted) }
        for (index, light) in lights.enumerated() {
            let y = CGFloat(151 + index * 112)
            text("\(light.number)", x: 40, y: y + 3, width: 31, height: 25, size: 18, color: amber, weight: .semibold)
            let x: CGFloat = 76, rowWidth = bounds.width - x - 40
            text(light.name, x: x, y: y, width: rowWidth, height: 35, size: 15, minimum: 11, weight: .semibold)
            text(light.kind.title + " · " + light.settings(units: plan.units), x: x, y: y + 37, width: rowWidth, height: 22, size: 10.5, minimum: 9)
            text(light.placement(units: plan.units), x: x, y: y + 59, width: rowWidth, height: 20, size: 10.5, minimum: 9, color: muted)
            text(light.aim(units: plan.units), x: x, y: y + 80, width: rowWidth, height: 20, size: 10.5, minimum: 9, color: light.aimIsValid ? muted : amber)
            stroke(cg, from: CGPoint(x: 40, y: y + 105), to: CGPoint(x: bounds.width - 40, y: y + 105), color: rule)
        }
        text("XYZ in \(plan.units.symbol) · entered settings rounded to six fractional digits · derived center-to-center 3D distances rounded to two.", x: 40, y: 715, width: width, height: 24, size: 9, color: muted)
    }

    private static func text(_ string: String, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat,
                             size: CGFloat, minimum: CGFloat? = nil, color: UIColor? = nil,
                             weight: UIFont.Weight = .regular, alignment: NSTextAlignment = .left) {
        let paragraph = NSMutableParagraphStyle(); paragraph.alignment = alignment; paragraph.lineBreakMode = .byWordWrapping
        let box = CGRect(x: x, y: y, width: width, height: height)
        var fontSize = size
        let floor = minimum ?? size
        var attributes: [NSAttributedString.Key: Any] = [:]
        let options: NSStringDrawingOptions = [.usesLineFragmentOrigin, .usesFontLeading]
        while true {
            attributes = [.font: UIFont.systemFont(ofSize: fontSize, weight: weight), .foregroundColor: color ?? ink, .paragraphStyle: paragraph]
            let required = (string as NSString).boundingRect(with: CGSize(width: width, height: 10_000), options: options, attributes: attributes, context: nil)
            if required.height <= height + 0.1 || fontSize <= floor { break }
            fontSize = max(floor, fontSize - 0.5)
        }
        (string as NSString).draw(with: box, options: options.union(.truncatesLastVisibleLine), attributes: attributes, context: nil)
    }

    private static func stroke(_ cg: CGContext, from: CGPoint, to: CGPoint, color: UIColor, width: CGFloat = 0.7) {
        path(cg, points: [from, to], color: color, width: width)
    }
    private static func path(_ cg: CGContext, points: [CGPoint], color: UIColor, width: CGFloat, dash: [CGFloat] = []) {
        guard let first = points.first else { return }
        cg.saveGState(); cg.setStrokeColor(color.cgColor); cg.setLineWidth(width); cg.setLineDash(phase: 0, lengths: dash)
        cg.beginPath(); cg.move(to: first); for p in points.dropFirst() { cg.addLine(to: p) }; cg.strokePath(); cg.restoreGState()
    }
    private static func arrow(_ cg: CGContext, points: [CGPoint], color: UIColor) {
        guard let tip = points.last, points.count >= 2 else { return }
        let previous = points[points.count - 2], dx = tip.x - previous.x, dy = tip.y - previous.y
        let length = hypot(dx, dy); guard length > 8 else { return }
        let ux = dx / length, uy = dy / length
        let a = CGPoint(x: tip.x - 7 * ux - 3 * uy, y: tip.y - 7 * uy + 3 * ux)
        let b = CGPoint(x: tip.x - 7 * ux + 3 * uy, y: tip.y - 7 * uy - 3 * ux)
        path(cg, points: [a, tip, b], color: color, width: 1.2)
    }
}
