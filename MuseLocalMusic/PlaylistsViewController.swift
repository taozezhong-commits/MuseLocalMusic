import UIKit

final class PlaylistsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let emptyView = UILabel()
    private var playlists: [Playlist] { PlaylistStore.shared.playlists }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "播放列表"
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addPlaylist))

        emptyView.text = "还没有歌单\n点击右上角 + 新建"
        emptyView.numberOfLines = 0
        emptyView.textColor = .secondaryLabel
        emptyView.textAlignment = .center
        emptyView.font = .systemFont(ofSize: 15)

        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .systemBackground
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: .playlistsDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: .libraryDidChange, object: nil)
        refresh()
    }

    @objc private func addPlaylist() {
        let alert = UIAlertController(title: "新建歌单", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "例如：通勤精选" }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "创建", style: .default) { _ in
            let name = alert.textFields?.first?.text ?? ""
            _ = PlaylistStore.shared.createPlaylist(named: name)
        })
        present(alert, animated: true)
    }

    @objc private func refresh() {
        tableView.reloadData()
        tableView.backgroundView = playlists.isEmpty ? emptyView : nil
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { playlists.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlaylistCell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "PlaylistCell")
        let playlist = playlists[indexPath.row]
        let count = PlaylistStore.shared.tracks(in: playlist.id).count
        cell.textLabel?.text = playlist.name
        cell.detailTextLabel?.text = "\(count) 首歌曲"
        cell.imageView?.image = UIImage(systemName: "music.note.list")
        cell.imageView?.tintColor = .museAccent
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let detail = PlaylistDetailViewController(playlistID: playlists[indexPath.row].id)
        navigationController?.pushViewController(detail, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let playlist = playlists[indexPath.row]
        let delete = UIContextualAction(style: .destructive, title: "删除") { _, _, done in
            PlaylistStore.shared.deletePlaylist(id: playlist.id)
            done(true)
        }
        return UISwipeActionsConfiguration(actions: [delete])
    }
}

final class PlaylistDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let playlistID: UUID
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let emptyView = UILabel()
    private var tracks: [Track] { PlaylistStore.shared.tracks(in: playlistID) }
    private var playlist: Playlist? { PlaylistStore.shared.playlists.first { $0.id == playlistID } }

    init(playlistID: UUID) {
        self.playlistID = playlistID
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addSongs))

        emptyView.text = "歌单还是空的\n点击右上角 + 添加歌曲"
        emptyView.numberOfLines = 0
        emptyView.textColor = .secondaryLabel
        emptyView.textAlignment = .center
        emptyView.font = .systemFont(ofSize: 15)

        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .systemBackground
        tableView.tableHeaderView = makeHeader()
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: .playlistsDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: .libraryDidChange, object: nil)
        refresh()
    }

    private func makeHeader() -> UIView {
        let play = UIButton(type: .system)
        play.setTitle("▶ 播放全部", for: .normal)
        play.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        play.tintColor = .museAccent
        play.addTarget(self, action: #selector(playAll), for: .touchUpInside)

        let rename = UIButton(type: .system)
        rename.setTitle("重命名", for: .normal)
        rename.titleLabel?.font = .systemFont(ofSize: 15)
        rename.addTarget(self, action: #selector(renamePlaylist), for: .touchUpInside)

        let row = UIStackView(arrangedSubviews: [play, UIView(), rename])
        row.axis = .horizontal
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false
        let header = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 58))
        header.addSubview(row)
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 20),
            row.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -20),
            row.topAnchor.constraint(equalTo: header.topAnchor, constant: 8),
            row.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -8)
        ])
        return header
    }

    @objc private func playAll() {
        guard let first = tracks.first else { return }
        PlaybackManager.shared.play(first, from: tracks)
        showNowPlaying()
    }

    @objc private func addSongs() {
        let picker = TrackPickerViewController(playlistID: playlistID)
        navigationController?.pushViewController(picker, animated: true)
    }

    @objc private func renamePlaylist() {
        let alert = UIAlertController(title: "重命名歌单", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.text = self.playlist?.name }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "保存", style: .default) { [weak self] _ in
            guard let self = self, let name = alert.textFields?.first?.text else { return }
            PlaylistStore.shared.renamePlaylist(id: self.playlistID, to: name)
        })
        present(alert, animated: true)
    }

    @objc private func refresh() {
        title = playlist?.name ?? "歌单"
        tableView.reloadData()
        tableView.backgroundView = tracks.isEmpty ? emptyView : nil
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { tracks.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlaylistTrackCell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "PlaylistTrackCell")
        let track = tracks[indexPath.row]
        cell.textLabel?.text = track.title
        cell.detailTextLabel?.text = "\(track.artist) · \(track.album)"
        cell.imageView?.image = UIImage(systemName: "music.note")
        cell.imageView?.tintColor = .secondaryLabel
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        PlaybackManager.shared.play(tracks[indexPath.row], from: tracks)
        showNowPlaying()
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let track = tracks[indexPath.row]
        let remove = UIContextualAction(style: .destructive, title: "移出") { _, _, done in
            PlaylistStore.shared.remove(trackID: track.id, from: self.playlistID)
            done(true)
        }
        return UISwipeActionsConfiguration(actions: [remove])
    }

    private func showNowPlaying() {
        let vc = NowPlayingViewController()
        vc.modalPresentationStyle = .pageSheet
        if #available(iOS 15.0, *) {
            vc.sheetPresentationController?.detents = [.medium(), .large()]
            vc.sheetPresentationController?.prefersGrabberVisible = true
        }
        present(vc, animated: true)
    }
}

final class TrackPickerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let playlistID: UUID
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let emptyView = UILabel()
    private var tracks: [Track] { LibraryStore.shared.tracks }

    init(playlistID: UUID) {
        self.playlistID = playlistID
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "添加歌曲"
        view.backgroundColor = .systemBackground

        emptyView.text = "曲库里还没有歌曲\n请先到「资料库」导入音乐"
        emptyView.numberOfLines = 0
        emptyView.textColor = .secondaryLabel
        emptyView.textAlignment = .center
        emptyView.font = .systemFont(ofSize: 15)

        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .systemBackground
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: .playlistsDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: .libraryDidChange, object: nil)
        refresh()
    }

    @objc private func refresh() {
        tableView.reloadData()
        tableView.backgroundView = tracks.isEmpty ? emptyView : nil
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { tracks.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PickerCell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "PickerCell")
        let track = tracks[indexPath.row]
        cell.textLabel?.text = track.title
        cell.detailTextLabel?.text = "\(track.artist) · \(track.album)"
        cell.accessoryType = PlaylistStore.shared.contains(trackID: track.id, in: playlistID) ? .checkmark : .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let track = tracks[indexPath.row]
        if PlaylistStore.shared.contains(trackID: track.id, in: playlistID) {
            PlaylistStore.shared.remove(trackID: track.id, from: playlistID)
        } else {
            PlaylistStore.shared.add(trackID: track.id, to: playlistID)
        }
        tableView.reloadRows(at: [indexPath], with: .automatic)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
