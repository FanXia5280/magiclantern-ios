import UIKit

/// 主框架：底部 4 个 Tab（主页 / 灯光 / 场景 / 设置）
///
/// 底部标签栏与导航栏都使用系统默认外观：
/// 用 Xcode 26+ / iOS 26+ SDK 构建时，系统会自动渲染为「液态玻璃浮动底栏」，
/// 因此这里不设置任何自定义 backgroundAppearance，避免覆盖原生效果。
final class MainTabController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let home = HomeViewController()
        home.tabBarItem = tabItem("主页", "house.fill")

        let light = LightViewController()
        light.tabBarItem = tabItem("灯光", "lightbulb.fill")

        let scene = SceneViewController()
        scene.tabBarItem = tabItem("场景", "sparkles")

        let settings = SettingsViewController()
        settings.tabBarItem = tabItem("设置", "gearshape.fill")

        viewControllers = [nav(home), nav(light), nav(scene), nav(settings)]

        // 交给系统渲染液态玻璃浮动底栏；只设强调色
        tabBar.tintColor = Theme.accentText
        tabBar.unselectedItemTintColor = UIColor(white: 1, alpha: 0.55)

        // 启动蓝牙
        BleController.shared.start()
    }

    private func tabItem(_ title: String, _ symbol: String) -> UITabBarItem {
        let image = UIImage(systemName: symbol)
        return UITabBarItem(title: title, image: image, tag: 0)
    }

    private func nav(_ root: UIViewController) -> UINavigationController {
        let n = UINavigationController(rootViewController: root)
        // 不设置自定义 navigationBarAppearance：让系统使用原生液态玻璃导航栏
        n.navigationBar.tintColor = Theme.accentText
        return n
    }
}
