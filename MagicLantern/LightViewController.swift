import UIKit

/// 灯光控制页：色盘 + 色相条 + 亮度 + 常用色
final class LightViewController: UIViewController, BleListener {

    private let preview = UIView()
    private let wheel = ColorWheelView()
    private let hueBar = HueBarView()
    private let brightnessSlider = UISlider()
    private let brightnessValue = Ui.label("100", size: 14, color: Theme.textPrimary, bold: true)
    private let rgbLabel = Ui.label("", size: 13, color: Theme.textSecondary)
    private var swatchStacks: [UIStackView] = []

    private let presetColors: [Int] = [
        0xFF0000, 0xFF8000, 0xFFFF00, 0x00FF00, 0x00FFFF, 0x0000FF,
        0x8000FF, 0xFF00FF, 0xFFFFFF, 0xFF3D00, 0x7B5CFF, 0x22C55E
    ]
    private let classicColors: [Int] = [
        0xFFE4E1, 0xFFC0CB, 0x9370DB, 0x4169E1, 0x00CED1, 0x3CB371,
        0xFFD700, 0xFFA500, 0xFF6347, 0x8B0000, 0x2F4F4F, 0x000000
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "灯光控制"
        applyGlassBackground()
        BleController.shared.addListener(self)
        setupUi()
        loadState()
    }

