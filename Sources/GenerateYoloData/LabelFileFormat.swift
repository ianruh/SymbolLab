//
// Created by Ian Ruh on 8/22/20.
//

import Foundation
import SymbolLab

public enum GeneratorError: Error {
    case noSVG(forNode: String)
    case noToken(forLabel: String)
    case misc(_ msg: String)
}

extension Double {
    public var nearestInt: Int {
        var val = self
        val.round(.toNearestOrAwayFromZero)
        return Int(val)
    }
}


/// Protocol for a general label file writer incase I have multiple later
///
protocol LabelFileWriter {
    static func write(nodes: [Node],
                      labelFile: String,
                      svgDirectory: String,
                      jpgDirectory: String,
                      usingSVGSource svgSource: SVGSource,
                      tokenMap: [String: Int]?,
                      countStart: Int,
                      size: Int) throws -> [String: Int]
}

/// File writer for the format used by https://github.com/david8862/keras-YOLOv3-model-set
struct KerasYOLOWriter: LabelFileWriter {
    static func write(nodes: [Node],
                      labelFile: String,
                      svgDirectory: String,
                      jpgDirectory: String,
                      usingSVGSource svgSource: SVGSource,
                      tokenMap: [String: Int]? = nil,
                      countStart: Int = 1,
                      size: Int = 200) throws -> [String: Int] {

        var labelString: String = ""

        var tokenCount = 0
        var tokenMapAct: [String: Int] = [:]

        var count = countStart
        for node in nodes {
            // Get the svg
            guard let svg = node.svg(using: svgSource) else {
                throw GeneratorError.noSVG(forNode: node.description)
            }

            // Resize to size x size
            guard let svg_bbox = svg.boundingBox else {
                throw GeneratorError.misc("No bounding box for svg")
            }
            var svgRes = svg
            if(svg_bbox.height > svg_bbox.width) {
                svgRes.resize(width: Double(size)*(svg_bbox.width/svg_bbox.height), height: Double(size))
            } else {
                svgRes.resize(width: Double(size), height: Double(size)*(svg_bbox.height/svg_bbox.width))
            }
            let svgNew = SVG(children: [])
            svgNew.paste(path: svgRes, withCenterLeftAt: Point(x: 0, y: Double(size)/2))

            // Get the bounding boxes
            let bboxes = svgNew.boundingBoxes
            var bboxLabelString = ""
            for key in bboxes.keys {
                // If we were given a token map
                if let tokenMapNP = tokenMap {
                    // Verify we have token for the key
                    guard tokenMapNP.keys.contains(key) else {
                        throw GeneratorError.noToken(forLabel: key)
                    }
                    // go through  every box
                    for box in bboxes[key]! {
                        bboxLabelString += "\(box.xmin.nearestInt),\(box.ymin.nearestInt),\(box.xmax.nearestInt),\(box.ymax.nearestInt),\(tokenMapNP[key]!) "
                    }
                } else {
                    // If we weren't given a token map
                    if(!tokenMapAct.keys.contains(key)) {
                        tokenMapAct[key] = tokenCount
                        tokenCount += 1
                    }

                    // go through  every box
                    for box in bboxes[key]! {
                        bboxLabelString += "\(box.xmin.nearestInt),\(box.ymin.nearestInt),\(box.xmax.nearestInt),\(box.ymax.nearestInt),\(tokenMapAct[key]!) "
                    }
                }
            }

            // Write the svg
            try svgNew.writeToDisk(path: "\(svgDirectory)/\(count).svg")

            // Construct the jpg name
            let jpgName = "\(jpgDirectory)/\(count).jpg"
            labelString += "\(jpgName) \(bboxLabelString)\n"
            count += 1
        }

        let labelURL: URL = URL(fileURLWithPath: labelFile)
        try labelString.write(to: labelURL, atomically: true, encoding: .utf8)

        if let tm = tokenMap {
            return tm
        } else {
            return tokenMapAct
        }
    }
}
