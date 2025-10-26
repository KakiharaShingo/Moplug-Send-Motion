import Foundation

struct MotionXMLGenerator {

    enum GenerationError: Error {
        case encodingFailed
        case invalidData
    }

    func generateMotionXML(from project: MotionProject) throws -> String {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        xml += "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n"
        xml += "<plist version=\"1.0\">\n"
        xml += "<dict>\n"

        // Project metadata
        xml += "    <key>name</key>\n"
        xml += "    <string>\(escapeXML(project.name))</string>\n"
        xml += "    <key>duration</key>\n"
        xml += "    <real>\(project.duration)</real>\n"
        xml += "    <key>frameRate</key>\n"
        xml += "    <real>\(project.frameRate)</real>\n"
        xml += "    <key>width</key>\n"
        xml += "    <integer>\(project.width)</integer>\n"
        xml += "    <key>height</key>\n"
        xml += "    <integer>\(project.height)</integer>\n"
        xml += "    <key>version</key>\n"
        xml += "    <string>\(project.version)</string>\n"

        // Scene root
        xml += "    <key>sceneRoot</key>\n"
        xml += "    <dict>\n"
        xml += "        <key>groups</key>\n"
        xml += "        <array>\n"

        // Groups (tracks)
        for group in project.groups {
            xml += generateGroupXML(group, indent: 3)
        }

        xml += "        </array>\n"
        xml += "    </dict>\n"

        xml += "</dict>\n"
        xml += "</plist>\n"

        return xml
    }

    private func generateGroupXML(_ group: MotionGroup, indent: Int) -> String {
        let indentStr = String(repeating: "    ", count: indent)
        var xml = ""

        xml += "\(indentStr)<dict>\n"
        xml += "\(indentStr)    <key>name</key>\n"
        xml += "\(indentStr)    <string>\(escapeXML(group.name))</string>\n"
        xml += "\(indentStr)    <key>type</key>\n"
        xml += "\(indentStr)    <string>\(group.type.rawValue)</string>\n"

        // Transform
        xml += "\(indentStr)    <key>transform</key>\n"
        xml += generateTransformXML(group.transform, indent: indent + 1)

        // Layers
        xml += "\(indentStr)    <key>layers</key>\n"
        xml += "\(indentStr)    <array>\n"

        for layer in group.layers {
            xml += generateLayerXML(layer, indent: indent + 2)
        }

        xml += "\(indentStr)    </array>\n"
        xml += "\(indentStr)</dict>\n"

        return xml
    }

    private func generateLayerXML(_ layer: MotionLayer, indent: Int) -> String {
        let indentStr = String(repeating: "    ", count: indent)
        var xml = ""

        xml += "\(indentStr)<dict>\n"
        xml += "\(indentStr)    <key>name</key>\n"
        xml += "\(indentStr)    <string>\(escapeXML(layer.name))</string>\n"
        xml += "\(indentStr)    <key>layerType</key>\n"
        xml += "\(indentStr)    <string>\(layer.layerType.rawValue)</string>\n"

        // Media reference
        if !layer.mediaRef.isEmpty {
            xml += "\(indentStr)    <key>mediaRef</key>\n"
            xml += "\(indentStr)    <string>\(escapeXML(layer.mediaRef))</string>\n"
        }

        // Media file path
        if let mediaPath = layer.mediaPath, !mediaPath.isEmpty {
            xml += "\(indentStr)    <key>mediaPath</key>\n"
            xml += "\(indentStr)    <string>\(escapeXML(mediaPath))</string>\n"
        }

        // Timing
        xml += "\(indentStr)    <key>timing</key>\n"
        xml += generateTimingXML(layer.timing, indent: indent + 1)

        // Transform
        xml += "\(indentStr)    <key>transform</key>\n"
        xml += generateTransformXML(layer.transform, indent: indent + 1)

        // Opacity
        xml += "\(indentStr)    <key>opacity</key>\n"
        xml += "\(indentStr)    <real>\(layer.opacity)</real>\n"

        // Blend mode
        xml += "\(indentStr)    <key>blendMode</key>\n"
        xml += "\(indentStr)    <string>\(layer.blendMode)</string>\n"

        // Filters
        if !layer.filters.isEmpty {
            xml += "\(indentStr)    <key>filters</key>\n"
            xml += "\(indentStr)    <array>\n"
            for filter in layer.filters {
                xml += generateFilterXML(filter, indent: indent + 2)
            }
            xml += "\(indentStr)    </array>\n"
        }

        xml += "\(indentStr)</dict>\n"

        return xml
    }

