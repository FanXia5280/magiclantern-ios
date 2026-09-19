import UIKit

/// 主页：连接状态 + 电源开关 + 快捷入口 + 常用模式
final class HomeViewController: UIViewController, BleListener {

    private let statusDot = UIView()
    private let statusLabel = Ui.label("未连接", size: 15, color: Theme.textPrimary, bold: true)
    private let subLabel = Ui.label("点击下方按钮搜索灯具", size: 12, color: Theme.textSecondary)
    private let powerButton = UIButton(type: .system)
    private let connectButton = UIButton(type: .system)
    private let favStack = Ui.vStack(10)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "氛围灯控制"
        view.backgroundColor = Theme.bg
        BleController.shared.addListener(self)
        BleController.shared.start()
        setupUi()
        refreshState()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshState()
        refreshFavs()
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

        // ---- 状态卡 ----
        let statusCard = Ui.card()
        let statusInner = Ui.vStack(12)
        statusInner.translatesAutoresizingMaskIntoConstraints = false
        statusCard.addSubview(statusInner)
        NSLayoutConstraint.activate([
            statusInner.topAnchor.constraint(equalTo: statusCard.topAnchor, constant: 16),
            statusInner.leftAnchor.constraint(equalTo: statusCard.leftAnchor, constant: 16),
            statusInner.rightAnchor.constraint(equalTo: statusCard.rightAnchor, constant: -16),
            statusInner.bottomAnchor.constraint(equalTo: statusCard.bottomAnchor, constant: -16)
        ])

        let head = Ui.hStack(10)
        statusDot.backgroundColor = Theme.textThird
        statusDot.layer.cornerRadius = 6
        statusDot.translatesAutoresizingMaskIntoConstraints = false
        statusDot.widthAnchor.constraint(equalToConstant: 12).isActive = true
        statusDot.heightAnchor.constraint(equalToConstant: 12).isActive = true
        head.addArrangedSubview(statusDot)
        let headText = Ui.vStack(4)
        headText.addArrangedSubview(statusLabel)
        headText.addArrangedSubview(subLabel)
        head.addArrangedSubview(headText)
        head.addArrangedSubview(UIView())

