import UIKit

/// iOS 26+ 强制要求使用 UIScene 生命周期：
/// 用新 SDK 构建的 App 如果缺省 scene 配置，启动时会被系统直接终止（闪退）。
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let w = UIWindow(windowScene: windowScene)
        w.backgroundColor = Theme.bg
        w.rootViewController = MainTabController()
        w.makeKeyAndVisible()
        window = w
    }
}
