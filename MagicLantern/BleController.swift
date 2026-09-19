import Foundation
import CoreBluetooth

enum BleState {
    case idle
    case connecting
    case connected
    case failed
}

/// 一台设备（iOS 拿不到 MAC 地址，用系统分配的 UUID 做唯一标识）
final class BleDevice {
    let peripheral: CBPeripheral
    var name: String
    var identifier: String
    var rssi: Int
    var state: BleState = .idle
    var writeChar: CBCharacteristic?

    init(peripheral: CBPeripheral, name: String, rssi: Int) {
        self.peripheral = peripheral
        self.name = name
        self.rssi = rssi
        self.identifier = peripheral.identifier.uuidString
    }

    var stateText: String {
        switch state {
        case .idle: return "未连接"
        case .connecting: return "连接中…"
        case .connected: return "已连接"
        case .failed: return "连接失败"
        }
    }
}

protocol BleListener: AnyObject {
    func bleDevicesChanged()
    func bleStateChanged(_ device: BleDevice?)
    func bleMessage(_ text: String)
}

/// BLE 控制器（对应 Android 版的 BleController）
final class BleController: NSObject {

    static let shared = BleController()

    private let listeners = NSHashTable<AnyObject>.weakObjects()

    private var central: CBCentralManager?
    private(set) var devices: [BleDevice] = []
    private(set) var connected: [BleDevice] = []
    private var all: [UUID: BleDevice] = [:]
    private(set) var scanning = false
    private var autoConnectTarget: String?
    private var autoConnectBusy = false

    private let chrWrite = CBUUID(string: "FFF3")
    private let chrWrite4 = CBUUID(string: "FFF4")
    private let chrWrite2 = CBUUID(string: "FFF2")

    private override init() {
        super.init()
    }

    // ---------------- 监听 ----------------

    func addListener(_ l: BleListener) {
        listeners.add(l)
    }

    private func notifyDevices() {
        for case let l as BleListener in listeners.allObjects { l.bleDevicesChanged() }
    }

    private func notifyState(_ d: BleDevice?) {
        for case let l as BleListener in listeners.allObjects { l.bleStateChanged(d) }
    }

    private func notifyMessage(_ t: String) {
        for case let l as BleListener in listeners.allObjects { l.bleMessage(t) }
    }

    // ---------------- 状态 ----------------

    func start() {
        if central == nil {
            central = CBCentralManager(delegate: self, queue: nil)
        }
    }

    var isReady: Bool { return central?.state == .poweredOn }

    var bluetoothOff: Bool {
        guard let s = central?.state else { return false }
        return s == .poweredOff || s == .unauthorized
    }

    var connectionSummary: String {
        let names = connected.map { $0.name }
        if names.isEmpty { return "未连接" }
        if names.count == 1 { return names[0] }
        return "已连接 \(names.count) 台设备"
    }

    // ---------------- 扫描 ----------------

    func startScan(autoConnectIdentifier: String? = nil) {
        guard let c = central, c.state == .poweredOn else { return }
        devices.removeAll()
        all.removeAll()
        autoConnectTarget = autoConnectIdentifier
        autoConnectBusy = autoConnectIdentifier != nil
        scanning = true
        c.scanForPeripherals(withServices: nil,
                             options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        notifyDevices()
    }

    func stopScan() {
        scanning = false
        central?.stopScan()
    }

    func clearFound() {
        devices.removeAll()
        all.removeAll()
        notifyDevices()
    }

    // ---------------- 连接 ----------------

    func connect(_ device: BleDevice) {
        guard let c = central else { return }
        device.state = .connecting
        all[device.peripheral.identifier] = device
        c.connect(device.peripheral, options: nil)
        notifyState(device)
    }

    func disconnect(_ device: BleDevice) {
        central?.cancelPeripheralConnection(device.peripheral)
    }

    func disconnectAll() {
        for d in connected {
            central?.cancelPeripheralConnection(d.peripheral)
        }
    }

    private func deviceFor(_ peripheral: CBPeripheral) -> BleDevice {
        if let d = all[peripheral.identifier] { return d }
        let d = BleDevice(peripheral: peripheral, name: peripheral.name ?? "未命名", rssi: 0)
        all[peripheral.identifier] = d
        return d
    }

    // ---------------- 发送（串行队列，保证顺序与可靠性）----------------

    private struct PendingWrite {
        let data: Data
        let device: BleDevice
    }

    private var pending: [PendingWrite] = []
    private var writeBusy = false
    private var writeTimeoutTask: DispatchWorkItem?

    func send(_ data: Data) {
        for d in connected {
            enqueue(data, to: d)
        }
    }

    func send(_ data: Data, to device: BleDevice) {
        enqueue(data, to: device)
    }

    private func enqueue(_ data: Data, to device: BleDevice) {
        DispatchQueue.main.async {
            self.pending.append(PendingWrite(data: data, device: device))
            self.pumpWrite()
        }
    }

    /// 逐条串行下发。
    ///
    /// 两个要点：
    /// 1. 优先"有响应写"（.withResponse）——原版 Android 用的是默认的
    ///    WRITE_TYPE_DEFAULT（有响应），有链路层确认和重传；
    ///    之前用 withoutResponse 时命令没有确认，设备偶尔会把状态丢掉，
    ///    表现就是开关按下去"亮一下又跳回去"。
    /// 2. 有响应写同一特征同时只允许一个未完成请求，所以必须排队等回调；
    ///    无响应写没有回调，用一个很短的间隔放行，避免打爆链路缓冲导致丢包。
    private func pumpWrite() {
        guard !writeBusy, !pending.isEmpty else { return }
        let item = pending.removeFirst()
        guard let chr = item.device.writeChar,
              item.device.peripheral.state == .connected else {
            pumpWrite()
            return
        }
        writeBusy = true
        let type: CBCharacteristicWriteType = chr.properties.contains(.write)
            ? .withResponse : .withoutResponse
        item.device.peripheral.writeValue(item.data, for: chr, type: type)
        if type == .withoutResponse {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
                self.writeBusy = false
                self.pumpWrite()
            }
        } else {
            // 有响应写正常会在 didWriteValueFor 回调里放行；
            // 万一回调丢失（链路异常/对端无响应），1.5s 超时兜底，避免队列卡死
            writeTimeoutTask?.cancel()
            let task = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                self.writeBusy = false
                self.pumpWrite()
            }
            writeTimeoutTask = task
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: task)
        }
    }

    /// 连接建立后的初始化（与 Android 版一致）
    ///
    /// 关键：关灯状态下只补一条"关灯"，绝不补发亮度/颜色 ——
    /// 否则刚关掉的灯会被自己的初始化重新点亮（"黑一下又亮"）。
    private func initialize(_ device: BleDevice) {
        let p = Prefs.shared

        if !p.powerOn {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.send(LedCommand.lightOn(false), to: device)
            }
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.send(LedCommand.lightOn(true), to: device)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.send(LedCommand.brightness(p.brightness), to: device)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.send(LedCommand.color((p.color >> 16) & 0xFF, (p.color >> 8) & 0xFF, p.color & 0xFF),
                      to: device)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.send(LedCommand.pixelCount(p.ledCount), to: device)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.send(LedCommand.pinSequence(LedOutput.pinValue()), to: device)
        }
    }
}

