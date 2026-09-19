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

extension UIViewController {

    /// 纯色背景（自动跟随浅色 / 深色模式）
    func applyGlassBackground() {
        view.backgroundColor = Theme.bg
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

    /// 移除玻璃背景（未选中态只留文字，避免一堆灰底显得零碎）
    static func removeGlassBackground(_ v: UIView) {
        v.viewWithTag(glassTag)?.removeFromSuperview()
        v.backgroundColor = .clear
    }
}
