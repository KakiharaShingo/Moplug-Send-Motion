import Foundation

struct TransformConverter {

    func convertTransform(_ fcpTransform: Transform) -> MotionTransform {
        var motionTransform = MotionTransform()

        motionTransform.position = MotionPoint3D(
            x: fcpTransform.positionX,
            y: fcpTransform.positionY,
            z: 0.0
        )

        motionTransform.scale = MotionPoint3D(
            x: fcpTransform.scaleX,
            y: fcpTransform.scaleY,
            z: 1.0
        )

        motionTransform.rotation = MotionPoint3D(
            x: 0.0,
            y: 0.0,
            z: fcpTransform.rotation
        )

        motionTransform.anchor = MotionPoint3D(
            x: 0.0,
            y: 0.0,
            z: 0.0
        )

        // Convert keyframes
        motionTransform.keyframes = fcpTransform.keyframes.map { convertKeyframe($0) }

        return motionTransform
    }

    func convertKeyframe(_ fcpKeyframe: Keyframe) -> MotionKeyframe {
        var motionKeyframe = MotionKeyframe()
        motionKeyframe.time = fcpKeyframe.time

        if let posX = fcpKeyframe.positionX, let posY = fcpKeyframe.positionY {
            motionKeyframe.position = MotionPoint3D(x: posX, y: posY, z: 0.0)
        }

        if let scaleX = fcpKeyframe.scaleX, let scaleY = fcpKeyframe.scaleY {
            motionKeyframe.scale = MotionPoint3D(x: scaleX, y: scaleY, z: 1.0)
        }

        if let rotation = fcpKeyframe.rotation {
            motionKeyframe.rotation = MotionPoint3D(x: 0.0, y: 0.0, z: rotation)
        }

        motionKeyframe.opacity = fcpKeyframe.opacity

        return motionKeyframe
    }

    func convertBlendMode(_ fcpBlendMode: String) -> String {
        let blendModeMap: [String: String] = [
            "normal": "Normal",
            "multiply": "Multiply",
            "screen": "Screen",
            "overlay": "Overlay",
            "softlight": "Soft Light",
            "hardlight": "Hard Light",
            "colordodge": "Color Dodge",
            "colorburn": "Color Burn",
            "darken": "Darken",
            "lighten": "Lighten",
            "difference": "Difference",
            "exclusion": "Exclusion",
            "hue": "Hue",
            "saturation": "Saturation",
            "color": "Color",
            "luminosity": "Luminosity"
        ]

        return blendModeMap[fcpBlendMode.lowercased()] ?? "Normal"
    }

    func convertOpacity(_ fcpOpacity: Double) -> Double {
        return max(0.0, min(1.0, fcpOpacity))
    }

    func convertTimingToMotion(offset: Double, duration: Double, frameRate: Double = 29.97) -> MotionTiming {
        var timing = MotionTiming()
        timing.offset = offset
        timing.duration = duration
        timing.trimStart = 0.0
        timing.trimEnd = duration
        return timing
    }

    func normalizeRotation(_ rotation: Double) -> Double {
        var normalizedRotation = rotation.truncatingRemainder(dividingBy: 360.0)
        if normalizedRotation < 0 {
            normalizedRotation += 360.0
        }
        return normalizedRotation
    }

    func degreesToRadians(_ degrees: Double) -> Double {
        return degrees * .pi / 180.0
    }

    func radiansToDegrees(_ radians: Double) -> Double {
        return radians * 180.0 / .pi
    }
}