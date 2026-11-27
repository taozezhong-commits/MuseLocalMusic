import UIKit

final class MainTabBarController: UITabBarController {
    private let miniPlayer = MiniPlayerView()

    override func viewDidLoad() {
        super.viewDidLoad()

        let library = UINavigationController(rootViewController: LibraryViewController())
        library.tabBarItem = UITabBarItem(title: "资料库", image: UIImage(systemName: "music.note.list"), tag: 0)

        let search = UINavigationController(rootViewController: SearchViewController())
        search.tabBarItem = UITabBarItem(title: "搜索", image: UIImage(systemName: "magnifyingglass"), tag: 1)

        viewControllers = [library, search]
        selectedIndex = 0

        tabBar.tintColor = .museAccent
        tabBar.unselectedItemTintColor = .secondaryLabel
        tabBar.isTranslucent = true

        view.addSubview(miniPlayer)
        miniPlayer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            miniPlayer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            miniPlayer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            miniPlayer.bottomAnchor.constraint(equalTo: tabBar.topAnchor, constant: -6),
            miniPlayer.heightAnchor.constraint(equalToConstant: 64)
        ])
        miniPlayer.onTap = { [weak self] in self?.presentMuseNowPlaying() }
    }
}
