import Foundation

/// 轻量配置存储（对应 Android 版的 Prefs）
final class Prefs {

    static let shared = Prefs()

    private let d = UserDefaults.standard

    private func int(_ key: String, _ def: Int) -> Int {
        if d.object(forKey: key) == nil { return def }
        return d.integer(forKey: key)
    }

    private func bool(_ key: String, _ def: Bool) -> Bool {
        if d.object(forKey: key) == nil { return def }
        return d.bool(forKey: key)
    }

    var brightness: Int {
        get { return int("brightness", 100) }
        set { d.set(newValue, forKey: "brightness") }
    }

    var speed: Int {
        get { return int("speed", 60) }
        set { d.set(newValue, forKey: "speed") }
    }

    /// 0xRRGGBB
    var color: Int {
        get { return int("color", 0xFF3D00) }
        set { d.set(newValue, forKey: "color") }
    }

    var ledCount: Int {
        get { return int("led_count", 60) }
        set { d.set(newValue, forKey: "led_count") }
    }

    var pinSequence: Int {
        get { return int("pin_sequence", 0) }
        set { d.set(newValue, forKey: "pin_sequence") }
    }

    var autoConnect: Bool {
        get { return bool("auto_connect", true) }
        set { d.set(newValue, forKey: "auto_connect") }
    }

    var nameFilter: Bool {
        get { return bool("name_filter", true) }
        set { d.set(newValue, forKey: "name_filter") }
    }

    var powerOn: Bool {
        get { return bool("power", true) }
        set { d.set(newValue, forKey: "power") }
    }

    var lastDevice: String? {
        get { return d.string(forKey: "last_device") }
        set { d.set(newValue, forKey: "last_device") }
    }

    // ---------------- 常用颜色 ----------------

    var customColors: [Int] {
        get {
            var list = (d.array(forKey: "custom_colors") as? [Int]) ?? []
            while list.count < 12 { list.append(0) }
            return list
        }
        set { d.set(newValue, forKey: "custom_colors") }
    }

    // ---------------- 主页常用模式（"group,cmd"）----------------

    var favModes: [String] {
        get {
            var list = (d.array(forKey: "fav_modes") as? [String]) ?? []
            if list.isEmpty { list = ["0,201"] }
            return list
        }
        set { d.set(newValue, forKey: "fav_modes") }
    }

    func addFavMode(group: Int, cmd: Int) {
        var list = favModes
        let item = "\(group),\(cmd)"
        if list.contains(item) { return }
        list.append(item)
        while list.count > 6 { list.removeFirst() }
        favModes = list
    }

    func removeFavMode(group: Int, cmd: Int) {
        var list = favModes
        let item = "\(group),\(cmd)"
        list.removeAll { $0 == item }
        favModes = list
    }

    // ---------------- 自定义渐变 ----------------

    struct Gradient: Equatable {
        var name: String
        var color1: Int
        var color2: Int
        var speed: Int

        var serialize: String {
            return "\(Gradient.clean(name))|\(color1)|\(color2)|\(speed)"
        }

        static func clean(_ s: String) -> String {
            return s.replacingOccurrences(of: "|", with: "")
                    .replacingOccurrences(of: ";", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        static func parse(_ s: String) -> Gradient? {
            let p = s.components(separatedBy: "|")
            if p.count < 4 { return nil }
            guard let c1 = Int(p[1]), let c2 = Int(p[2]), let sp = Int(p[3]) else { return nil }
            return Gradient(name: p[0], color1: c1, color2: c2, speed: sp)
        }
    }

    var gradients: [Gradient] {
        get {
            let raw = d.string(forKey: "custom_gradients") ?? ""
            if raw.isEmpty { return [] }
            var list: [Gradient] = []
            for part in raw.components(separatedBy: ";") {
                if let g = Gradient.parse(part) { list.append(g) }
            }
            return list
        }
        set {
            let raw = newValue.map { $0.serialize }.joined(separator: ";")
            d.set(raw, forKey: "custom_gradients")
        }
    }

    func saveGradient(oldName: String?, item: Gradient) {
        var list = gradients
        let key = Gradient.clean(item.name)
        list.removeAll { $0.name == key || (oldName != nil && $0.name == oldName!) }
        list.append(item)
        gradients = list
    }

    func removeGradient(_ name: String) {
        var list = gradients
        list.removeAll { $0.name == name }
        gradients = list
    }
}
