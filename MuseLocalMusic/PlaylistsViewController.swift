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

        emptyView.text = "还没有播放列表\n点击右上角 + 新建"
        emptyView.numberOfLines = 0
        emptyView.textColor = .secondaryLabel
        emptyView.textAlignment = .center
        emptyView.font = .systemFont(ofSize: 15)

        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .systemBackground
        tableView.rowHeight = 62
        tableView.register(PlaylistRowCell.self, forCellReuseIdentifier: "PlaylistRow")
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
        let alert = UIAlertController(title: "新建播放列表", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "例如：通勤精选" }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "创建", style: .default) { _ in
            _ = PlaylistStore.shared.createPlaylist(named: alert.textFields?.first?.text ?? "")
        })
        present(alert, animated: true)
    }

    @objc private func refresh() {
        tableView.reloadData()
        tableView.backgroundView = playlists.isEmpty ? emptyView : nil
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { playlists.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlaylistRow", for: indexPath) as? PlaylistRowCell
            ?? PlaylistRowCell(style: .default, reuseIdentifier: "PlaylistRow")
        let playlist = playlists[indexPath.row]
        let count = PlaylistStore.shared.tracks(in: playlist.id).count
        cell.configure(title: playlist.name, subtitle: "\(count) 首歌曲", seed: playlist.name)
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let playlist = playlists[indexPath.row]
        let detail = PlaylistDetailViewController(playlistID: playlist.id)
        let cell = tableView.cellForRow(at: indexPath)
        animatePush(detail, from: cell)
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

    private func animatePush(_ viewController: UIViewController, from cell: UITableViewCell?) {
        guard let cell = cell else {
            navigationController?.pushViewController(viewController, animated: true)
            return
        }
        UIView.animate(withDuration: 0.12, animations: {
            cell.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
        }, completion: { _ in
            UIView.animate(withDuration: 0.24, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, animations: {
                cell.transform = .identity
            })
            self.navigationController?.pushViewController(viewController, animated: true)
        })
    }
}

final class PlaylistDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let playlistID: UUID
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let emptyView = UILabel()
    private let heroArtwork = ArtworkView()
    private let heroTitle = UILabel()
    private let heroSubtitle = UILabel()
    private let shuffleButton = UIButton(type: .system)
    private let playButton = UIButton(type: .system)
    private let moreButton = UIButton(type: .system)
    private var headerView: UIView?

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

        heroArtwork.corner = 12
        heroTitle.font = .systemFont(ofSize: 24, weight: .bold)
        heroTitle.textAlignment = .center
        heroTitle.numberOfLines = 2
        heroSubtitle.font = .systemFont(ofSize: 12)
        heroSubtitle.textColor = .secondaryLabel
        heroSubtitle.textAlignment = .center

        shuffleButton.setImage(UIImage(systemName: "shuffle"), for: .normal)
        shuffleButton.setTitle(" 随机播放", for: .normal)
        playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playButton.setTitle(" 播放", for: .normal)
        moreButton.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        [shuffleButton, playButton, moreButton].forEach { $0.tintColor = .label; $0.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold) }
        shuffleButton.addTarget(self, action: #selector(shuffleAll), for: .touchUpInside)
        playButton.addTarget(self, action: #selector(playAll), for: .touchUpInside)
        moreButton.addTarget(self, action: #selector(moreTapped), for: .touchUpInside)

        let controls = UIStackView(arrangedSubviews: [shuffleButton, playButton, moreButton])
        controls.axis = .horizontal
        controls.distribution = .equalSpacing
        controls.alignment = .center

        let stack = UIStackView(arrangedSubviews: [heroArtwork, heroTitle, heroSubtitle, controls])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        let header = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 330))
        header.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: header.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -12),
            heroArtwork.widthAnchor.constraint(equalToConstant: 180),
            heroArtwork.heightAnchor.constraint(equalToConstant: 180)
        ])
        headerView = header
        tableView.tableHeaderView = header

        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .systemBackground
        tableView.rowHeight = 58
        tableView.register(TrackRowCell.self, forCellReuseIdentifier: "TrackRow")
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
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: .playbackDidChange, object: nil)
        refresh()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let header = headerView else { return }
        let width = tableView.bounds.width
        if abs(header.frame.width - width) > 0.5 {
            header.frame = CGRect(x: 0, y: 0, width: width, height: header.frame.height)
            tableView.tableHeaderView = header
        }
    }

    private func pulse(_ button: UIButton) {
        let down = UIViewPropertyAnimator(duration: 0.12, dampingRatio: 1) { button.transform = CGAffineTransform(scaleX: 0.9, y: 0.9) }
        let up = UIViewPropertyAnimator(duration: 0.26, dampingRatio: 0.6) { button.transform = .identity }
        down.addCompletion { _ in up.startAnimation() }
        down.startAnimation()
    }

    @objc private func playAll() {
        guard let first = tracks.first else { return }
        pulse(playButton)
        PlaybackManager.shared.play(first, from: tracks)
        presentMuseNowPlaying()
    }

    @objc private func shuffleAll() {
        guard !tracks.isEmpty else { return }
        pulse(shuffleButton)
        PlaybackManager.shared.isShuffleEnabled = true
        let first = tracks.randomElement() ?? tracks[0]
        PlaybackManager.shared.play(first, from: tracks)
        presentMuseNowPlaying()
    }

    @objc private func addSongs() {
        navigationController?.pushViewController(TrackPickerViewController(playlistID: playlistID), animated: true)
    }

    @objc private func moreTapped() {
        let sheet = UIAlertController(title: playlist?.name, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "重命名", style: .default) { [weak self] _ in self?.renamePlaylist() })
        sheet.addAction(UIAlertAction(title: "添加歌曲", style: .default) { [weak self] _ in self?.addSongs() })
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        sheet.popoverPresentationController?.sourceView = moreButton
        present(sheet, animated: true)
    }

    @objc private func renamePlaylist() {
        let alert = UIAlertController(title: "重命名播放列表", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.text = self.playlist?.name }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "保存", style: .default) { [weak self] _ in
            guard let self = self, let name = alert.textFields?.first?.text else { return }
            PlaylistStore.shared.renamePlaylist(id: self.playlistID, to: name)
        })
        present(alert, animated: true)
    }

    @objc private func refresh() {
        title = playlist?.name ?? "播放列表"
        heroTitle.text = playlist?.name ?? "播放列表"
        heroSubtitle.text = "播放列表 · \(tracks.count) 首歌曲"
        heroArtwork.seed = playlist?.name ?? "Muse"
        tableView.reloadData()
        tableView.backgroundView = tracks.isEmpty ? emptyView : nil
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { tracks.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TrackRow", for: indexPath) as? TrackRowCell
            ?? TrackRowCell(style: .default, reuseIdentifier: "TrackRow")
        let track = tracks[indexPath.row]
        let isCurrent = PlaybackManager.shared.currentTrack?.id == track.id
        cell.configure(number: indexPath.row + 1, title: track.title, subtitle: "\(track.artist) · \(track.album)", highlighted: isCurrent)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let track = tracks[indexPath.row]
        let cell = tableView.cellForRow(at: indexPath)
        UIView.animate(withDuration: 0.12, animations: { cell?.transform = CGAffineTransform(scaleX: 0.98, y: 0.98) }, completion: { _ in
            UIView.animate(withDuration: 0.2) { cell?.transform = .identity }
            PlaybackManager.shared.play(track, from: self.tracks)
            self.presentMuseNowPlaying()
        })
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
        navigationController?.navigationBar.prefersLargeTitles = true

        emptyView.text = "曲库里还没有歌曲\n请先到资料库导入音乐"
        emptyView.numberOfLines = 0
        emptyView.textColor = .secondaryLabel
        emptyView.textAlignment = .center
        emptyView.font = .systemFont(ofSize: 15)

        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .systemBackground
        tableView.rowHeight = 58
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
        cell.imageView?.image = UIImage(systemName: "music.note")
        cell.imageView?.tintColor = .label
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

private final class PlaylistRowCell: UITableViewCell {
    private let artwork = ArtworkView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(artwork)
        artwork.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            artwork.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            artwork.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            artwork.widthAnchor.constraint(equalToConstant: 44),
            artwork.heightAnchor.constraint(equalToConstant: 44)
        ])
        textLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        detailTextLabel?.font = .systemFont(ofSize: 12)
        detailTextLabel?.textColor = .secondaryLabel
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        let inset: CGFloat = 68
        textLabel?.frame.origin.x = inset
        detailTextLabel?.frame.origin.x = inset
        textLabel?.frame.size.width = contentView.bounds.width - inset - 36
        detailTextLabel?.frame.size.width = textLabel?.frame.width ?? 0
    }

    func configure(title: String, subtitle: String, seed: String) {
        textLabel?.text = title
        detailTextLabel?.text = subtitle
        artwork.seed = seed
        artwork.corner = 8
    }
}

private final class TrackRowCell: UITableViewCell {
    private let numberLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(numberLabel)
        numberLabel.translatesAutoresizingMaskIntoConstraints = false
        numberLabel.font = .systemFont(ofSize: 13)
        numberLabel.textColor = .secondaryLabel
        numberLabel.textAlignment = .center
        NSLayoutConstraint.activate([
            numberLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            numberLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            numberLabel.widthAnchor.constraint(equalToConstant: 24)
        ])
        textLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        detailTextLabel?.font = .systemFont(ofSize: 12)
        detailTextLabel?.textColor = .secondaryLabel
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        let inset: CGFloat = 48
        textLabel?.frame.origin.x = inset
        detailTextLabel?.frame.origin.x = inset
        textLabel?.frame.size.width = contentView.bounds.width - inset - 28
        detailTextLabel?.frame.size.width = textLabel?.frame.width ?? 0
    }

    func configure(number: Int, title: String, subtitle: String, highlighted: Bool) {
        numberLabel.text = "\(number)"
        textLabel?.text = title
        detailTextLabel?.text = subtitle
        textLabel?.textColor = highlighted ? .label : .label
        detailTextLabel?.textColor = highlighted ? .label : .secondaryLabel
    }
}