// MARK: - CBCentralManagerDelegate

extension BleController: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        DispatchQueue.main.async {
            if central.state == .poweredOn {
                self.notifyMessage("蓝牙已就绪")
            } else if central.state == .poweredOff {
                self.notifyMessage("蓝牙未开启")
            }
            self.notifyDevices()
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber) {
        var name = (advertisementData[CBAdvertisementDataLocalNameKey] as? String) ?? ""
        if name.isEmpty { name = peripheral.name ?? "" }
        if name.isEmpty { return }

        if Prefs.shared.nameFilter && !name.hasPrefix(LedCommand.nameFilter) { return }

        let rssi = RSSI.intValue
        if let exist = all[peripheral.identifier] {
            exist.rssi = rssi
        } else {
            let d = BleDevice(peripheral: peripheral, name: name, rssi: rssi)
            all[peripheral.identifier] = d
            devices.append(d)
        }

        if autoConnectBusy, let target = autoConnectTarget,
           peripheral.identifier.uuidString == target {
            autoConnectBusy = false
            if let d = all[peripheral.identifier] {
                connect(d)
            }
        }

        devices.sort { $0.rssi > $1.rssi }
        DispatchQueue.main.async { self.notifyDevices() }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }

    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral, error: Error?) {
        let d = deviceFor(peripheral)
        d.state = .failed
        DispatchQueue.main.async { self.notifyState(d) }
    }

    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        let d = deviceFor(peripheral)
        d.state = .idle
        d.writeChar = nil
        connected.removeAll { $0.identifier == d.identifier }
        DispatchQueue.main.async {
            // 清掉该设备排队的命令，避免断开后队列空转
            self.pending.removeAll { $0.device.identifier == d.identifier }
            if self.connected.isEmpty {
                self.pending.removeAll()
                self.writeBusy = false
                self.writeTimeoutTask?.cancel()
                self.writeTimeoutTask = nil
            }
            self.notifyState(d)
            self.notifyMessage("\(d.name) 已断开")
        }
    }
}

// MARK: - CBPeripheralDelegate

extension BleController: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil, let services = peripheral.services else { return }
        for s in services {
            peripheral.discoverCharacteristics(nil, for: s)
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let chars = service.characteristics else { return }
        let dev = deviceFor(peripheral)

        for c in chars {
            let canWrite = c.properties.contains(.write) || c.properties.contains(.writeWithoutResponse)
            if !canWrite { continue }
            if c.uuid == chrWrite {
                dev.writeChar = c
            } else if c.uuid == chrWrite4 && dev.writeChar == nil {
                dev.writeChar = c
            } else if c.uuid == chrWrite2 && dev.writeChar == nil {
                dev.writeChar = c
            } else if dev.writeChar == nil {
                dev.writeChar = c
            }
        }

        if dev.writeChar != nil && dev.state != .connected {
            dev.state = .connected
            if !connected.contains(where: { $0.identifier == dev.identifier }) {
                connected.append(dev)
            }
            Prefs.shared.lastDevice = dev.identifier
            stopScan()
            initialize(dev)
            DispatchQueue.main.async {
                self.notifyState(dev)
                self.notifyMessage("已连接 \(dev.name)")
            }
        }
    }

    /// 有响应写完成 → 放行队列里的下一条
    func peripheral(_ peripheral: CBPeripheral,
                    didWriteValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        DispatchQueue.main.async {
            self.writeTimeoutTask?.cancel()
            self.writeTimeoutTask = nil
            self.writeBusy = false
            self.pumpWrite()
        }
    }
}
