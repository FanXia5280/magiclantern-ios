import UIKit

/// 设置页：点数 / 线序 / 自动连接 / 设备过滤 / 关于
final class SettingsViewController: UIViewController, BleListener {

    private let countValue = Ui.label("", size: 13, color: Theme.textSecondary)
    private let seqValue = Ui.label("", size: 13, color: Theme.textSecondary)
    private let btValue = Ui.label("", size: 13, color: Theme.textSecondary)
    private let autoSwitch = UISwitch()
    private let filterSwitch = UISwitch()

    private let seqNames = ["R G B", "R B G", "G R B", "G B R", "B R G", "B G R"]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "设置"
        applyGlassBackground()
        BleController.shared.addListener(self)
        setupUi()
        refresh()
    }

    private func setupUi() {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)

        let root = Ui.vStack(14)
        root.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(root)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leftAnchor.constraint(equalTo: view.leftAnchor),
            scroll.rightAnchor.constraint(equalTo: view.rightAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            root.topAnchor.constraint(equalTo: scroll.topAnchor, constant: 14),
            root.leftAnchor.constraint(equalTo: scroll.leftAnchor, constant: Theme.pad),
            root.rightAnchor.constraint(equalTo: scroll.rightAnchor, constant: -Theme.pad),
            root.bottomAnchor.constraint(equalTo: scroll.bottomAnchor, constant: -24),
            root.widthAnchor.constraint(equalTo: scroll.widthAnchor, constant: -Theme.pad * 2)
        ])

        // ---- 常规设置 ----
        root.addArrangedSubview(sectionTitle("常规设置"))
        let card1 = Ui.card()
        let inner1 = Ui.vStack(0)
        inner1.translatesAutoresizingMaskIntoConstraints = false
        card1.addSubview(inner1)
        NSLayoutConstraint.activate([
            inner1.topAnchor.constraint(equalTo: card1.topAnchor, constant: 6),
            inner1.leftAnchor.constraint(equalTo: card1.leftAnchor, constant: 14),
            inner1.rightAnchor.constraint(equalTo: card1.rightAnchor, constant: -14),
            inner1.bottomAnchor.constraint(equalTo: card1.bottomAnchor, constant: -6)
        ])

        inner1.addArrangedSubview(row(title: "灯带总点数", sub: countValue, action: { [weak self] in
            self?.editCount()
        }))
        inner1.addArrangedSubview(divider())
        inner1.addArrangedSubview(row(title: "调整线序", sub: seqValue, action: { [weak self] in
            self?.editSequence()
        }))
        inner1.addArrangedSubview(divider())

        autoSwitch.isOn = Prefs.shared.autoConnect
        autoSwitch.onTintColor = Theme.accent
        autoSwitch.addTarget(self, action: #selector(autoChanged), for: .valueChanged)
        inner1.addArrangedSubview(switchRow(title: "自动连接设备", sub: "启动后自动连接上次设备",
                                            sw: autoSwitch))
        inner1.addArrangedSubview(divider())

        filterSwitch.isOn = Prefs.shared.nameFilter
        filterSwitch.onTintColor = Theme.accent
        filterSwitch.addTarget(self, action: #selector(filterChanged), for: .valueChanged)
        inner1.addArrangedSubview(switchRow(title: "仅显示灯具设备", sub: "只列出 MELK- 开头的设备",
                                            sw: filterSwitch))
        root.addArrangedSubview(card1)

        // ---- 设备管理 ----
        root.addArrangedSubview(sectionTitle("设备管理"))
        let card2 = Ui.card()
        let inner2 = Ui.vStack(0)
        inner2.translatesAutoresizingMaskIntoConstraints = false
        card2.addSubview(inner2)
        NSLayoutConstraint.activate([
            inner2.topAnchor.constraint(equalTo: card2.topAnchor, constant: 6),
            inner2.leftAnchor.constraint(equalTo: card2.leftAnchor, constant: 14),
            inner2.rightAnchor.constraint(equalTo: card2.rightAnchor, constant: -14),
            inner2.bottomAnchor.constraint(equalTo: card2.bottomAnchor, constant: -6)
        ])
        inner2.addArrangedSubview(row(title: "蓝牙连接", sub: btValue, action: { [weak self] in
            let vc = DeviceViewController()
            self?.navigationController?.pushViewController(vc, animated: true)
        }))
        inner2.addArrangedSubview(divider())
        inner2.addArrangedSubview(row(title: "断开全部设备", sub: nil, action: {
            BleController.shared.disconnectAll()
            Ui.toast("已断开全部设备")
        }))
        root.addArrangedSubview(card2)

        // ---- 关于 ----
        root.addArrangedSubview(sectionTitle("关于"))
        let card3 = Ui.card()
        let inner3 = Ui.vStack(0)
        inner3.translatesAutoresizingMaskIntoConstraints = false
        card3.addSubview(inner3)
        NSLayoutConstraint.activate([
            inner3.topAnchor.constraint(equalTo: card3.topAnchor, constant: 6),
            inner3.leftAnchor.constraint(equalTo: card3.leftAnchor, constant: 14),
            inner3.rightAnchor.constraint(equalTo: card3.rightAnchor, constant: -14),
            inner3.bottomAnchor.constraint(equalTo: card3.bottomAnchor, constant: -6)
        ])
        inner3.addArrangedSubview(row(title: "关于本应用", sub: Ui.label("版本 1.0.0", size: 13,
                                                                     color: Theme.textSecondary),
                                      action: { [weak self] in self?.showAbout() }))
        root.addArrangedSubview(card3)

        // 附带说明
        let tip = Ui.label("提示：自定义渐变需要 App 保持运行；\n「场景 → 双色流动」里的固件效果发一次就永久生效，关掉 App 也照常执行。",
                           size: 12, color: Theme.textThird)
        root.addArrangedSubview(tip)
    }

    private func sectionTitle(_ text: String) -> UILabel {
        let l = Ui.label(text, size: 13, color: Theme.textSecondary)
        l.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return l
    }

    private func divider() -> UIView {
        let v = UIView()
        v.backgroundColor = UIColor(white: 1, alpha: 0.07)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return v
    }

    private func row(title: String, sub: UILabel?, action: (() -> Void)?) -> UIView {
        let b = MButton(type: .system)
        b.action = action
        b.backgroundColor = .clear
        let stack = Ui.hStack(10)
        let col = Ui.vStack(3)
        let t = Ui.label(title, size: 15, color: Theme.textPrimary)
        col.addArrangedSubview(t)
        if let s = sub {
            s.text = ""
            col.addArrangedSubview(s)
        }
        stack.addArrangedSubview(col)
        stack.addArrangedSubview(UIView())
        stack.addArrangedSubview(Ui.label("›", size: 20, color: Theme.textThird))
        stack.isUserInteractionEnabled = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        b.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: b.topAnchor, constant: 12),
            stack.leftAnchor.constraint(equalTo: b.leftAnchor),
            stack.rightAnchor.constraint(equalTo: b.rightAnchor),
            stack.bottomAnchor.constraint(equalTo: b.bottomAnchor, constant: -12)
        ])
        b.addTarget(b, action: #selector(MButton.fire), for: .touchUpInside)
        return b
    }

    private func switchRow(title: String, sub: String, sw: UISwitch) -> UIView {
        let v = UIView()
        let stack = Ui.hStack(10)
        let col = Ui.vStack(3)
        col.addArrangedSubview(Ui.label(title, size: 15, color: Theme.textPrimary))
        col.addArrangedSubview(Ui.label(sub, size: 12, color: Theme.textSecondary))
        stack.addArrangedSubview(col)
        stack.addArrangedSubview(UIView())
        stack.addArrangedSubview(sw)
        stack.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: v.topAnchor, constant: 10),
            stack.leftAnchor.constraint(equalTo: v.leftAnchor),
            stack.rightAnchor.constraint(equalTo: v.rightAnchor),
            stack.bottomAnchor.constraint(equalTo: v.bottomAnchor, constant: -10)
        ])
        return v
    }

    // ---------------- 交互 ----------------

    @objc private func autoChanged() {
        Prefs.shared.autoConnect = autoSwitch.isOn
    }

    @objc private func filterChanged() {
        Prefs.shared.nameFilter = filterSwitch.isOn
        BleController.shared.clearFound()
    }

    private func editCount() {
        let alert = UIAlertController(title: "灯带总点数", message: "请输入灯带上的灯珠数量",
                                      preferredStyle: .alert)
        alert.addTextField { t in
            t.text = "\(Prefs.shared.ledCount)"
            t.keyboardType = .numberPad
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确定", style: .default) { [weak self, weak alert] _ in
            let text = alert?.textFields?.first?.text ?? ""
            let n = max(1, min(2000, Int(text) ?? 60))
            Prefs.shared.ledCount = n
            LedOutput.sendPixelCount(n)
            self?.refresh()
            Ui.toast("已设置 \(n) 点")
        })
        present(alert, animated: true)
    }

    private func editSequence() {
        let sheet = UIAlertController(title: "调整线序", message: "如果颜色显示不对，换一个线序试试",
                                      preferredStyle: .actionSheet)
        for (i, name) in seqNames.enumerated() {
            let title = (i == Prefs.shared.pinSequence ? "✓ " : "") + name
            sheet.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                Prefs.shared.pinSequence = i
                LedOutput.sendPinSequence()
                self?.refresh()
                Ui.toast("线序已设为 \(name)")
            })
        }
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        if let pop = sheet.popoverPresentationController {
            pop.sourceView = view
            pop.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
        }
        present(sheet, animated: true)
    }

    private func showAbout() {
        let alert = UIAlertController(title: "氛围灯控制",
                                      message: "版本 1.0.0\n\n支持 BLE 蓝牙灯控：调色、灯效模式、双色流动、自定义渐变、定时。",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }

    private func refresh() {
        countValue.text = "\(Prefs.shared.ledCount) 点"
        seqValue.text = seqNames[max(0, min(seqNames.count - 1, Prefs.shared.pinSequence))]
        btValue.text = BleController.shared.connectionSummary
        if autoSwitch.isOn != Prefs.shared.autoConnect {
            autoSwitch.isOn = Prefs.shared.autoConnect
        }
        if filterSwitch.isOn != Prefs.shared.nameFilter {
            filterSwitch.isOn = Prefs.shared.nameFilter
        }
    }

    // ---------------- BleListener ----------------

    func bleDevicesChanged() { refresh() }
    func bleStateChanged(_ device: BleDevice?) { refresh() }
    func bleMessage(_ text: String) { refresh() }
}