    private func generateTimingXML(_ timing: MotionTiming, indent: Int) -> String {
        let indentStr = String(repeating: "    ", count: indent)
        var xml = ""

        xml += "\(indentStr)<dict>\n"
        xml += "\(indentStr)    <key>offset</key>\n"
        xml += "\(indentStr)    <real>\(timing.offset)</real>\n"
        xml += "\(indentStr)    <key>duration</key>\n"
        xml += "\(indentStr)    <real>\(timing.duration)</real>\n"
        xml += "\(indentStr)    <key>trimStart</key>\n"
        xml += "\(indentStr)    <real>\(timing.trimStart)</real>\n"
        xml += "\(indentStr)    <key>trimEnd</key>\n"
        xml += "\(indentStr)    <real>\(timing.trimEnd)</real>\n"
        xml += "\(indentStr)</dict>\n"

        return xml
    }

    private func generateTransformXML(_ transform: MotionTransform, indent: Int) -> String {
        let indentStr = String(repeating: "    ", count: indent)
        var xml = ""

        xml += "\(indentStr)<dict>\n"
        xml += "\(indentStr)    <key>position</key>\n"
        xml += generatePoint3DXML(transform.position, indent: indent + 1)
        xml += "\(indentStr)    <key>scale</key>\n"
        xml += generatePoint3DXML(transform.scale, indent: indent + 1)
        xml += "\(indentStr)    <key>rotation</key>\n"
        xml += generatePoint3DXML(transform.rotation, indent: indent + 1)
        xml += "\(indentStr)    <key>anchor</key>\n"
        xml += generatePoint3DXML(transform.anchor, indent: indent + 1)

        // Keyframes
        if !transform.keyframes.isEmpty {
            xml += "\(indentStr)    <key>keyframes</key>\n"
            xml += "\(indentStr)    <array>\n"
            for keyframe in transform.keyframes {
                xml += generateKeyframeXML(keyframe, indent: indent + 2)
            }
            xml += "\(indentStr)    </array>\n"
        }

        xml += "\(indentStr)</dict>\n"

        return xml
    }

    private func generateKeyframeXML(_ keyframe: MotionKeyframe, indent: Int) -> String {
        let indentStr = String(repeating: "    ", count: indent)
        var xml = ""

        xml += "\(indentStr)<dict>\n"
        xml += "\(indentStr)    <key>time</key>\n"
        xml += "\(indentStr)    <real>\(keyframe.time)</real>\n"

        if let position = keyframe.position {
            xml += "\(indentStr)    <key>position</key>\n"
            xml += generatePoint3DXML(position, indent: indent + 1)
        }

        if let scale = keyframe.scale {
            xml += "\(indentStr)    <key>scale</key>\n"
            xml += generatePoint3DXML(scale, indent: indent + 1)
        }

        if let rotation = keyframe.rotation {
            xml += "\(indentStr)    <key>rotation</key>\n"
            xml += generatePoint3DXML(rotation, indent: indent + 1)
        }

        if let opacity = keyframe.opacity {
            xml += "\(indentStr)    <key>opacity</key>\n"
            xml += "\(indentStr)    <real>\(opacity)</real>\n"
        }

        xml += "\(indentStr)</dict>\n"

        return xml
    }

    private func generatePoint3DXML(_ point: MotionPoint3D, indent: Int) -> String {
        let indentStr = String(repeating: "    ", count: indent)
        var xml = ""

        xml += "\(indentStr)<dict>\n"
        xml += "\(indentStr)    <key>x</key>\n"
        xml += "\(indentStr)    <real>\(point.x)</real>\n"
        xml += "\(indentStr)    <key>y</key>\n"
        xml += "\(indentStr)    <real>\(point.y)</real>\n"
        xml += "\(indentStr)    <key>z</key>\n"
        xml += "\(indentStr)    <real>\(point.z)</real>\n"
        xml += "\(indentStr)</dict>\n"

        return xml
    }

    private func generateFilterXML(_ filter: MotionFilter, indent: Int) -> String {
        let indentStr = String(repeating: "    ", count: indent)
        var xml = ""

        xml += "\(indentStr)<dict>\n"
        xml += "\(indentStr)    <key>name</key>\n"
        xml += "\(indentStr)    <string>\(escapeXML(filter.name))</string>\n"
        xml += "\(indentStr)    <key>enabled</key>\n"
        xml += "\(indentStr)    <\(filter.enabled ? "true" : "false")/>\n"

        if !filter.parameters.isEmpty {
            xml += "\(indentStr)    <key>parameters</key>\n"
            xml += "\(indentStr)    <dict>\n"
            for (key, param) in filter.parameters {
                xml += "\(indentStr)        <key>\(escapeXML(key))</key>\n"
                xml += "\(indentStr)        <dict>\n"
                xml += "\(indentStr)            <key>type</key>\n"
                xml += "\(indentStr)            <string>\(escapeXML(param.type))</string>\n"
                xml += "\(indentStr)            <key>value</key>\n"
                xml += "\(indentStr)            <string>\(escapeXML(param.value))</string>\n"
                xml += "\(indentStr)        </dict>\n"
            }
            xml += "\(indentStr)    </dict>\n"
        }

        xml += "\(indentStr)</dict>\n"

        return xml
    }

    private func escapeXML(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}
