import Foundation
import UIKit

/// 灯光输出统一出口（指令格式与 Android 版一致）
enum LedOutput {

    /// 线序值：1=R 2=G 3=B，按 (ch1<<16)|(ch2<<8)|ch3
    private static let pinSequences = [
        0x010203, // R G B
        0x010302, // R B G
        0x020103, // G R B
        0x020301, // G B R
        0x030102, // B R G
        0x030201  // B G R
    ]

    static func pinValue() -> Int {
        let i = max(0, min(5, Prefs.shared.pinSequence))
        return pinSequences[i]
    }

    private static func sendChannels(_ ch: [Int]) {
        let v = pinValue()
        let c1 = (v >> 16) & 0xFF
        let c2 = (v >> 8) & 0xFF
        let c3 = v & 0xFF
        BleController.shared.send(LedCommand.color(ch[c1 - 1], ch[c2 - 1], ch[c3 - 1]))
    }

    /// 静态颜色（0xRRGGBB，用户主动操作：停止自定义渐变）
    static func sendColor(_ rgb: Int) {
        GradientPlayer.shared.stop()
        sendRawColor(rgb)
    }

    /// 直接发色（渐变播放器内部使用）
    static func sendRawColor(_ rgb: Int) {
        sendChannels([(rgb >> 16) & 0xFF, (rgb >> 8) & 0xFF, rgb & 0xFF])
    }

    static func setBrightness(_ percent: Int) {
        BleController.shared.send(LedCommand.brightness(percent))
    }

    /// 灯效模式：第 9 组（场景）走 scene 帧，其余走 mode 帧
    static func sendMode(group: Int, value: Int, speed: Int) {
        GradientPlayer.shared.stop()
        if group == 8 {
            BleController.shared.send(LedCommand.scene(value))
        } else {
            BleController.shared.send(LedCommand.mode(value))
        }
        BleController.shared.send(LedCommand.speed(speed))
    }

    static func sendSpeed(_ speed: Int) {
        BleController.shared.send(LedCommand.speed(speed))
    }

    /// 开 / 关灯
    static func power(_ on: Bool) {
        GradientPlayer.shared.stop()
        let p = Prefs.shared
        p.powerOn = on
        let ble = BleController.shared
        if on {
            ble.send(LedCommand.lightOn(true))
            ble.send(LedCommand.brightness(p.brightness))
            ble.send(LedCommand.color((p.color >> 16) & 0xFF, (p.color >> 8) & 0xFF, p.color & 0xFF))
        } else {
            ble.send(LedCommand.lightOn(false))
            ble.send(LedCommand.rgbwStatus(false, false, 0, 0))
            ble.send(LedCommand.brightness(0))
        }
    }

    static func sendPinSequence() {
        BleController.shared.send(LedCommand.pinSequence(pinValue()))
    }

    static func sendPixelCount(_ count: Int) {
        BleController.shared.send(LedCommand.pixelCount(count))
    }
}

/// 自定义渐变播放器（App 端每 ~70ms 下发一帧插值颜色）
final class GradientPlayer {

    static let shared = GradientPlayer()

    private var timer: Timer?
    private var item: Prefs.Gradient?
    private var phase: Double = 0
    private var dir: Double = 1

    private init() {}

    var isPlaying: Bool { return item != nil }

    var playingName: String? { return item?.name }

    func play(_ g: Prefs.Gradient) {
        item = g
        phase = 0
        dir = 1
        timer?.invalidate()
        let t = Timer(timeInterval: 0.07, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
        tick()
    }

    func stop() {
        item = nil
        timer?.invalidate()
        timer = nil
    }

    func applySpeed(_ g: Prefs.Gradient) {
        if item?.name == g.name { item?.speed = g.speed }
    }

    func replace(oldName: String, with g: Prefs.Gradient) {
        if item?.name == oldName { item = g }
    }

    private func tick() {
        guard let g = item else { return }
        LedOutput.sendRawColor(GradientPlayer.lerp(g.color1, g.color2, phase))
        let step = 0.010 + Double(g.speed) / 100.0 * 0.045
        phase += dir * step
        if phase >= 1 {
            phase = 1
            dir = -1
        } else if phase <= 0 {
            phase = 0
            dir = 1
        }
    }

    /// 两色线性插值（0xRRGGBB）
    static func lerp(_ c1: Int, _ c2: Int, _ t: Double) -> Int {
        let r1 = Double((c1 >> 16) & 0xFF), g1 = Double((c1 >> 8) & 0xFF), b1 = Double(c1 & 0xFF)
        let r2 = Double((c2 >> 16) & 0xFF), g2 = Double((c2 >> 8) & 0xFF), b2 = Double(c2 & 0xFF)
        let r = Int(r1 * (1 - t) + r2 * t + 0.5)
        let g = Int(g1 * (1 - t) + g2 * t + 0.5)
        let b = Int(b1 * (1 - t) + b2 * t + 0.5)
        return (r << 16) | (g << 8) | b
    }
}
