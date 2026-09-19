import UIKit

/// 原生液态玻璃卡片（UIKit Liquid Glass：UIGlassEffect，iOS 26+）
final class GlassCard: UIView {

    private let glass: UIVisualEffectView

    init(radius: CGFloat = 24, interactive: Bool = true, tint: UIColor? = nil) {
        let effect = UIGlassEffect(style: .regular)
        effect.isInteractive = interactive
        effect.tintColor = tint
        glass = UIVisualEffectView(effect: effect)
        super.init(frame: .zero)

        backgroundColor = .clear
        layer.cornerRadius = radius
        layer.cornerCurve = .continuous
        layer.masksToBounds = true

        glass.isUserInteractionEnabled = false
        glass.layer.cornerRadius = radius
        glass.layer.cornerCurve = .continuous
        glass.clipsToBounds = true
        glass.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(glass)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        glass.frame = bounds
    }

    /// 保持调用兼容（原生玻璃自带光学高光，无需额外绘制）
    func showShine(_ on: Bool) {
        setNeedsLayout()
    }

    /// 更新玻璃色调
    func setTint(_ color: UIColor?) {
        if let e = glass.effect as? UIGlassEffect {
            e.tintColor = color
            glass.effect = e
        }
    }
}

/// 背景：深色底 + 柔和光晕（给玻璃提供层次，克制不抢戏）
final class AuroraBackground: UIView {

    private let blobA = UIView()
    private let blobB = UIView()
    private let blobC = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(argb: 0xFF05060A)
        isUserInteractionEnabled = false

        blobA.backgroundColor = UIColor(argb: 0x333B5BFF)   // 蓝
        blobB.backgroundColor = UIColor(argb: 0x2A6B4BFF)   // 紫
        blobC.backgroundColor = UIColor(argb: 0x1F2FBFDF)   // 青

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
        circle(blobA, -w * 0.30, -h * 0.12, w * 1.00)
        circle(blobB, w * 0.50, h * 0.48, w * 1.05)
        circle(blobC, -w * 0.05, h * 0.72, w * 0.8)
    }

    private func circle(_ v: UIView, _ x: CGFloat, _ y: CGFloat, _ size: CGFloat) {
        v.frame = CGRect(x: x, y: y, width: size, height: size)
        v.layer.cornerRadius = size / 2
        v.layer.masksToBounds = true
    }
}

extension UIViewController {

    /// 给页面铺上深色 + 光晕背景
    func applyGlassBackground() {
        view.backgroundColor = UIColor(argb: 0xFF05060A)
        let bg = AuroraBackground()
        bg.frame = view.bounds
        bg.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(bg, at: 0)
    }
}

/// 原生液态玻璃样式工具
enum Glass {

    private static let glassTag = 88001

    /// 给任意视图注入原生液态玻璃背景
    static func addGlassBackground(_ v: UIView, radius: CGFloat,
                                   interactive: Bool = true, tint: UIColor? = nil) {
        v.backgroundColor = .clear
        v.layer.cornerRadius = radius
        v.layer.cornerCurve = .continuous

        // 已存在则只更新色调（避免重建导致闪烁）
        if let old = v.viewWithTag(glassTag) as? UIVisualEffectView {
            old.frame = v.bounds
            old.layer.cornerRadius = radius
            if let e = old.effect as? UIGlassEffect {
                e.tintColor = tint
                e.isInteractive = interactive
                old.effect = e
            }
            return
        }

        let effect = UIGlassEffect(style: .regular)
        effect.isInteractive = interactive
        effect.tintColor = tint

        let g = UIVisualEffectView(effect: effect)
        g.tag = glassTag
        g.isUserInteractionEnabled = false
        g.frame = v.bounds
        g.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        g.layer.cornerRadius = radius
        g.layer.cornerCurve = .continuous
        g.clipsToBounds = true
        v.insertSubview(g, at: 0)
    }

    /// 液态玻璃按钮
    static func styleButton(_ b: UIButton, radius: CGFloat = 16, accent: Bool = false) {
        addGlassBackground(b, radius: radius, interactive: true,
                           tint: accent ? Theme.accent : nil)
    }

    /// 液态玻璃方块（模式按钮 / 列表项等）
    static func styleTile(_ v: UIView, selected: Bool = false, radius: CGFloat = 18) {
        addGlassBackground(v, radius: radius, interactive: true,
                           tint: selected ? Theme.accent : nil)
    }

    /// 胶囊（分类切换等）
    static func styleChip(_ v: UIView, selected: Bool, radius: CGFloat = 17) {
        addGlassBackground(v, radius: radius, interactive: true,
                           tint: selected ? Theme.accent : nil)
    }
}
