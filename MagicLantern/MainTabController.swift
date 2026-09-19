import UIKit

/// 主框架：底部 4 个 Tab（主页 / 灯光 / 场景 / 设置）
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

        tabBar.barTintColor = Theme.card
        tabBar.tintColor = Theme.accentText
        tabBar.unselectedItemTintColor = Theme.textSecondary
        tabBar.isTranslucent = false

        // 启动蓝牙
        BleController.shared.start()
    }

    private func tabItem(_ title: String, _ symbol: String) -> UITabBarItem {
        var image: UIImage? = nil
        if #available(iOS 13.0, *) {
            image = UIImage(systemName: symbol)
        }
        return UITabBarItem(title: title, image: image, tag: 0)
    }

    private func nav(_ root: UIViewController) -> UINavigationController {
        let n = UINavigationController(rootViewController: root)
        n.navigationBar.barTintColor = Theme.bg
        n.navigationBar.tintColor = Theme.accentText
        n.navigationBar.isTranslucent = false
        n.navigationBar.titleTextAttributes = [.foregroundColor: Theme.textPrimary]
        return n
    }
}
