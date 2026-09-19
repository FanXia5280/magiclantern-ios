import UIKit

/// 主框架：底部 4 个 Tab（主页 / 灯光 / 场景 / 设置）
/// 底栏交给系统渲染为液态玻璃浮动胶囊；设置为其中之一。
final class MainTabController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let home = HomeViewController()
        home.tabBarItem = iconItem("主页", "house.fill")

        let light = LightViewController()
        light.tabBarItem = iconItem("灯光", "lightbulb.fill")

        let scene = SceneViewController()
        scene.tabBarItem = iconItem("场景", "sparkles")

        let settings = SettingsViewController()
        settings.tabBarItem = iconItem("设置", "gearshape.fill")

        viewControllers = [nav(home), nav(light), nav(scene), nav(settings)]

        tabBar.tintColor = Theme.accentText
        tabBar.unselectedItemTintColor = Theme.textThird

        // 启动蓝牙
        BleController.shared.start()
    }

    /// 只显示图标的 Tab 项
    ///
    /// 注意：title 必须传**空字符串**而不是 nil ——
    /// 传 nil 时系统会回退，用 view controller 的 title（如"氛围灯控制"）当底栏文字。
    private func iconItem(_ accessibilityTitle: String, _ symbol: String) -> UITabBarItem {
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        let image = UIImage(systemName: symbol, withConfiguration: config)
        let item = UITabBarItem(title: "", image: image, tag: 0)
        item.accessibilityLabel = accessibilityTitle
        return item
    }

    private func nav(_ root: UIViewController) -> UINavigationController {
        let n = UINavigationController(rootViewController: root)
        // 不设置自定义导航栏外观：让系统使用原生液态玻璃
        n.navigationBar.tintColor = Theme.accentText
        return n
    }
}
