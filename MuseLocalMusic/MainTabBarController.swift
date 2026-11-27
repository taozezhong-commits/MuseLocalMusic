import UIKit

final class MainTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        let library = UINavigationController(rootViewController: LibraryViewController())
        library.tabBarItem = UITabBarItem(title: "资料库", image: UIImage(systemName: "square.stack"), tag: 0)

        let playlists = UINavigationController(rootViewController: PlaylistsViewController())
        playlists.tabBarItem = UITabBarItem(title: "播放列表", image: UIImage(systemName: "music.note.list"), tag: 1)

        let settings = UINavigationController(rootViewController: SettingsViewController())
        settings.tabBarItem = UITabBarItem(title: "设置", image: UIImage(systemName: "gearshape"), tag: 2)

        viewControllers = [library, playlists, settings]
        tabBar.tintColor = .museAccent
        tabBar.isTranslucent = true
    }
}
