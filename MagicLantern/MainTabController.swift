import UIKit

/// 主框架：
/// - 底部只放 3 个「纯图标」Tab（主页 / 灯光 / 场景），由系统渲染为液态玻璃浮动胶囊
/// - 「设置」独立出来，做成右下角的圆形液态玻璃悬浮按钮
final class MainTabController: UITabBarController {

    private let settingsButton = UIButton(type: .system)
    private let fabSize: CGFloat = 54

    override func viewDidLoad() {
        super.viewDidLoad()

        let home = HomeViewController()
        home.tabBarItem = iconItem("主页", "house.fill")

        let light = LightViewController()
        light.tabBarItem = iconItem("灯光", "lightbulb.fill")

        let scene = SceneViewController()
        scene.tabBarItem = iconItem("场景", "sparkles")

        viewControllers = [nav(home), nav(light), nav(scene)]

        tabBar.tintColor = Theme.accentText
        tabBar.unselectedItemTintColor = Theme.textThird

        setupSettingsButton()

        // 启动蓝牙
        BleController.shared.start()
    }

    /// 只要图标、不要文字的 Tab 项
    private func iconItem(_ accessibilityTitle: String, _ symbol: String) -> UITabBarItem {
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        let image = UIImage(systemName: symbol, withConfiguration: config)
        let item = UITabBarItem(title: nil, image: image, tag: 0)
        item.accessibilityLabel = accessibilityTitle
        return item
    }

    /// 圆形液态玻璃按钮（设置）：与底部导航栏并排，位于其右侧
    private func setupSettingsButton() {
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        settingsButton.setImage(UIImage(systemName: "gearshape.fill", withConfiguration: config),
                                for: .normal)
        settingsButton.tintColor = Theme.textPrimary
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        Glass.addGlassBackground(settingsButton, radius: fabSize / 2, interactive: true)
        view.addSubview(settingsButton)

        NSLayoutConstraint.activate([
            settingsButton.widthAnchor.constraint(equalToConstant: fabSize),
            settingsButton.heightAnchor.constraint(equalToConstant: fabSize),
            settingsButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                                                     constant: -14),
            // 与底栏同一水平线（像系统"照片"App 那样）
            settingsButton.centerYAnchor.constraint(equalTo: tabBar.centerYAnchor)
        ])
        settingsButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
    }

    @objc private func openSettings() {
        guard let nav = selectedViewController as? UINavigationController else { return }
        nav.pushViewController(SettingsViewController(), animated: true)
    }

    private func nav(_ root: UIViewController) -> UINavigationController {
        let n = UINavigationController(rootViewController: root)
        // 不设置自定义导航栏外观：让系统使用原生液态玻璃
        n.navigationBar.tintColor = Theme.accentText
        return n
    }
}
