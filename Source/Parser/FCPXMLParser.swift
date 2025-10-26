import Foundation

struct FCPXMLParser {

    enum ParseError: Error {
        case invalidXML
        case missingTimelineData
        case parseError(String)
    }

    func parse(xmlString: String) throws -> Timeline {
        guard let xmlData = xmlString.data(using: .utf8) else {
            throw ParseError.invalidXML
        }

        let parser = XMLParser(data: xmlData)
        let delegate = FCPXMLParserDelegate()
        parser.delegate = delegate

        guard parser.parse() else {
            throw ParseError.parseError(parser.parserError?.localizedDescription ?? "Unknown parsing error")
        }

        guard let timeline = delegate.timeline else {
            throw ParseError.missingTimelineData
        }

        return timeline
    }
}

class FCPXMLParserDelegate: NSObject, XMLParserDelegate {
    var timeline: Timeline?
    private var currentElement: String = ""
    private var currentClip: Clip?
    private var currentTrack: Track?
    private var clips: [Clip] = []
    private var tracks: [Track] = []
    private var elementStack: [String] = []
    private var assets: [String: Asset] = [:]  // ID -> Asset mapping
    private var currentAsset: Asset?

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {

        elementStack.append(elementName)
        currentElement = elementName

        switch elementName {
        case "fcpxml":
            timeline = Timeline(duration: 0, tracks: [])

        case "project":
            if let name = attributeDict["name"] {
                timeline?.name = name
            }

        case "sequence":
            if let durationString = attributeDict["duration"],
               let tcFormat = attributeDict["tcFormat"] {
                let duration = parseDuration(durationString, tcFormat: tcFormat)
                timeline?.duration = duration
            }

        case "asset":
            currentAsset = Asset()
            currentAsset?.id = attributeDict["id"] ?? ""
            currentAsset?.name = attributeDict["name"] ?? ""
            currentAsset?.src = attributeDict["src"] ?? ""
            currentAsset?.hasVideo = attributeDict["hasVideo"] == "1"
            currentAsset?.hasAudio = attributeDict["hasAudio"] == "1"

            if let durationString = attributeDict["duration"] {
                currentAsset?.duration = parseDuration(durationString, tcFormat: "25p")
            }
            if let formatString = attributeDict["format"] {
                currentAsset?.format = formatString
            }

        case "spine", "video", "audio":
            currentTrack = Track(type: elementName == "audio" ? .audio : .video, clips: [])

        case "clip", "title", "gap":
            currentClip = Clip()
            currentClip?.type = ClipType(rawValue: elementName) ?? .clip
            currentClip?.name = attributeDict["name"] ?? ""

            if let offsetString = attributeDict["offset"],
               let durationString = attributeDict["duration"] {
                currentClip?.offset = parseDuration(offsetString, tcFormat: "25p")
                currentClip?.duration = parseDuration(durationString, tcFormat: "25p")
            }

            if let ref = attributeDict["ref"] {
                currentClip?.ref = ref
            }

            // Parse start attribute for in-point
            if let startString = attributeDict["start"] {
                currentClip?.start = parseDuration(startString, tcFormat: "25p")
            }

        case "param":
            parseParam(attributes: attributeDict)

        case "transform":
            parseTransform(attributes: attributeDict)

        default:
            break
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {

        elementStack.removeLast()

        switch elementName {
        case "asset":
            if let asset = currentAsset, !asset.id.isEmpty {
                assets[asset.id] = asset
            }
            currentAsset = nil

        case "clip", "title", "gap":
            if let clip = currentClip {
                // Resolve asset reference
                if !clip.ref.isEmpty, let asset = assets[clip.ref] {
                    var updatedClip = clip
                    updatedClip.assetInfo = asset
                    currentTrack?.clips.append(updatedClip)
                } else {
                    currentTrack?.clips.append(clip)
                }
                currentClip = nil
            }

        case "spine", "video", "audio":
            if let track = currentTrack {
                tracks.append(track)
                currentTrack = nil
            }

        case "sequence":
            timeline?.tracks = tracks
            timeline?.assets = assets

        default:
            break
        }
    }

    private func parseParam(attributes: [String: String]) {
        guard let name = attributes["name"],
              let value = attributes["value"] else { return }

        switch name {
        case "opacity":
            if let opacityValue = Double(value) {
                currentClip?.opacity = opacityValue
            }
        case "blend":
            currentClip?.blendMode = value
        default:
            break
        }
    }

    private func parseTransform(attributes: [String: String]) {
        var transform = Transform()

        if let scaleX = attributes["scale.x"], let scaleValue = Double(scaleX) {
            transform.scaleX = scaleValue
        }
        if let scaleY = attributes["scale.y"], let scaleValue = Double(scaleY) {
            transform.scaleY = scaleValue
        }
        if let posX = attributes["position.x"], let posValue = Double(posX) {
            transform.positionX = posValue
        }
        if let posY = attributes["position.y"], let posValue = Double(posY) {
            transform.positionY = posValue
        }
        if let rotation = attributes["rotation"], let rotValue = Double(rotation) {
            transform.rotation = rotValue
        }

        currentClip?.transform = transform
    }

    private func parseDuration(_ durationString: String, tcFormat: String) -> Double {
        let components = durationString.replacingOccurrences(of: "s", with: "").split(separator: "/")
        guard components.count == 2,
              let numerator = Double(components[0]),
              let denominator = Double(components[1]) else {
            return 0.0
        }
        return numerator / denominator
    }
}

// MARK: - Data Models

struct Timeline: Codable {
    var name: String = ""
    var duration: Double
    var tracks: [Track]
    var assets: [String: Asset] = [:]
}

struct Track: Codable {
    let type: TrackType
    var clips: [Clip]
}

enum TrackType: String, Codable {
    case video
    case audio
}

struct Clip: Codable {
    var type: ClipType = .clip
    var name: String = ""
    var ref: String = ""
    var offset: Double = 0.0
    var duration: Double = 0.0
    var start: Double = 0.0  // In-point in source media
    var opacity: Double = 1.0
    var blendMode: String = "normal"
    var transform: Transform = Transform()
    var effects: [Effect] = []
    var assetInfo: Asset?  // Resolved asset information
}

enum ClipType: String, Codable {
    case clip
    case title
    case gap
}

struct Transform: Codable {
    var positionX: Double = 0.0
    var positionY: Double = 0.0
    var scaleX: Double = 1.0
    var scaleY: Double = 1.0
    var rotation: Double = 0.0
    var keyframes: [Keyframe] = []  // Animation keyframes
}

struct Keyframe: Codable {
    var time: Double = 0.0  // Time in seconds
    var positionX: Double?
    var positionY: Double?
    var scaleX: Double?
    var scaleY: Double?
    var rotation: Double?
    var opacity: Double?
}

struct Effect: Codable {
    let name: String
    var parameters: [String: String] = [:]
}

struct Asset: Codable {
    var id: String = ""
    var name: String = ""
    var src: String = ""  // File path or URL
    var duration: Double = 0.0
    var format: String = ""
    var hasVideo: Bool = false
    var hasAudio: Bool = false
}