import UIKit

/// 渐变色卡（双色 / 多色背景 + 名称，可点击选中）
final class GradientCell: UIView {

    private let gradient = CAGradientLayer()
    private let titleLabel = UILabel()
    var onTap: (() -> Void)?
    var onLongPress: (() -> Void)?

    private var colors: [Int]

    init(colors: [Int], text: String) {
        self.colors = colors.isEmpty ? [0x222222, 0x444444] : colors
        super.init(frame: .zero)
        layer.cornerRadius = 16
        layer.cornerCurve = .continuous
        layer.masksToBounds = true
        layer.borderWidth = 1
        layer.borderColor = UIColor(white: 1, alpha: 0.28).cgColor

        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        gradient.colors = self.colors.map { UIColor(rgb: $0).cgColor }
        layer.addSublayer(gradient)

        titleLabel.text = text
        titleLabel.font = UIFont.boldSystemFont(ofSize: 13)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2
        titleLabel.layer.shadowColor = UIColor.black.cgColor
        titleLabel.layer.shadowOpacity = 0.8
        titleLabel.layer.shadowRadius = 2
        titleLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.leftAnchor.constraint(greaterThanOrEqualTo: leftAnchor, constant: 4),
            titleLabel.rightAnchor.constraint(lessThanOrEqualTo: rightAnchor, constant: -4)
        ])

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped)))
        let lp = UILongPressGestureRecognizer(target: self, action: #selector(longPressed))
        addGestureRecognizer(lp)

        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 52).isActive = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = bounds
    }

    func setSelectedStyle(_ selected: Bool) {
        layer.borderWidth = selected ? 2.5 : 1
        layer.borderColor = selected ? UIColor.white.cgColor
            : UIColor(white: 1, alpha: 0.28).cgColor
    }

    @objc private func tapped() { onTap?() }
    @objc private func longPressed(_ g: UILongPressGestureRecognizer) {
        if g.state == .began { onLongPress?() }
    }
}

/// 场景模式页：自定义渐变 / 双色流动 / 9 类固件模式
final class SceneViewController: UIViewController, BleListener {

    private let categoryStack = UIStackView()
    private let categoryScroll = UIScrollView()
    private let contentStack = UIStackView()
    private let speedSlider = UISlider()
    private let speedLabel = Ui.label("60", size: 14, color: Theme.textPrimary, bold: true)

    private var categories: [String] = []
    private var current = 0   // 0=自定义, 1=双色流动, 2..10 = ModeData.groups[0..8]

    private var modeButtons: [UIButton] = []
    private var flowCells: [Int: GradientCell] = [:]
    private var firmwareCells: [Int: GradientCell] = [:]
    private var customCells: [String: GradientCell] = [:]
    private var selectedFlowCmd = -1

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "场景模式"
        applyGlassBackground()
        BleController.shared.addListener(self)

