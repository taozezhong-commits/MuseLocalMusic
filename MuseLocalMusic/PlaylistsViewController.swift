import UIKit

final class PlaylistsViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "播放列表"
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.prefersLargeTitles = true
        let label = UILabel()
        label.text = "播放列表功能将在下一版本加入"
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
