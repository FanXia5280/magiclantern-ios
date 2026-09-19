import Foundation

/// 氛围灯 BLE 指令集（与原版 Magic Lantern / Android 版完全一致）
///
/// 服务 0000FFF0，写特征 0000FFF3，帧格式 9 字节：头 0x7E，尾 0xEF
/// 设备广播名前缀：MELK-
enum LedCommand {

    static let nameFilter = "MELK-"

    private static let head: UInt8 = 0x7E
    private static let tail: UInt8 = 0xEF
    private static let fill: UInt8 = 0xFF

    private static func frame(_ len: Int, _ cmd: Int, _ data: [Int]) -> Data {
        var b = [UInt8](repeating: 0, count: 9)
        b[0] = head
        b[1] = UInt8(len & 0xFF)
        b[2] = UInt8(cmd & 0xFF)
        var i = 0
        while i < 7 && i < data.count {
            b[3 + i] = UInt8(data[i] & 0xFF)
            i += 1
        }
        b[8] = tail
        return Data(b)
    }

    /// 开 / 关灯：7E 04 04 on 00 on FF 00 EF
    static func lightOn(_ on: Bool) -> Data {
        let v = on ? 1 : 0
        return frame(4, 4, [v, 0, v, Int(fill), 0])
    }

    /// 亮度 0-100：7E 04 01 b FF FF FF 00 EF
    static func brightness(_ percent: Int) -> Data {
        let b = max(0, min(100, percent))
        return frame(4, 1, [b, Int(fill), Int(fill), Int(fill), 0])
    }

    /// 静态颜色：7E 07 05 03 R G B 10 EF
    static func color(_ r: Int, _ g: Int, _ b: Int) -> Data {
        return frame(7, 5, [3, r, g, b, 0x10])
    }

    /// 律动颜色：7E 07 05 03 R G B 20 EF
    static func rhythmColor(_ r: Int, _ g: Int, _ b: Int) -> Data {
        return frame(7, 5, [3, r, g, b, 0x20])
    }

    /// 灯效模式：7E 05 03 mode 06 FF FF 00 EF
    static func mode(_ m: Int) -> Data {
        return frame(5, 3, [m, 6, Int(fill), Int(fill), 0])
    }

    /// 模式速度 0-100：7E 04 02 speed FF FF FF 00 EF
    static func speed(_ s: Int) -> Data {
        return frame(4, 2, [max(0, min(100, s)), Int(fill), Int(fill), Int(fill), 0])
    }

    /// 场景（第 9 组）：7E 05 31 scene 07 FF FF 01 EF
    static func scene(_ s: Int) -> Data {
        return frame(5, 0x31, [s, 7, Int(fill), Int(fill), 1])
    }

    /// 线序：7E 06 81 b2 b1 b0 FF 00 EF
    static func pinSequence(_ seq: Int) -> Data {
        return frame(6, 0x81, [(seq >> 16) & 0xFF, (seq >> 8) & 0xFF, seq & 0xFF, Int(fill), 0])
    }

    /// 灯带点数：7E 07 21 lo hi 00 FF 00 EF
    static func pixelCount(_ n: Int) -> Data {
        return frame(7, 0x21, [n & 0xFF, (n >> 8) & 0xFF, 0, Int(fill), 0])
    }

    /// RGBW 通道开关：7E 04 04 mask lightMode ch FF 00 EF
    static func rgbwStatus(_ rgbOn: Bool, _ wOn: Bool, _ lightMode: Int, _ ch: Int) -> Data {
        var mask = 0
        if rgbOn { mask |= 0xE0 }
        if wOn { mask |= 0x10 }
        return frame(4, 4, [mask, lightMode & 0xFF, ch & 0xFF, Int(fill), 0])
    }

    /// 冷暖白：7E 06 05 02 warm cold FF 08 EF
    static func colorTemperature(_ warm: Int, _ cold: Int) -> Data {
        return frame(6, 5, [2, warm, cold, Int(fill), 0x08])
    }

    /// 外置麦克风开关：7E 04 07 on FF FF FF 00 EF
    static func externalMic(_ on: Bool) -> Data {
        return frame(4, 7, [on ? 1 : 0, Int(fill), Int(fill), Int(fill), 0])
    }
}