    private func setupUi() {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leftAnchor.constraint(equalTo: view.leftAnchor),
            scroll.rightAnchor.constraint(equalTo: view.rightAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let root = Ui.vStack(14)
        root.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(root)
        NSLayoutConstraint.activate([
            root.topAnchor.constraint(equalTo: scroll.topAnchor, constant: 14),
            root.leftAnchor.constraint(equalTo: scroll.leftAnchor, constant: Theme.pad),
            root.rightAnchor.constraint(equalTo: scroll.rightAnchor, constant: -Theme.pad),
            root.bottomAnchor.constraint(equalTo: scroll.bottomAnchor, constant: -24),
            root.widthAnchor.constraint(equalTo: scroll.widthAnchor, constant: -Theme.pad * 2)
        ])

        // ---- 颜色预览 ----
        let previewCard = GlassCard(radius: 18)
        previewCard.showShine(true)
        previewCard.translatesAutoresizingMaskIntoConstraints = false
        previewCard.heightAnchor.constraint(equalToConstant: 56).isActive = true
        preview.translatesAutoresizingMaskIntoConstraints = false
        previewCard.addSubview(preview)
        NSLayoutConstraint.activate([
            preview.topAnchor.constraint(equalTo: previewCard.topAnchor),
            preview.leftAnchor.constraint(equalTo: previewCard.leftAnchor),
            preview.rightAnchor.constraint(equalTo: previewCard.rightAnchor),
            preview.bottomAnchor.constraint(equalTo: previewCard.bottomAnchor)
        ])
        preview.layer.cornerRadius = 12
        root.addArrangedSubview(previewCard)

        // ---- 色盘 ----
        wheel.translatesAutoresizingMaskIntoConstraints = false
        wheel.heightAnchor.constraint(equalTo: wheel.widthAnchor).isActive = true
        root.addArrangedSubview(wheel)

        hueBar.translatesAutoresizingMaskIntoConstraints = false
        hueBar.heightAnchor.constraint(equalToConstant: 22).isActive = true
        root.addArrangedSubview(hueBar)

        // ---- 亮度 ----
        let brightCard = Ui.card()
        let brightStack = Ui.vStack(6)
        brightStack.translatesAutoresizingMaskIntoConstraints = false
        brightCard.addSubview(brightStack)
        NSLayoutConstraint.activate([
            brightStack.topAnchor.constraint(equalTo: brightCard.topAnchor, constant: 12),
            brightStack.leftAnchor.constraint(equalTo: brightCard.leftAnchor, constant: 14),
            brightStack.rightAnchor.constraint(equalTo: brightCard.rightAnchor, constant: -14),
            brightStack.bottomAnchor.constraint(equalTo: brightCard.bottomAnchor, constant: -12)
        ])
        let brightHead = Ui.hStack(8)
        brightHead.addArrangedSubview(Ui.label("亮度", size: 14, color: Theme.textSecondary))
        brightHead.addArrangedSubview(UIView())
        brightHead.addArrangedSubview(brightnessValue)
        brightStack.addArrangedSubview(brightHead)
        brightnessSlider.minimumValue = 0
        brightnessSlider.maximumValue = 100
        brightnessSlider.tintColor = Theme.accent
        brightnessSlider.addTarget(self, action: #selector(brightnessChanged), for: .valueChanged)
        brightnessSlider.addTarget(self, action: #selector(brightnessDone), for: .touchUpInside)
        brightnessSlider.addTarget(self, action: #selector(brightnessDone), for: .touchUpOutside)
        brightStack.addArrangedSubview(brightnessSlider)
        root.addArrangedSubview(brightCard)

        // ---- 常用色 / 经典色 ----
        let colorCard = Ui.card()
        let colorStack = Ui.vStack(10)
        colorStack.translatesAutoresizingMaskIntoConstraints = false
        colorCard.addSubview(colorStack)
        NSLayoutConstraint.activate([
            colorStack.topAnchor.constraint(equalTo: colorCard.topAnchor, constant: 14),
            colorStack.leftAnchor.constraint(equalTo: colorCard.leftAnchor, constant: 14),
            colorStack.rightAnchor.constraint(equalTo: colorCard.rightAnchor, constant: -14),
            colorStack.bottomAnchor.constraint(equalTo: colorCard.bottomAnchor, constant: -14)
        ])
        colorStack.addArrangedSubview(Ui.label("常用色（长按可保存当前颜色）", size: 12, color: Theme.textSecondary))
        let customStack = buildSwatches(Prefs.shared.customColors, custom: true)
        colorStack.addArrangedSubview(customStack)
        swatchStacks.append(customStack)

        colorStack.addArrangedSubview(Ui.label("经典色", size: 12, color: Theme.textSecondary))
        let classicStack = buildSwatches(classicColors, custom: false)
        colorStack.addArrangedSubview(classicStack)
        swatchStacks.append(classicStack)

        let saveButton = makeButton("保存当前颜色为常用色", primary: false)
        saveButton.addTarget(self, action: #selector(saveCurrentColor), for: .touchUpInside)
        colorStack.addArrangedSubview(saveButton)

        let rgbButton = makeButton("RGB 手调", primary: false)
        rgbButton.addTarget(self, action: #selector(openRgbDialog), for: .touchUpInside)
        colorStack.addArrangedSubview(rgbButton)

        root.addArrangedSubview(colorCard)

        // ---- 联动 ----
        wheel.onColorChanged = { [weak self] rgb in
            self?.applyColor(rgb, send: true)
        }
        hueBar.onHueChanged = { [weak self] h in
            guard let self = self else { return }
            self.wheel.setHue(h)
            self.applyColor(self.wheel.color, send: true)
        }
    }

    private func buildSwatches(_ colors: [Int], custom: Bool) -> UIStackView {
        let rows = Ui.vStack(6)
        var i = 0
        while i < colors.count {
            let row = Ui.hStack(6)
            row.distribution = .fillEqually
            for j in 0..<6 {
                let idx = i + j
                if idx >= colors.count { break }
                let sw = UIView()
                sw.backgroundColor = UIColor(rgb: colors[idx])
                sw.layer.cornerRadius = 10
                sw.layer.cornerCurve = .continuous
                sw.layer.borderWidth = 1
                sw.layer.borderColor = UIColor(white: 1, alpha: 0.28).cgColor
                sw.translatesAutoresizingMaskIntoConstraints = false
                sw.heightAnchor.constraint(equalToConstant: 34).isActive = true
                sw.tag = custom ? idx : -1
                let tap = UITapGestureRecognizer(target: self, action: #selector(swatchTapped(_:)))
                sw.addGestureRecognizer(tap)
                if custom {
                    let press = UILongPressGestureRecognizer(target: self, action: #selector(swatchLongPressed(_:)))
                    sw.addGestureRecognizer(press)
                }
                row.addArrangedSubview(sw)
            }
            rows.addArrangedSubview(row)
            i += 6
        }
        return rows
    }

    private func loadState() {
        let c = Prefs.shared.color
        wheel.setColor(c)
        preview.backgroundColor = UIColor(rgb: c)
        var h: CGFloat = 0, s: CGFloat = 0, v: CGFloat = 0, a: CGFloat = 0
        UIColor(rgb: c).getHue(&h, saturation: &s, brightness: &v, alpha: &a)
        hueBar.setHue(h * 360)
        brightnessSlider.value = Float(Prefs.shared.brightness)
        brightnessValue.text = "\(Prefs.shared.brightness)"
        updateRgbLabel(c)
    }

    private func updateRgbLabel(_ rgb: Int) {
        rgbLabel.text = "R \(rgb >> 16 & 0xFF)  G \(rgb >> 8 & 0xFF)  B \(rgb & 0xFF)"
    }

    private func applyColor(_ rgb: Int, send: Bool) {
        preview.backgroundColor = UIColor(rgb: rgb)
        updateRgbLabel(rgb)
        Prefs.shared.color = rgb
        if send {
            LedOutput.sendColor(rgb)
        }
    }

    // ---------------- 交互 ----------------

    @objc private func brightnessChanged() {
        let v = Int(brightnessSlider.value)
        brightnessValue.text = "\(v)"
        Prefs.shared.brightness = v
        LedOutput.setBrightness(v)
    }

    @objc private func brightnessDone() {
        Prefs.shared.brightness = Int(brightnessSlider.value)
        LedOutput.setBrightness(Int(brightnessSlider.value))
    }

    @objc private func swatchTapped(_ g: UITapGestureRecognizer) {
        guard let v = g.view else { return }
        if v.tag >= 0 {
            let colors = Prefs.shared.customColors
            if v.tag < colors.count {
                let c = colors[v.tag]
                if c == 0 {
                    Ui.toast("这一格还没有颜色，先保存一个")
                    return
                }
                wheel.setColor(c)
                var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                UIColor(rgb: c).getHue(&h, saturation: &s, brightness: &b, alpha: &a)
                hueBar.setHue(h * 360)
                applyColor(c, send: true)
            }
        } else {
            // 经典色：从背景色读
            if let bg = v.backgroundColor {
                let c = bg.rgbInt
                wheel.setColor(c)
                var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                bg.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
                hueBar.setHue(h * 360)
                applyColor(c, send: true)
            }
        }
    }

    @objc private func swatchLongPressed(_ g: UILongPressGestureRecognizer) {
        guard g.state == .began, let v = g.view, v.tag >= 0 else { return }
        var colors = Prefs.shared.customColors
        if v.tag >= colors.count { return }
        colors[v.tag] = wheel.color
        Prefs.shared.customColors = colors
        v.backgroundColor = UIColor(rgb: wheel.color)
        Ui.toast("已保存到常用色 \(v.tag + 1)")
    }

    @objc private func saveCurrentColor() {
        var colors = Prefs.shared.customColors
        if let idx = colors.firstIndex(of: 0) {
            colors[idx] = wheel.color
        } else {
            colors.removeFirst()
            colors.append(wheel.color)
        }
        Prefs.shared.customColors = colors
        refreshSwatches()
        applyColor(wheel.color, send: true)
        Ui.toast("已保存并应用")
    }

    private func refreshSwatches() {
        guard let stack = swatchStacks.first else { return }
        let colors = Prefs.shared.customColors
        var idx = 0
        for row in stack.arrangedSubviews {
            guard let hstack = row as? UIStackView else { continue }
            for sw in hstack.arrangedSubviews {
                if idx < colors.count {
                    sw.backgroundColor = UIColor(rgb: colors[idx])
                }
                idx += 1
            }
        }
    }

    @objc private func openRgbDialog() {
        let alert = UIAlertController(title: "RGB 手调", message: nil, preferredStyle: .alert)
        let c = wheel.color
        alert.addTextField { t in
            t.text = "\(c >> 16 & 0xFF)"
            t.keyboardType = .numberPad
            t.placeholder = "R"
        }
        alert.addTextField { t in
            t.text = "\(c >> 8 & 0xFF)"
            t.keyboardType = .numberPad
            t.placeholder = "G"
        }
        alert.addTextField { t in
            t.text = "\(c & 0xFF)"
            t.keyboardType = .numberPad
            t.placeholder = "B"
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确定", style: .default) { [weak self, weak alert] _ in
            guard let self = self, let fields = alert?.textFields, fields.count == 3 else { return }
            let r = max(0, min(255, Int(fields[0].text ?? "") ?? 0))
            let g = max(0, min(255, Int(fields[1].text ?? "") ?? 0))
            let b = max(0, min(255, Int(fields[2].text ?? "") ?? 0))
            let rgb = (r << 16) | (g << 8) | b
            self.wheel.setColor(rgb)
            var h: CGFloat = 0, s: CGFloat = 0, v: CGFloat = 0, a: CGFloat = 0
            UIColor(rgb: rgb).getHue(&h, saturation: &s, brightness: &v, alpha: &a)
            self.hueBar.setHue(h * 360)
            self.applyColor(rgb, send: true)
        })
        present(alert, animated: true)
    }

    private func makeButton(_ title: String, primary: Bool) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        b.setTitleColor(primary ? .white : Theme.textPrimary, for: .normal)
        Glass.styleButton(b, accent: primary)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return b
    }

    // ---------------- BleListener ----------------

    func bleDevicesChanged() {}

    func bleStateChanged(_ device: BleDevice?) {}

    func bleMessage(_ text: String) {}
}
