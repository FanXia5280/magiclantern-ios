import UIKit

/// 液态玻璃卡片：半透明磨砂 + 顶部高光 + 连续圆角 + 描边
/// （用 UIVisualEffectView 实现，iOS 13 起全版本可用；iOS 26+ 上与系统玻璃语言一致）
final class GlassCard: UIView {

    private let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let shine = CAGradientLayer()

    init(radius: CGFloat = 22, strong: Bool = false) {
        super.init(frame: .zero)
        backgroundColor = .clear
        layer.cornerRadius = radius
        layer.cornerCurve = .continuous
        layer.masksToBounds = true
        layer.borderWidth = 1
        layer.borderColor = UIColor(white: 1, alpha: strong ? 0.24 : 0.16).cgColor

        blur.effect = UIBlurEffect(style: strong ? .systemThinMaterialDark
                                                  : .systemUltraThinMaterialDark)
        blur.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(blur)

        // 玻璃反光：顶部一条柔和白光，向下渐隐
        shine.colors = [UIColor(white: 1, alpha: 0.12).cgColor,
                        UIColor(white: 1, alpha: 0.03).cgColor,
                        UIColor.clear.cgColor]
        shine.locations = [0, 0.10, 0.42]
        shine.startPoint = CGPoint(x: 0.5, y: 0)
        shine.endPoint = CGPoint(x: 0.5, y: 1)
        shine.isHidden = true
        layer.addSublayer(shine)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        blur.frame = bounds
        if !shine.isHidden {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            shine.frame = bounds
            CATransaction.commit()
        }
    }

    /// 显示顶部高光（卡片类用 true 更通透）
    func showShine(_ on: Bool) {
        shine.isHidden = !on
        setNeedsLayout()
    }
}

/// 背景光斑：深色底 + 几团柔和色晕，让玻璃卡片浮起来有层次
final class AuroraBackground: UIView {

    private let blobA = UIView()
    private let blobB = UIView()
    private let blobC = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = Theme.bg
        isUserInteractionEnabled = false

        blobA.backgroundColor = UIColor(argb: 0x3D2F6BFF)   // 蓝紫
        blobB.backgroundColor = UIColor(argb: 0x30B14BFF)   // 紫
        blobC.backgroundColor = UIColor(argb: 0x22FF3D8A)   // 粉

        for b in [blobA, blobB, blobC] {
            b.isUserInteractionEnabled = false
            addSubview(b)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let w = bounds.width
        let h = bounds.height
        circle(blobA, -w * 0.28, -h * 0.10, w * 0.95)
        circle(blobB, w * 0.52, h * 0.52, w * 1.0)
        circle(blobC, w * 0.05, h * 0.72, w * 0.7)
    }

    private func circle(_ v: UIView, _ x: CGFloat, _ y: CGFloat, _ size: CGFloat) {
        v.frame = CGRect(x: x, y: y, width: size, height: size)
        v.layer.cornerRadius = size / 2
        v.layer.masksToBounds = true
    }
}

extension UIViewController {

    /// 给页面铺上"液态玻璃"风格的背景（深色 + 光斑）
    func applyGlassBackground() {
        view.backgroundColor = Theme.bg
        let bg = AuroraBackground()
        bg.frame = view.bounds
        bg.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(bg, at: 0)
    }
}

enum Glass {

    /// 玻璃按钮样式（半透明 + 高光描边）
    static func styleButton(_ b: UIButton, radius: CGFloat = 14, accent: Bool = false) {
        b.layer.cornerRadius = radius
        b.layer.cornerCurve = .continuous
        b.layer.borderWidth = 1
        if accent {
            b.backgroundColor = UIColor(argb: 0xCC4A6CF7)
            b.layer.borderColor = UIColor(white: 1, alpha: 0.35).cgColor
        } else {
            b.backgroundColor = UIColor(white: 1, alpha: 0.10)
            b.layer.borderColor = UIColor(white: 1, alpha: 0.16).cgColor
        }
        b.clipsToBounds = true
    }

    /// 玻璃小方块（模式按钮等）
    static func styleTile(_ v: UIView, selected: Bool = false, radius: CGFloat = 14) {
        v.layer.cornerRadius = radius
        v.layer.cornerCurve = .continuous
        v.layer.borderWidth = selected ? 1.5 : 1
        if selected {
            v.backgroundColor = UIColor(argb: 0x552F6BFF)
            v.layer.borderColor = UIColor(argb: 0xFF6E8CFF).cgColor
        } else {
            v.backgroundColor = UIColor(white: 1, alpha: 0.09)
            v.layer.borderColor = UIColor(white: 1, alpha: 0.15).cgColor
        }
    }
}
