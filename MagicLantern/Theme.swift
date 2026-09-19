import UIKit

/// 全局配色：自动跟随 iPhone 的浅色 / 深色模式
enum Theme {

    /// 页面底色
    static let bg = UIColor.adaptive(light: 0xFFF2F4F8, dark: 0xFF05060A)
    /// 卡片内的次级填充
    static let cardInner = UIColor.adaptive(light: 0xFFE9ECF3, dark: 0xFF1E2331)

    static let textPrimary = UIColor.adaptive(light: 0xFF11131A, dark: 0xFFFFFFFF)
    static let textSecondary = UIColor.adaptive(light: 0xFF5A6273, dark: 0xFF8A93A6)
    static let textThird = UIColor.adaptive(light: 0xFF9AA2B2, dark: 0xFF5C6577)

    static let accent = UIColor(argb: 0xFF4A6CF7)
    static let accentText = UIColor.adaptive(light: 0xFF4436D6, dark: 0xFF8E7CFF)
    static let green = UIColor(argb: 0xFF22C55E)

    static let pad: CGFloat = 16
    static let radius: CGFloat = 24
}

extension UIColor {

    convenience init(argb: Int) {
        let a = CGFloat((argb >> 24) & 0xFF) / 255.0
        let r = CGFloat((argb >> 16) & 0xFF) / 255.0
        let g = CGFloat((argb >> 8) & 0xFF) / 255.0
        let b = CGFloat(argb & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: a <= 0 ? 1.0 : a)
    }

    /// 0xRRGGBB → UIColor
    convenience init(rgb: Int) {
        self.init(argb: 0xFF000000 | (rgb & 0xFFFFFF))
    }

    /// 浅色 / 深色两套色值，自动跟随系统
    static func adaptive(light: Int, dark: Int) -> UIColor {
        return UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(argb: dark) : UIColor(argb: light)
        }
    }

    /// 分隔线 / 细边框（深色下白、浅色下黑）
    static var hairline: UIColor {
        return UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(white: 1, alpha: 0.10)
                : UIColor(white: 0, alpha: 0.08)
        }
    }

    /// 轻微填充（未选中态底衬）
    static var subtleFill: UIColor {
        return UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(white: 1, alpha: 0.08)
                : UIColor(white: 0, alpha: 0.05)
        }
    }

    var argbInt: Int {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Int(a * 255) << 24) | (Int(r * 255) << 16) | (Int(g * 255) << 8) | Int(b * 255)
    }

    var rgbInt: Int {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Int(r * 255) << 16) | (Int(g * 255) << 8) | Int(b * 255)
    }
}

/// UI 快捷构建（对应 Android 版的 Ui 工具）
enum Ui {

    static func label(_ text: String, size: CGFloat = 15,
                      color: UIColor = Theme.textPrimary, bold: Bool = false) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = bold ? UIFont.boldSystemFont(ofSize: size) : UIFont.systemFont(ofSize: size)
        l.textColor = color
        l.numberOfLines = 0
        return l
    }

    static func vStack(_ spacing: CGFloat = 0) -> UIStackView {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = spacing
        return s
    }

    static func hStack(_ spacing: CGFloat = 0) -> UIStackView {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = spacing
        s.alignment = .center
        return s
    }

    /// 原生液态玻璃卡片
    static func card() -> UIView {
        let c = GlassCard(radius: 24)
        c.showShine(true)
        return c
    }

    static func applyCardStyle(_ v: UIView, radius: CGFloat = 20) {
        Glass.styleTile(v, selected: false, radius: radius)
    }

    /// 圆形图标（纯色圆 + 文字/符号）
    static func iconCircle(_ icon: String, color: UIColor, size: CGFloat = 38) -> UIView {
        let v = UIView()
        v.backgroundColor = color
        v.layer.cornerRadius = size / 2
        v.translatesAutoresizingMaskIntoConstraints = false
        v.widthAnchor.constraint(equalToConstant: size).isActive = true
        v.heightAnchor.constraint(equalToConstant: size).isActive = true

        let l = label(icon, size: size * 0.48, color: .white, bold: true)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(l)
        l.centerXAnchor.constraint(equalTo: v.centerXAnchor).isActive = true
        l.centerYAnchor.constraint(equalTo: v.centerYAnchor).isActive = true
        return v
    }

    /// 段控样式的文字按钮
    static func chipButton(_ text: String, size: CGFloat = 14) -> UILabel {
        let l = label(text, size: size, color: Theme.textPrimary, bold: true)
        l.textAlignment = .center
        l.backgroundColor = .subtleFill
        l.layer.cornerRadius = 12
        l.layer.masksToBounds = true
        return l
    }

    static func bordered(_ v: UIView, color: UIColor = Theme.accent, width: CGFloat = 2,
                         radius: CGFloat = Theme.radius) {
        v.layer.borderWidth = width
        v.layer.borderColor = color.cgColor
        v.layer.cornerRadius = radius
    }

    /// 两色（或多色）横向渐变背景
    static func gradientLayer(_ colors: [Int], frame: CGRect) -> CAGradientLayer {
        let g = CAGradientLayer()
        g.frame = frame
        g.startPoint = CGPoint(x: 0, y: 0.5)
        g.endPoint = CGPoint(x: 1, y: 0.5)
        g.colors = colors.map { UIColor(rgb: $0).cgColor }
        g.cornerRadius = Theme.radius
        return g
    }

    static func toast(_ text: String) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else { return }
        let l = label(text, size: 14, color: .white)
        l.textAlignment = .center
        l.backgroundColor = UIColor(white: 0.1, alpha: 0.92)
        l.layer.cornerRadius = 14
        l.layer.cornerCurve = .continuous
        l.layer.masksToBounds = true
        l.alpha = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        window.addSubview(l)
        NSLayoutConstraint.activate([
            l.centerXAnchor.constraint(equalTo: window.centerXAnchor),
            l.bottomAnchor.constraint(equalTo: window.safeAreaLayoutGuide.bottomAnchor, constant: -140),
            l.widthAnchor.constraint(lessThanOrEqualTo: window.widthAnchor, constant: -48),
            l.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
        UIView.animate(withDuration: 0.2, animations: { l.alpha = 1 }) { _ in
            UIView.animate(withDuration: 0.3, delay: 1.6, options: [], animations: {
                l.alpha = 0
            }) { _ in
                l.removeFromSuperview()
            }
        }
    }
}