        categories = ["自定义", "双色流动"] + ModeData.groups
        setupUi()
        selectCategory(0)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if current == 0 { rebuild() }
    }

    private func setupUi() {
        // 分类条
        categoryScroll.translatesAutoresizingMaskIntoConstraints = false
        categoryScroll.showsHorizontalScrollIndicator = false
        view.addSubview(categoryScroll)

        categoryStack.axis = .horizontal
        categoryStack.spacing = 8
        categoryStack.translatesAutoresizingMaskIntoConstraints = false
        categoryScroll.addSubview(categoryStack)

        // 内容
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        contentStack.axis = .vertical
        contentStack.spacing = 10
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(contentStack)

        // 速度
        let speedBar = Ui.vStack(4)
        speedBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(speedBar)
        let speedHead = Ui.hStack(8)
        speedHead.addArrangedSubview(Ui.label("速度", size: 13, color: Theme.textSecondary))
        speedHead.addArrangedSubview(UIView())
        speedHead.addArrangedSubview(speedLabel)
        speedBar.addArrangedSubview(speedHead)
        speedSlider.minimumValue = 0
        speedSlider.maximumValue = 100
        speedSlider.value = Float(Prefs.shared.speed)
        speedSlider.tintColor = Theme.accent
        speedSlider.addTarget(self, action: #selector(speedChanged), for: .valueChanged)
        speedSlider.addTarget(self, action: #selector(speedDone), for: .touchUpInside)
        speedSlider.addTarget(self, action: #selector(speedDone), for: .touchUpOutside)
        speedBar.addArrangedSubview(speedSlider)
        speedLabel.text = "\(Prefs.shared.speed)"

        NSLayoutConstraint.activate([
            categoryScroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            categoryScroll.leftAnchor.constraint(equalTo: view.leftAnchor),
            categoryScroll.rightAnchor.constraint(equalTo: view.rightAnchor),
            categoryScroll.heightAnchor.constraint(equalToConstant: 52),

            categoryStack.topAnchor.constraint(equalTo: categoryScroll.topAnchor, constant: 8),
            categoryStack.bottomAnchor.constraint(equalTo: categoryScroll.bottomAnchor, constant: -8),
            categoryStack.leftAnchor.constraint(equalTo: categoryScroll.leftAnchor, constant: Theme.pad),
            categoryStack.rightAnchor.constraint(equalTo: categoryScroll.rightAnchor, constant: -Theme.pad),

            speedBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -6),
            speedBar.leftAnchor.constraint(equalTo: view.leftAnchor, constant: Theme.pad),
            speedBar.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -Theme.pad),

            scroll.topAnchor.constraint(equalTo: categoryScroll.bottomAnchor, constant: 4),
            scroll.leftAnchor.constraint(equalTo: view.leftAnchor),
            scroll.rightAnchor.constraint(equalTo: view.rightAnchor),
            scroll.bottomAnchor.constraint(equalTo: speedBar.topAnchor, constant: -6),

            contentStack.topAnchor.constraint(equalTo: scroll.topAnchor, constant: 6),
            contentStack.bottomAnchor.constraint(equalTo: scroll.bottomAnchor, constant: -16),
            contentStack.leftAnchor.constraint(equalTo: scroll.leftAnchor, constant: Theme.pad),
            contentStack.rightAnchor.constraint(equalTo: scroll.rightAnchor, constant: -Theme.pad),
            contentStack.widthAnchor.constraint(equalTo: scroll.widthAnchor, constant: -Theme.pad * 2)
        ])

        // 分类 chips
        for (i, name) in categories.enumerated() {
            let chip = MButton(type: .system)
            chip.tag = i
            chip.setTitle(name, for: .normal)
            chip.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
            chip.layer.cornerRadius = 16
            chip.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
            chip.translatesAutoresizingMaskIntoConstraints = false
            chip.heightAnchor.constraint(equalToConstant: 34).isActive = true
            chip.addTarget(self, action: #selector(chipTapped(_:)), for: .touchUpInside)
            categoryStack.addArrangedSubview(chip)
        }
        refreshChips()
    }

    private func refreshChips() {
        for v in categoryStack.arrangedSubviews {
            guard let b = v as? UIButton else { continue }
            let sel = b.tag == current
            b.setTitleColor(sel ? .white : Theme.textSecondary, for: .normal)
            if sel {
                // 选中：液态玻璃胶囊
                Glass.styleChip(b, selected: true)
            } else {
                // 未选中：去掉底色，只留文字（更干净）
                Glass.removeGlassBackground(b)
            }
        }
    }

    @objc private func chipTapped(_ sender: UIButton) {
        selectCategory(sender.tag)
    }

    private func selectCategory(_ index: Int) {
        current = index
        refreshChips()
        rebuild()
    }

    // ---------------- 内容构建 ----------------

    private func rebuild() {
        for v in contentStack.arrangedSubviews { v.removeFromSuperview() }
        modeButtons.removeAll()
        flowCells.removeAll()
        firmwareCells.removeAll()
        customCells.removeAll()

        if current == 0 {
            buildCustom()
        } else if current == 1 {
            buildFlow()
        } else {
            buildModes(group: current - 2)
        }
    }

    private func addGrid(_ items: [UIView], columns: Int) {
        var row: UIStackView?
        for (i, v) in items.enumerated() {
            if i % columns == 0 {
                let r = Ui.hStack(8)
                r.distribution = .fillEqually
                contentStack.addArrangedSubview(r)
                row = r
            }
            row?.addArrangedSubview(v)
        }
        if let last = row, last.arrangedSubviews.count < columns {
            let need = columns - last.arrangedSubviews.count
            for _ in 0..<need {
                let ghost = UIView()
                ghost.translatesAutoresizingMaskIntoConstraints = false
                ghost.heightAnchor.constraint(equalToConstant: 52).isActive = true
                last.addArrangedSubview(ghost)
            }
        }
    }

    private func sectionTitle(_ text: String) -> UILabel {
        let l = Ui.label(text, size: 12, color: Theme.textSecondary)
        return l
    }

    // ---- 9 类固件模式 ----
    private func buildModes(group: Int) {
        let names = ModeData.names[group]
        let cmds = ModeData.cmds[group]
        var cells: [UIView] = []
        for i in 0..<names.count {
            let cmd = cmds[i]
            let b = MButton(type: .system)
            b.tag = i
            b.setTitle(names[i], for: .normal)
            b.titleLabel?.font = UIFont.systemFont(ofSize: 13)
            b.titleLabel?.numberOfLines = 2
            b.setTitleColor(Theme.textPrimary, for: .normal)
            Glass.styleTile(b)
            b.translatesAutoresizingMaskIntoConstraints = false
            b.heightAnchor.constraint(equalToConstant: 52).isActive = true
            b.action = { [weak self] in
                guard let self = self else { return }
                LedOutput.sendMode(group: group, value: cmd, speed: Prefs.shared.speed)
                self.highlightMode(i)
                Ui.toast("已应用：\(names[i])")
            }
            b.addTarget(b, action: #selector(MButton.fire), for: .touchUpInside)
            let lp = UILongPressGestureRecognizer(target: self, action: #selector(modeLongPressed(_:)))
            b.addGestureRecognizer(lp)
            modeButtons.append(b)
            cells.append(b)
        }
        addGrid(cells, columns: 3)
    }

    private func highlightMode(_ index: Int) {
        for (i, b) in modeButtons.enumerated() {
            Glass.styleTile(b, selected: i == index)
        }
    }

    @objc private func modeLongPressed(_ g: UILongPressGestureRecognizer) {
        guard g.state == .began, let b = g.view as? UIButton else { return }
        let group = current - 2
        guard group >= 0, group < ModeData.cmds.count else { return }
        let cmd = ModeData.cmds[group][b.tag]
        let name = ModeData.names[group][b.tag]
        let isFav = Prefs.shared.favModes.contains("\(group),\(cmd)")
        let sheet = UIAlertController(title: name, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "立即应用", style: .default) { _ in
            LedOutput.sendMode(group: group, value: cmd, speed: Prefs.shared.speed)
        })
        sheet.addAction(UIAlertAction(title: isFav ? "从主页移除" : "添加到主页常用",
                                      style: .default) { _ in
            if isFav {
                Prefs.shared.removeFavMode(group: group, cmd: cmd)
                Ui.toast("已从主页移除")
            } else {
                Prefs.shared.addFavMode(group: group, cmd: cmd)
                Ui.toast("已添加到主页常用")
            }
        })
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        if let pop = sheet.popoverPresentationController {
            pop.sourceView = b
            pop.sourceRect = b.bounds
        }
        present(sheet, animated: true)
    }

    // ---- 双色流动（84 个固件效果）----
    private func buildFlow() {
        for group in FlowData.groups {
            contentStack.addArrangedSubview(sectionTitle(group.title))
            var cells: [UIView] = []
            for i in 0..<group.names.count {
                let cmd = group.cmds[i]
                let cell = GradientCell(colors: group.colors[i], text: group.names[i])
                cell.setSelectedStyle(cmd == selectedFlowCmd)
                cell.onTap = { [weak self] in
                    guard let self = self else { return }
                    self.selectedFlowCmd = cmd
                    LedOutput.sendMode(group: 0, value: cmd, speed: Prefs.shared.speed)
                    self.refreshFlowSelection()
                    Ui.toast("已应用：\(group.names[i])（设备端执行，关 App 也生效）")
                }
                flowCells[cmd] = cell
                cells.append(cell)
            }
            addGrid(cells, columns: 2)
        }
    }

    private func refreshFlowSelection() {
        for (cmd, cell) in flowCells {
            cell.setSelectedStyle(cmd == selectedFlowCmd)
        }
    }

    // ---- 自定义渐变 ----
    private func buildCustom() {
        contentStack.addArrangedSubview(sectionTitle("自定义渐变 · 需 App 保持运行（退出即停）"))

        let add = MButton(type: .system)
        add.setTitle("+ 新建渐变", for: .normal)
        add.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        add.setTitleColor(.white, for: .normal)
        Glass.addGlassBackground(add, radius: 18, interactive: true, tint: Theme.accent)
        add.translatesAutoresizingMaskIntoConstraints = false
        add.heightAnchor.constraint(equalToConstant: 52).isActive = true
        add.action = { [weak self] in
            self?.openEditor(nil)
        }
        add.addTarget(add, action: #selector(MButton.fire), for: .touchUpInside)

        var cells: [UIView] = [add]
        for g in Prefs.shared.gradients {
            let cell = GradientCell(colors: [g.color1, g.color2], text: g.name)
            cell.setSelectedStyle(g.name == GradientPlayer.shared.playingName)
            cell.onTap = { [weak self] in
                self?.applyGradient(g)
            }
            cell.onLongPress = { [weak self] in
                self?.gradientMenu(g)
            }
            customCells[g.name] = cell
            cells.append(cell)
        }
        addGrid(cells, columns: 2)

        contentStack.addArrangedSubview(sectionTitle("固件渐变 · 关掉 App 也一直执行"))
        var fwCells: [UIView] = []
        let fwNames = ["七色渐变", "红黄交替渐变", "红紫交替渐变", "绿青交替渐变", "绿黄交替渐变", "蓝紫交替渐变"]
        let fwCmds = [199, 200, 201, 202, 203, 204]
        let fwColors: [[Int]] = [FlowData.rainbow,
                                 [FlowData.red, FlowData.yellow],
                                 [FlowData.red, FlowData.purple],
                                 [FlowData.green, FlowData.cyan],
                                 [FlowData.green, FlowData.yellow],
                                 [FlowData.blue, FlowData.purple]]
        for i in 0..<fwCmds.count {
            let cmd = fwCmds[i]
            let cell = GradientCell(colors: fwColors[i], text: fwNames[i])
            cell.onTap = { [weak self] in
                LedOutput.sendMode(group: 0, value: cmd, speed: Prefs.shared.speed)
                self?.refreshFirmwareSelection(cmd)
                Ui.toast("固件渐变已下发（设备端执行，关掉 App 也生效）")
            }
            firmwareCells[cmd] = cell
            fwCells.append(cell)
        }
        addGrid(fwCells, columns: 2)
    }

    private var selectedFirmwareCmd = -1

    private func refreshFirmwareSelection(_ cmd: Int) {
        selectedFirmwareCmd = cmd
        for (c, cell) in firmwareCells {
            cell.setSelectedStyle(c == cmd)
        }
    }

    private func applyGradient(_ g: Prefs.Gradient) {
        GradientPlayer.shared.play(g)
        selectedFirmwareCmd = -1
        for (_, cell) in firmwareCells { cell.setSelectedStyle(false) }
        Prefs.shared.speed = g.speed
        speedSlider.value = Float(g.speed)
        speedLabel.text = "\(g.speed)"
        refreshCustomSelection(g.name)
        Ui.toast("已应用：\(g.name)（需保持 App 运行）")
    }

    private func refreshCustomSelection(_ name: String?) {
        for (n, cell) in customCells {
            cell.setSelectedStyle(n == name)
        }
    }

    private func gradientMenu(_ g: Prefs.Gradient) {
        let sheet = UIAlertController(title: g.name, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "立即应用", style: .default) { [weak self] _ in
            self?.applyGradient(g)
        })
        sheet.addAction(UIAlertAction(title: "编辑", style: .default) { [weak self] _ in
            self?.openEditor(g)
        })
        sheet.addAction(UIAlertAction(title: "删除", style: .destructive) { [weak self] _ in
            if GradientPlayer.shared.playingName == g.name { GradientPlayer.shared.stop() }
            Prefs.shared.removeGradient(g.name)
            self?.rebuild()
            Ui.toast("已删除：\(g.name)")
        })
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        if let pop = sheet.popoverPresentationController {
            pop.sourceView = view
            pop.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
        }
        present(sheet, animated: true)
    }

    private func openEditor(_ origin: Prefs.Gradient?) {
        let vc = GradientEditorViewController()
        vc.origin = origin
        vc.onSaved = { [weak self] oldName, item in
            Prefs.shared.saveGradient(oldName: oldName, item: item)
            GradientPlayer.shared.replace(oldName: oldName ?? "", with: item)
            self?.rebuild()
            self?.applyGradient(item)
        }
        let nav = UINavigationController(rootViewController: vc)
        nav.navigationBar.barTintColor = Theme.bg
        nav.navigationBar.tintColor = Theme.accentText
        nav.navigationBar.titleTextAttributes = [.foregroundColor: Theme.textPrimary]
        present(nav, animated: true)
    }

    // ---------------- 速度 ----------------

    @objc private func speedChanged() {
        speedLabel.text = "\(Int(speedSlider.value))"
    }

    @objc private func speedDone() {
        let v = Int(speedSlider.value)
        Prefs.shared.speed = v
        LedOutput.sendSpeed(v)
        // 自定义渐变：同步到正在播放的那条
        if let name = GradientPlayer.shared.playingName {
            if var g = Prefs.shared.gradients.first(where: { $0.name == name }) {
                g.speed = v
                GradientPlayer.shared.applySpeed(g)
                var list = Prefs.shared.gradients
                if let idx = list.firstIndex(where: { $0.name == name }) {
                    list[idx] = g
                    Prefs.shared.gradients = list
                }
            }
        }
    }

    // ---------------- BleListener ----------------

    func bleDevicesChanged() {}
    func bleStateChanged(_ device: BleDevice?) {}
    func bleMessage(_ text: String) {}
}
