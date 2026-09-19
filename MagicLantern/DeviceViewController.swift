import UIKit

/// 设备管理：扫描并连接灯具
final class DeviceViewController: UIViewController, BleListener, UITableViewDataSource, UITableViewDelegate {

    private let table = UITableView()
    private let scanButton = UIButton(type: .system)
    private let hintLabel = Ui.label("", size: 13, color: Theme.textSecondary)
    private let refreshControl = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "设备管理"
        applyGlassBackground()
        BleController.shared.addListener(self)
        setupUi()
        refreshUi()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 进来自动开始搜索，省一步操作
        let ble = BleController.shared
        if !ble.scanning && ble.connected.isEmpty {
            ble.startScan()
            refreshUi()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        BleController.shared.stopScan()
    }

    private func setupUi() {
        let head = Ui.vStack(10)
        head.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(head)

        scanButton.setTitle("开始搜索", for: .normal)
        scanButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        scanButton.setTitleColor(.white, for: .normal)
        scanButton.backgroundColor = Theme.accent
        scanButton.layer.cornerRadius = 12
        scanButton.translatesAutoresizingMaskIntoConstraints = false
        scanButton.heightAnchor.constraint(equalToConstant: 46).isActive = true
        scanButton.addTarget(self, action: #selector(toggleScan), for: .touchUpInside)
        head.addArrangedSubview(scanButton)
        head.addArrangedSubview(hintLabel)

        table.translatesAutoresizingMaskIntoConstraints = false
        table.backgroundColor = .clear
        table.separatorColor = .hairline
        table.dataSource = self
        table.delegate = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        refreshControl.tintColor = Theme.textSecondary
        refreshControl.addTarget(self, action: #selector(toggleScan), for: .valueChanged)
        table.refreshControl = refreshControl
        view.addSubview(table)

        NSLayoutConstraint.activate([
            head.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            head.leftAnchor.constraint(equalTo: view.leftAnchor, constant: Theme.pad),
            head.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -Theme.pad),

            table.topAnchor.constraint(equalTo: head.bottomAnchor, constant: 12),
            table.leftAnchor.constraint(equalTo: view.leftAnchor),
            table.rightAnchor.constraint(equalTo: view.rightAnchor),
            table.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func refreshUi() {
        let ble = BleController.shared
        scanButton.setTitle(ble.scanning ? "停止搜索" : "开始搜索", for: .normal)
        if ble.bluetoothOff {
            hintLabel.text = "蓝牙未开启，请到系统设置里打开蓝牙"
        } else if ble.connected.isEmpty {
            hintLabel.text = ble.scanning ? "正在搜索 MELK- 开头的灯具…" : "点击开始搜索灯具"
        } else {
            hintLabel.text = "已连接：\(ble.connectionSummary)"
        }
        table.reloadData()
        if !ble.scanning {
            refreshControl.endRefreshing()
        }
    }

    @objc private func toggleScan() {
        let ble = BleController.shared
        if ble.scanning {
            ble.stopScan()
        } else {
            ble.startScan()
        }
        refreshUi()
    }

    // ---------------- 表格 ----------------

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return BleController.shared.devices.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var reusable = tableView.dequeueReusableCell(withIdentifier: "cell")
        if reusable == nil {
            reusable = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        }
        let cell = reusable!
        let devices = BleController.shared.devices
        guard indexPath.row < devices.count else { return cell }
        let d = devices[indexPath.row]
        cell.backgroundColor = .clear
        cell.textLabel?.text = d.name
        cell.textLabel?.textColor = Theme.textPrimary
        cell.detailTextLabel?.text = "\(d.stateText) · 信号 \(d.rssi)"
        cell.detailTextLabel?.textColor = Theme.textSecondary
        if d.state == .connected {
            cell.accessoryView = Ui.label("已连接", size: 13, color: Theme.accent, bold: true)
        } else {
            cell.accessoryView = Ui.label("点击连接", size: 13, color: Theme.textThird)
        }
        let bg = UIView()
        bg.backgroundColor = .subtleFill
        cell.selectedBackgroundView = bg
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let ble = BleController.shared
        let devices = ble.devices
        guard indexPath.row < devices.count else { return }
        let d = devices[indexPath.row]
        if d.state == .connected {
            ble.disconnect(d)
        } else if d.state == .connecting {
            Ui.toast("正在连接…")
        } else {
            ble.connect(d)
        }
        refreshUi()
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return BleController.shared.devices.isEmpty ? nil : "搜索到的设备"
    }

    // ---------------- BleListener ----------------

    func bleDevicesChanged() {
        refreshUi()
    }

    func bleStateChanged(_ device: BleDevice?) {
        refreshUi()
    }

    func bleMessage(_ text: String) {
        refreshUi()
    }
}
