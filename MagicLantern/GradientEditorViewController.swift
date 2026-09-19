import UIKit

/// 自定义渐变编辑器：名称 + 起始色/结束色 + 速度 + 实时预览
final class GradientEditorViewController: UIViewController {

    var origin: Prefs.Gradient?
    /// 回调：旧名称（新建为 nil）、保存后的渐变
    var onSaved: ((String?, Prefs.Gradient) -> Void)?

    private let nameField = UITextField()
    private let preview = GradientPreviewView(frame: .zero)
    private let swatchA = UIView()
    private let swatchB = UIView()
    private let wheel = ColorWheelView()
    private let hueBar = HueBarView()
    private let speedSlider = UISlider()
    private let speedLabel = Ui.label("60", size: 14, color: Theme.textPrimary, bold: true)
    private let hintLabel = Ui.label("点色块选择要调整的颜色，再拖上方色盘 / 色相条", size: 12,
                                     color: Theme.textSecondary)

    private var c1 = 0xFF3B3B
    private var c2 = 0x3B6BFF
    private var target = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        title = origin == nil ? "新建渐变" : "编辑渐变"
        applyGlassBackground()

        if let g = origin {
            c1 = g.color1
            c2 = g.color2
            speedSlider.value = Float(g.speed)
            speedLabel.text = "\(g.speed)"
        } else {
            speedSlider.value = Float(Prefs.shared.speed)
            speedLabel.text = "\(Prefs.shared.speed)"
        }
        nameField.text = origin?.name ?? ""

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "取消", style: .plain,
                                                           target: self, action: #selector(cancel))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "保存", style: .done,
                                                            target: self, action: #selector(save))
        setupUi()
        refreshSwatches()
        selectTarget(0)
    }

    private func setupUi() {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.keyboardDismissMode = .onDrag
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

        // 名称
        nameField.placeholder = "渐变名称（如：晨曦）"
        nameField.textColor = Theme.textPrimary
        nameField.font = UIFont.systemFont(ofSize: 15)
        nameField.backgroundColor = Theme.cardInner
        nameField.layer.cornerRadius = 12
        nameField.translatesAutoresizingMaskIntoConstraints = false
        nameField.heightAnchor.constraint(equalToConstant: 46).isActive = true
        nameField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 10))
        nameField.leftViewMode = .always
        root.addArrangedSubview(nameField)

        // 预览
        preview.translatesAutoresizingMaskIntoConstraints = false
        preview.heightAnchor.constraint(equalToConstant: 48).isActive = true
        root.addArrangedSubview(preview)

        // 两个色块
        let swatchRow = Ui.hStack(10)
        swatchRow.distribution = .fillEqually
        swatchRow.addArrangedSubview(makeSwatch(swatchA, title: "起始色"))
        swatchRow.addArrangedSubview(makeSwatch(swatchB, title: "结束色"))
        root.addArrangedSubview(swatchRow)
        root.addArrangedSubview(hintLabel)

        // 色盘
        wheel.translatesAutoresizingMaskIntoConstraints = false
        wheel.heightAnchor.constraint(equalTo: wheel.widthAnchor).isActive = true
        root.addArrangedSubview(wheel)

        hueBar.translatesAutoresizingMaskIntoConstraints = false
        hueBar.heightAnchor.constraint(equalToConstant: 22).isActive = true
        root.addArrangedSubview(hueBar)

        // 速度
        let speedCard = Ui.card()
        let speedInner = Ui.vStack(6)
        speedInner.translatesAutoresizingMaskIntoConstraints = false
        speedCard.addSubview(speedInner)
        NSLayoutConstraint.activate([
            speedInner.topAnchor.constraint(equalTo: speedCard.topAnchor, constant: 12),
            speedInner.leftAnchor.constraint(equalTo: speedCard.leftAnchor, constant: 14),
            speedInner.rightAnchor.constraint(equalTo: speedCard.rightAnchor, constant: -14),
            speedInner.bottomAnchor.constraint(equalTo: speedCard.bottomAnchor, constant: -12)
        ])
        let speedHead = Ui.hStack(8)
        speedHead.addArrangedSubview(Ui.label("速度", size: 14, color: Theme.textSecondary))
        speedHead.addArrangedSubview(UIView())
        speedHead.addArrangedSubview(speedLabel)
        speedInner.addArrangedSubview(speedHead)
        speedSlider.minimumValue = 0
        speedSlider.maximumValue = 100
        speedSlider.tintColor = Theme.accent
        speedSlider.addTarget(self, action: #selector(speedChanged), for: .valueChanged)
        speedInner.addArrangedSubview(speedSlider)
        root.addArrangedSubview(speedCard)

        // 联动
        wheel.onColorChanged = { [weak self] rgb in
            self?.setTargetColor(rgb)
        }
        hueBar.onHueChanged = { [weak self] h in
            guard let self = self else { return }
            self.wheel.setHue(h)
            self.setTargetColor(self.wheel.color)
        }
    }

    private func makeSwatch(_ v: UIView, title: String) -> UIView {
        let col = Ui.vStack(6)
        v.layer.cornerRadius = 10
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor(white: 1, alpha: 0.2).cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        v.heightAnchor.constraint(equalToConstant: 44).isActive = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(swatchTapped(_:)))
        v.addGestureRecognizer(tap)
        col.addArrangedSubview(v)
        let l = Ui.label(title, size: 12, color: Theme.textSecondary)
        l.textAlignment = .center
        col.addArrangedSubview(l)
        return col
    }

    private func refreshSwatches() {
        swatchA.backgroundColor = UIColor(rgb: c1)
        swatchB.backgroundColor = UIColor(rgb: c2)
        swatchA.layer.borderWidth = target == 0 ? 3 : 1
        swatchA.layer.borderColor = target == 0 ? UIColor.white.cgColor
            : UIColor(white: 1, alpha: 0.2).cgColor
        swatchB.layer.borderWidth = target == 1 ? 3 : 1
        swatchB.layer.borderColor = target == 1 ? UIColor.white.cgColor
            : UIColor(white: 1, alpha: 0.2).cgColor
        preview.setColors(c1, c2)
    }

    private func setTargetColor(_ rgb: Int) {
        if target == 0 { c1 = rgb } else { c2 = rgb }
        refreshSwatches()
    }

    private func selectTarget(_ t: Int) {
        target = t
        let rgb = t == 0 ? c1 : c2
        wheel.setColor(rgb)
        var h: CGFloat = 0, s: CGFloat = 0, v: CGFloat = 0, a: CGFloat = 0
        UIColor(rgb: rgb).getHue(&h, saturation: &s, brightness: &v, alpha: &a)
        hueBar.setHue(h * 360)
        refreshSwatches()
    }

    @objc private func swatchTapped(_ g: UITapGestureRecognizer) {
        if g.view === swatchA {
            selectTarget(0)
        } else if g.view === swatchB {
            selectTarget(1)
        }
    }

    @objc private func speedChanged() {
        speedLabel.text = "\(Int(speedSlider.value))"
    }

    @objc private func cancel() {
        dismiss(animated: true)
    }

    @objc private func save() {
        var name = Prefs.Gradient.clean(nameField.text ?? "")
        if name.isEmpty {
            name = "渐变\(Prefs.shared.gradients.count + 1)"
        }
        let item = Prefs.Gradient(name: name, color1: c1, color2: c2,
                                  speed: Int(speedSlider.value))
        onSaved?(origin?.name, item)
        dismiss(animated: true)
    }
}