        powerButton.setTitle("开灯", for: .normal)
        powerButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        powerButton.setTitleColor(.white, for: .normal)
        powerButton.backgroundColor = Theme.accent
        powerButton.layer.cornerRadius = 12
        powerButton.translatesAutoresizingMaskIntoConstraints = false
        powerButton.widthAnchor.constraint(equalToConstant: 92).isActive = true
        powerButton.heightAnchor.constraint(equalToConstant: 42).isActive = true
        powerButton.addTarget(self, action: #selector(togglePower), for: .touchUpInside)
        head.addArrangedSubview(powerButton)
        statusInner.addArrangedSubview(head)

        connectButton.setTitle("搜索并连接灯具", for: .normal)
        connectButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        connectButton.setTitleColor(Theme.textPrimary, for: .normal)
        connectButton.backgroundColor = UIColor(white: 1, alpha: 0.06)
        connectButton.layer.cornerRadius = 12
        connectButton.translatesAutoresizingMaskIntoConstraints = false
        connectButton.heightAnchor.constraint(equalToConstant: 46).isActive = true
        connectButton.addTarget(self, action: #selector(openDevices), for: .touchUpInside)
        statusInner.addArrangedSubview(connectButton)

        root.addArrangedSubview(statusCard)

        // ---- 快捷入口 ----
        root.addArrangedSubview(Ui.label("快捷功能", size: 13, color: Theme.textSecondary))
        let quickCard = Ui.card()
        let quickInner = Ui.vStack(12)
        quickInner.translatesAutoresizingMaskIntoConstraints = false
        quickCard.addSubview(quickInner)
        NSLayoutConstraint.activate([
            quickInner.topAnchor.constraint(equalTo: quickCard.topAnchor, constant: 14),
            quickInner.leftAnchor.constraint(equalTo: quickCard.leftAnchor, constant: 14),
            quickInner.rightAnchor.constraint(equalTo: quickCard.rightAnchor, constant: -14),
            quickInner.bottomAnchor.constraint(equalTo: quickCard.bottomAnchor, constant: -14)
        ])
        let row1 = Ui.hStack(10)
        row1.distribution = .fillEqually
        row1.addArrangedSubview(quickButton("灯光控制", 0xFF4A6CF7) { [weak self] in
            self?.tabBarController?.selectedIndex = 1
        })
        row1.addArrangedSubview(quickButton("场景模式", 0xFF7B5CFF) { [weak self] in
            self?.tabBarController?.selectedIndex = 2
        })
        quickInner.addArrangedSubview(row1)
        let row2 = Ui.hStack(10)
        row2.distribution = .fillEqually
        row2.addArrangedSubview(quickButton("设备管理", 0xFF22C55E) { [weak self] in
            self?.openDevices()
        })
        row2.addArrangedSubview(quickButton("设置", 0xFFF59E0B) { [weak self] in
            self?.tabBarController?.selectedIndex = 3
        })
        quickInner.addArrangedSubview(row2)
        root.addArrangedSubview(quickCard)

        // ---- 常用模式 ----
        root.addArrangedSubview(Ui.label("常用模式（去场景页长按可添加）", size: 13, color: Theme.textSecondary))
        let favCard = Ui.card()
        favStack.translatesAutoresizingMaskIntoConstraints = false
        favCard.addSubview(favStack)
        NSLayoutConstraint.activate([
            favStack.topAnchor.constraint(equalTo: favCard.topAnchor, constant: 14),
            favStack.leftAnchor.constraint(equalTo: favCard.leftAnchor, constant: 14),
            favStack.rightAnchor.constraint(equalTo: favCard.rightAnchor, constant: -14),
            favStack.bottomAnchor.constraint(equalTo: favCard.bottomAnchor, constant: -14)
        ])
        root.addArrangedSubview(favCard)

        refreshFavs()
    }

    private func quickButton(_ title: String, _ color: Int, action: @escaping () -> Void) -> UIButton {
        let b = MButton(type: .system)
        b.action = action
        b.setTitle(title, for: .normal)
        b.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = UIColor(rgb: color)
        b.layer.cornerRadius = 12
        b.translatesAutoresizingMaskIntoConstraints = false
        b.heightAnchor.constraint(equalToConstant: 52).isActive = true
        b.addTarget(b, action: #selector(MButton.fire), for: .touchUpInside)
        return b
    }

    private func refreshFavs() {
        for v in favStack.arrangedSubviews { v.removeFromSuperview() }
        let favs = Prefs.shared.favModes
        if favs.isEmpty {
            favStack.addArrangedSubview(Ui.label("暂无常用模式", size: 13, color: Theme.textThird))
            return
        }
        var row: UIStackView?
        for (idx, item) in favs.enumerated() {
            let parts = item.components(separatedBy: ",")
            guard parts.count == 2, let g = Int(parts[0]), let cmd = Int(parts[1]) else { continue }
            if idx % 2 == 0 {
                let r = Ui.hStack(10)
                r.distribution = .fillEqually
                favStack.addArrangedSubview(r)
                row = r
            }
            let name = ModeData.name(group: g, cmd: cmd)
            let b = MButton(type: .system)
            b.action = {
                LedOutput.sendMode(group: g, value: cmd, speed: Prefs.shared.speed)
                Ui.toast("已应用：\(name)")
            }
            b.setTitle(name, for: .normal)
            b.titleLabel?.font = UIFont.systemFont(ofSize: 14)
            b.setTitleColor(Theme.textPrimary, for: .normal)
            b.backgroundColor = Theme.cardInner
            b.layer.cornerRadius = 12
            b.translatesAutoresizingMaskIntoConstraints = false
            b.heightAnchor.constraint(equalToConstant: 46).isActive = true
            b.addTarget(b, action: #selector(MButton.fire), for: .touchUpInside)
            row?.addArrangedSubview(b)
        }
        if let last = favStack.arrangedSubviews.last as? UIStackView, last.arrangedSubviews.count == 1 {
            let ghost = UIView()
            ghost.translatesAutoresizingMaskIntoConstraints = false
            ghost.heightAnchor.constraint(equalToConstant: 46).isActive = true
            last.addArrangedSubview(ghost)
        }
    }

    private func refreshState() {
        let ble = BleController.shared
        if ble.bluetoothOff {
            statusLabel.text = "蓝牙未开启"
            subLabel.text = "请在系统设置中打开蓝牙"
            statusDot.backgroundColor = Theme.textThird
        } else if ble.connected.isEmpty {
            statusLabel.text = "未连接"
            subLabel.text = "点击下方按钮搜索灯具"
            statusDot.backgroundColor = Theme.textThird
        } else {
            statusLabel.text = ble.connectionSummary
            subLabel.text = "已连接 \(ble.connected.count) 台设备"
            statusDot.backgroundColor = Theme.accent
        }
        let on = Prefs.shared.powerOn
        powerButton.setTitle(on ? "关灯" : "开灯", for: .normal)
        powerButton.backgroundColor = on ? Theme.accent : UIColor(white: 1, alpha: 0.12)
        connectButton.setTitle(ble.scanning ? "正在搜索…（点此查看）" : "搜索并连接灯具", for: .normal)
    }

    @objc private func togglePower() {
        let next = !Prefs.shared.powerOn
        LedOutput.power(next)
        refreshState()
        Ui.toast(next ? "已开灯" : "已关灯")
    }

    @objc private func openDevices() {
        let vc = DeviceViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    // ---------------- BleListener ----------------

    func bleDevicesChanged() {
        refreshState()
    }

    func bleStateChanged(_ device: BleDevice?) {
        refreshState()
    }

    func bleMessage(_ text: String) {
        refreshState()
    }
}

/// 带闭包的按钮（避免到处写 objc 方法）
final class MButton: UIButton {
    var action: (() -> Void)?

    @objc func fire() {
        action?()
    }
}
