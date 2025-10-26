import Foundation

struct MotionProjectGenerator {

    enum GenerationError: Error {
        case conversionFailed(String)
        case unsupportedFormat
    }

    func generateMotionProject(from timeline: Timeline) throws -> MotionProject {
        var motionProject = MotionProject()
        motionProject.name = timeline.name.isEmpty ? "Converted from Final Cut Pro" : timeline.name
        motionProject.duration = timeline.duration
        motionProject.frameRate = 29.97

        var motionGroups: [MotionGroup] = []

        for (trackIndex, track) in timeline.tracks.enumerated() {
            let motionGroup = try convertTrackToGroup(track, trackIndex: trackIndex)
            motionGroups.append(motionGroup)
        }

        motionProject.groups = motionGroups
        return motionProject
    }

    private func convertTrackToGroup(_ track: Track, trackIndex: Int) throws -> MotionGroup {
        var motionGroup = MotionGroup()
        motionGroup.name = "Track \(trackIndex + 1) (\(track.type.rawValue.capitalized))"
        motionGroup.type = track.type == .video ? .video : .audio

        var motionLayers: [MotionLayer] = []

        for clip in track.clips {
            let motionLayer = try convertClipToLayer(clip)
            motionLayers.append(motionLayer)
        }

        motionGroup.layers = motionLayers
        return motionGroup
    }

    private func convertClipToLayer(_ clip: Clip) throws -> MotionLayer {
        var motionLayer = MotionLayer()
        motionLayer.name = clip.name.isEmpty ? "Untitled Layer" : clip.name
        motionLayer.mediaRef = clip.ref

        // Set media path from asset info
        if let asset = clip.assetInfo {
            motionLayer.mediaPath = resolveMediaPath(asset.src)
        }

        // Timing with in/out points
        motionLayer.timing.offset = clip.offset
        motionLayer.timing.duration = clip.duration
        motionLayer.timing.trimStart = clip.start  // In-point
        motionLayer.timing.trimEnd = clip.start + clip.duration  // Out-point

        let converter = TransformConverter()
        motionLayer.transform = converter.convertTransform(clip.transform)

        motionLayer.opacity = clip.opacity
        motionLayer.blendMode = convertBlendMode(clip.blendMode)

        if clip.type == .title {
            motionLayer.layerType = .text
        } else {
            motionLayer.layerType = .media
        }

        return motionLayer
    }

    private func resolveMediaPath(_ src: String) -> String {
        // Handle file:// URLs
        if src.hasPrefix("file://") {
            if let url = URL(string: src) {
                return url.path
            }
        }

        // Handle relative paths - convert to absolute
        // FCPXML often uses URLs like "file:///Users/..."
        if src.hasPrefix("/") {
            return src
        }

        // Return as-is for other formats
        return src
    }

    private func convertBlendMode(_ fcpBlendMode: String) -> String {
        switch fcpBlendMode.lowercased() {
        case "normal":
            return "Normal"
        case "multiply":
            return "Multiply"
        case "screen":
            return "Screen"
        case "overlay":
            return "Overlay"
        case "softlight":
            return "Soft Light"
        case "hardlight":
            return "Hard Light"
        case "colordodge":
            return "Color Dodge"
        case "colorburn":
            return "Color Burn"
        case "darken":
            return "Darken"
        case "lighten":
            return "Lighten"
        case "difference":
            return "Difference"
        case "exclusion":
            return "Exclusion"
        default:
            return "Normal"
        }
    }
}

// MARK: - Motion Project Data Models

struct MotionProject: Codable {
    var name: String = ""
    var duration: Double = 0.0
    var frameRate: Double = 29.97
    var width: Int = 1920
    var height: Int = 1080
    var groups: [MotionGroup] = []
    var version: String = "5.7"
}

struct MotionGroup: Codable {
    var name: String = ""
    var type: MotionGroupType = .video
    var layers: [MotionLayer] = []
    var transform: MotionTransform = MotionTransform()
}

enum MotionGroupType: String, Codable {
    case video = "Video"
    case audio = "Audio"
}

struct MotionLayer: Codable {
    var name: String = ""
    var layerType: MotionLayerType = .media
    var mediaRef: String = ""
    var mediaPath: String?  // Actual file path to media
    var timing: MotionTiming = MotionTiming()
    var transform: MotionTransform = MotionTransform()
    var opacity: Double = 1.0
    var blendMode: String = "Normal"
    var filters: [MotionFilter] = []
}

enum MotionLayerType: String, Codable {
    case media = "Media"
    case text = "Text"
    case shape = "Shape"
}

struct MotionTiming: Codable {
    var offset: Double = 0.0
    var duration: Double = 0.0
    var trimStart: Double = 0.0
    var trimEnd: Double = 0.0
}

struct MotionTransform: Codable {
    var position: MotionPoint3D = MotionPoint3D()
    var scale: MotionPoint3D = MotionPoint3D(x: 1.0, y: 1.0, z: 1.0)
    var rotation: MotionPoint3D = MotionPoint3D()
    var anchor: MotionPoint3D = MotionPoint3D()
    var keyframes: [MotionKeyframe] = []
}

struct MotionPoint3D: Codable {
    var x: Double = 0.0
    var y: Double = 0.0
    var z: Double = 0.0
}

struct MotionFilter: Codable {
    var name: String = ""
    var enabled: Bool = true
    var parameters: [String: MotionFilterParameter] = [:]
}

struct MotionFilterParameter: Codable {
    let type: String
    let value: String
}

struct MotionKeyframe: Codable {
    var time: Double = 0.0
    var position: MotionPoint3D?
    var scale: MotionPoint3D?
    var rotation: MotionPoint3D?
    var opacity: Double?
}