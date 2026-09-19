import UIKit

/// 全局配色（与 Android 版一致：深色卡片 + 蓝紫强调色）
enum Theme {
    static let bg = UIColor(argb: 0xFF0A0D14)
    static let card = UIColor(argb: 0xFF141926)
    static let cardInner = UIColor(argb: 0xFF1E2331)
    static let stroke = UIColor(white: 1.0, alpha: 0.08)

    static let textPrimary = UIColor.white
    static let textSecondary = UIColor(argb: 0xFF8A93A6)
    static let textThird = UIColor(argb: 0xFF5C6577)

    static let accent = UIColor(argb: 0xFF4A6CF7)
    static let accentText = UIColor(argb: 0xFF7B5CFF)
    static let green = UIColor(argb: 0xFF22C55E)

    static let pad: CGFloat = 16
    static let radius: CGFloat = 14
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

    static func card() -> UIView {
        let v = UIView()
        v.backgroundColor = Theme.card
        v.layer.cornerRadius = Theme.radius
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor(white: 1.0, alpha: 0.06).cgColor
        return v
    }

    static func applyCardStyle(_ v: UIView, radius: CGFloat = Theme.radius) {
        v.backgroundColor = Theme.card
        v.layer.cornerRadius = radius
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor(white: 1.0, alpha: 0.06).cgColor
    }

    /// 圆形渐变图标（用纯色圆代替渐变色，风格一致）
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
        l.backgroundColor = UIColor(white: 1.0, alpha: 0.06)
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
        guard let window = UIApplication.shared.windows.first else { return }
        let l = label(text, size: 14, color: .white)
        l.textAlignment = .center
        l.backgroundColor = UIColor(white: 0.1, alpha: 0.92)
        l.layer.cornerRadius = 10
        l.layer.masksToBounds = true
        l.alpha = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        window.addSubview(l)
        NSLayoutConstraint.activate([
            l.centerXAnchor.constraint(equalTo: window.centerXAnchor),
            l.bottomAnchor.constraint(equalTo: window.safeAreaLayoutGuide.bottomAnchor, constant: -90),
            l.widthAnchor.constraint(lessThanOrEqualTo: window.widthAnchor, constant: -48)
        ])
        l.layoutMargins = UIEdgeInsets(top: 12, left: 18, bottom: 12, right: 18)
        UIView.animate(withDuration: 0.2, animations: { l.alpha = 1 }) { _ in
            UIView.animate(withDuration: 0.3, delay: 1.6, options: [], animations: {
                l.alpha = 0
            }) { _ in
                l.removeFromSuperview()
            }
        }
    }
}
