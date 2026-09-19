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

        tabBar.tintColor = Theme.accentText
        tabBar.unselectedItemTintColor = Theme.textSecondary

        // 液态玻璃标签栏（iOS 15+ 用系统外观 + 磨砂；旧版本用半透明）
        if #available(iOS 15.0, *) {
            let ap = UITabBarAppearance()
            ap.configureWithDefaultBackground()
            ap.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
            ap.backgroundColor = UIColor(white: 0.04, alpha: 0.35)
            tabBar.standardAppearance = ap
            tabBar.scrollEdgeAppearance = ap
        } else {
            tabBar.barTintColor = .clear
            tabBar.isTranslucent = true
        }

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
        n.navigationBar.tintColor = Theme.accentText

        // 液态玻璃导航栏
        if #available(iOS 15.0, *) {
            let ap = UINavigationBarAppearance()
            ap.configureWithDefaultBackground()
            ap.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
            ap.backgroundColor = UIColor(white: 0.04, alpha: 0.3)
            ap.titleTextAttributes = [.foregroundColor: Theme.textPrimary]
            ap.largeTitleTextAttributes = [.foregroundColor: Theme.textPrimary]
            n.navigationBar.standardAppearance = ap
            n.navigationBar.scrollEdgeAppearance = ap
            n.navigationBar.compactAppearance = ap
        } else {
            n.navigationBar.barTintColor = Theme.bg
            n.navigationBar.isTranslucent = true
            n.navigationBar.titleTextAttributes = [.foregroundColor: Theme.textPrimary]
        }
        return n
    }
}
