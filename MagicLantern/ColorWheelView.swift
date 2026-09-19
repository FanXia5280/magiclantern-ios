import UIKit

/// 方形 HSV 色板：横向 = 饱和度，纵向 = 明度（色相由 HueBarView 决定）
final class ColorWheelView: UIView {

    var onColorChanged: ((Int) -> Void)?

    private let baseLayer = CAGradientLayer()
    private let shadeLayer = CAGradientLayer()
    private let indicatorRing = UIView()

    private(set) var hue: CGFloat = 0        // 0-360
    private var sat: CGFloat = 1             // 0-1
    private var val: CGFloat = 1             // 0-1

    /// 当前颜色（0xRRGGBB）
    var color: Int {
        let c = UIColor(hue: hue / 360.0, saturation: sat, brightness: val, alpha: 1)
        return c.rgbInt
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        layer.cornerRadius = 18
        layer.cornerCurve = .continuous
        layer.masksToBounds = true

        baseLayer.startPoint = CGPoint(x: 0, y: 0.5)
        baseLayer.endPoint = CGPoint(x: 1, y: 0.5)
        layer.addSublayer(baseLayer)

        shadeLayer.startPoint = CGPoint(x: 0.5, y: 0)
        shadeLayer.endPoint = CGPoint(x: 0.5, y: 1)
        shadeLayer.colors = [UIColor.clear.cgColor, UIColor.black.cgColor]
        layer.addSublayer(shadeLayer)

        indicatorRing.backgroundColor = .clear
        indicatorRing.layer.borderWidth = 3
        indicatorRing.layer.borderColor = UIColor.white.cgColor
        indicatorRing.layer.cornerRadius = 11
        indicatorRing.isUserInteractionEnabled = false
        addSubview(indicatorRing)

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(pan)

        updateShaders()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        baseLayer.frame = bounds
        shadeLayer.frame = bounds
        updateShaders()
        layoutIndicator()
    }

    private func updateShaders() {
        let pure = UIColor(hue: hue / 360.0, saturation: 1, brightness: 1, alpha: 1)
        baseLayer.colors = [UIColor.white.cgColor, pure.cgColor]
    }

    private func layoutIndicator() {
        let x = sat * bounds.width
        let y = (1 - val) * bounds.height
        indicatorRing.frame = CGRect(x: x - 11, y: y - 11, width: 22, height: 22)
    }

    @objc private func handlePan(_ g: UIPanGestureRecognizer) {
        let p = g.location(in: self)
        sat = max(0, min(1, p.x / max(1, bounds.width)))
        val = max(0, min(1, 1 - p.y / max(1, bounds.height)))
        layoutIndicator()
        onColorChanged?(color)
    }

    // ---------------- 对外接口 ----------------

    func setHue(_ h: CGFloat) {
        hue = h
        updateShaders()
    }

    func setColor(_ rgb: Int) {
        let c = UIColor(rgb: rgb)
        var h: CGFloat = 0, s: CGFloat = 0, v: CGFloat = 0, a: CGFloat = 0
        c.getHue(&h, saturation: &s, brightness: &v, alpha: &a)
        hue = h * 360
        sat = s
        val = v
        updateShaders()
        layoutIndicator()
    }
}

/// 彩虹色相条
final class HueBarView: UIView {

    var onHueChanged: ((CGFloat) -> Void)?

    private let barLayer = CAGradientLayer()
    private let indicator = UIView()
    private(set) var hue: CGFloat = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        layer.cornerRadius = 11
        layer.masksToBounds = true

        barLayer.startPoint = CGPoint(x: 0, y: 0.5)
        barLayer.endPoint = CGPoint(x: 1, y: 0.5)
        var cols: [CGColor] = []
        for i in 0...6 {
            let h = CGFloat(i) / 6.0
            cols.append(UIColor(hue: h, saturation: 1, brightness: 1, alpha: 1).cgColor)
        }
        barLayer.colors = cols
        layer.addSublayer(barLayer)

        indicator.backgroundColor = .white
        indicator.layer.cornerRadius = 3
        addSubview(indicator)

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(pan)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        barLayer.frame = bounds
        layoutIndicator()
    }

    private func layoutIndicator() {
        let x = hue / 360.0 * bounds.width
        indicator.frame = CGRect(x: x - 3, y: -2, width: 6, height: bounds.height + 4)
    }

    @objc private func handlePan(_ g: UIPanGestureRecognizer) {
        let p = g.location(in: self)
        hue = max(0, min(360, p.x / max(1, bounds.width) * 360))
        layoutIndicator()
        onHueChanged?(hue)
    }

    func setHue(_ h: CGFloat) {
        hue = h
        layoutIndicator()
    }
}

/// 渐变预览条（两色往复流动）
final class GradientPreviewView: UIView {

    private let layer0 = CAGradientLayer()
    private var timer: Timer?
    private var phase: CGFloat = 0
    private var dir: CGFloat = 1
    private var c1: Int = 0xFF3B3B
    private var c2: Int = 0x3B6BFF

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 12
        layer.masksToBounds = true
        layer0.startPoint = CGPoint(x: 0, y: 0.5)
        layer0.endPoint = CGPoint(x: 1, y: 0.5)
        layer.addSublayer(layer0)
        updateColors()
        startAnim()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    deinit {
        timer?.invalidate()
    }

    func setColors(_ a: Int, _ b: Int) {
        c1 = a
        c2 = b
        updateColors()
    }

    private func updateColors() {
        let mix = GradientPlayer.lerp(c1, c2, Double(phase))
        layer0.colors = [UIColor(rgb: c1).cgColor,
                         UIColor(rgb: mix).cgColor,
                         UIColor(rgb: c2).cgColor,
                         UIColor(rgb: mix).cgColor,
                         UIColor(rgb: c1).cgColor]
    }

    private func startAnim() {
        timer?.invalidate()
        let t = Timer(timeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.phase += self.dir * 0.012
            if self.phase >= 1 {
                self.phase = 1
                self.dir = -1
            } else if self.phase <= 0 {
                self.phase = 0
                self.dir = 1
            }
            self.updateColors()
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer0.frame = bounds
    }
}
