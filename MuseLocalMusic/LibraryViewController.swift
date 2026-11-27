import UIKit
import UniformTypeIdentifiers

final class LibraryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UIDocumentPickerDelegate {
    private enum Mode: Int { case recent, playlists, songs }
    private enum DisplaySection { case playlists, songs }

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let header = UIView()
    private let segmented = UISegmentedControl(items: ["最近播放", "播放列表", "歌曲"])
    private let recentLabel = UILabel()
    private let emptyView = UILabel()
    private var mode: Mode = .recent

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 118, height: 150)
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .clear
        view.showsHorizontalScrollIndicator = false
        view.dataSource = self
        view.delegate = self
        view.register(RecentCell.self, forCellWithReuseIdentifier: "RecentCell")
        return view
    }()

    private var tracks: [Track] { LibraryStore.shared.tracks }
    private var playlists: [Playlist] { PlaylistStore.shared.playlists }
    private var recentPlaylists: [Playlist] { Array(playlists.prefix(8)) }

    private var displaySections: [DisplaySection] {
        switch mode {
        case .recent: return [.playlists, .songs]
        case .playlists: return [.playlists]
        case .songs: return [.songs]
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "资料库"
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.prefersLargeTitles = true

        let add = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(importMusic))
        let settings = UIBarButtonItem(image: UIImage(systemName: "gearshape"), style: .plain, target: self, action: #selector(openSettings))
        navigationItem.rightBarButtonItems = [add, settings]

        segmented.selectedSegmentIndex = 0
        segmented.addTarget(self, action: #selector(modeChanged), for: .valueChanged)
        if #available(iOS 13.0, *) {
            segmented.selectedSegmentTintColor = .systemGray5
        }
        segmented.setTitleTextAttributes([.foregroundColor: UIColor.secondaryLabel], for: .normal)
        segmented.setTitleTextAttributes([.foregroundColor: UIColor.label], for: .selected)

        recentLabel.text = "最近播放"
        recentLabel.font = .systemFont(ofSize: 20, weight: .bold)

        emptyView.text = "资料库还是空的\n点击右上角 + 导入本地音乐"
        emptyView.numberOfLines = 0
        emptyView.textColor = .secondaryLabel
        emptyView.textAlignment = .center
        emptyView.font = .systemFont(ofSize: 15)

        buildHeader()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .systemBackground
        tableView.rowHeight = 58
        tableView.register(LibraryCell.self, forCellReuseIdentifier: "LibraryCell")
        tableView.tableHeaderView = header
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: .libraryDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: .playlistsDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: .playbackDidChange, object: nil)
        refresh()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let width = tableView.bounds.width
        guard width > 0 else { return }
        let size = CGSize(width: width, height: UIView.layoutFittingCompressedSize.height)
        let height = header.systemLayoutSizeFitting(size, withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel).height
        if abs(header.frame.height - height) > 0.5 {
            header.frame = CGRect(x: 0, y: 0, width: width, height: height)
            tableView.tableHeaderView = header
        }
    }

    private func buildHeader() {
        header.addSubview(segmented)
        header.addSubview(recentLabel)
        header.addSubview(collectionView)
        [segmented, recentLabel, collectionView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            segmented.topAnchor.constraint(equalTo: header.topAnchor, constant: 12),
            segmented.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 16),
            segmented.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -16),
            recentLabel.topAnchor.constraint(equalTo: segmented.bottomAnchor, constant: 18),
            recentLabel.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 20),
            collectionView.topAnchor.constraint(equalTo: recentLabel.bottomAnchor, constant: 10),
            collectionView.leadingAnchor.constraint(equalTo: header.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: header.trailingAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: 150),
            collectionView.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -12)
        ])
    }

    @objc private func modeChanged() {
        mode = Mode(rawValue: segmented.selectedSegmentIndex) ?? .recent
        refresh()
    }

    @objc private func importMusic() {
        if #available(iOS 14.0, *) {
            var types: [UTType] = [.audio, .mp3, .mpeg4Audio, .aiff]
            if let wave = UTType("com.microsoft.waveform-audio") { types.append(wave) }
            let picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: true)
            presentPicker(picker)
        } else {
            let types = ["public.audio", "public.mp3", "public.mpeg-4-audio", "public.aiff-audio", "com.microsoft.waveform-audio"]
            let picker = UIDocumentPickerViewController(documentTypes: types, in: .import)
            presentPicker(picker)
        }
    }

    @objc private func openSettings() {
        let settings = SettingsViewController()
        let nav = UINavigationController(rootViewController: settings)
        settings.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissSettings))
        present(nav, animated: true)
    }

    @objc private func dismissSettings() {
        dismiss(animated: true)
    }

    private func presentPicker(_ picker: UIDocumentPickerViewController) {
        picker.delegate = self
        picker.allowsMultipleSelection = true
        present(picker, animated: true)
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        var failures: [String] = []
        for url in urls {
            do {
                try LibraryStore.shared.addImportedFile(at: url)
            } catch {
                failures.append(error.localizedDescription)
            }
        }
        if let first = failures.first {
            let message = failures.count == 1 ? first : "\(failures.count) 个文件无法导入。\(first)"
            let alert = UIAlertController(title: "部分文件导入失败", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "好", style: .default))
            present(alert, animated: true)
        }
        refresh()
    }

    @objc private func refresh() {
        collectionView.reloadData()
        tableView.reloadData()
        let isEmpty = displaySections.allSatisfy { section in
            switch section {
            case .playlists: return displayedPlaylists.isEmpty
            case .songs: return displayedTracks.isEmpty
            }
        }
        tableView.backgroundView = isEmpty ? emptyView : nil
    }

    private var displayedPlaylists: [Playlist] {
        mode == .recent ? Array(playlists.prefix(6)) : playlists
    }

    private var displayedTracks: [Track] {
        mode == .recent ? Array(tracks.prefix(10)) : tracks
    }

    // MARK: - Collection

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { recentPlaylists.count }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RecentCell", for: indexPath) as? RecentCell
            ?? RecentCell(frame: .zero)
        cell.configure(playlist: recentPlaylists[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let playlist = recentPlaylists[indexPath.item]
        let cell = collectionView.cellForItem(at: indexPath)
        pushPlaylist(playlist, from: cell)
    }

    // MARK: - Table

    func numberOfSections(in tableView: UITableView) -> Int { displaySections.count }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch displaySections[section] {
        case .playlists: return displayedPlaylists.count
        case .songs: return displayedTracks.count
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch displaySections[section] {
        case .playlists: return "播放列表"
        case .songs: return "歌曲"
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LibraryCell", for: indexPath) as? LibraryCell
            ?? LibraryCell(style: .default, reuseIdentifier: "LibraryCell")
        switch displaySections[indexPath.section] {
        case .playlists:
            let playlist = displayedPlaylists[indexPath.row]
            cell.configure(title: playlist.name, subtitle: "\(PlaylistStore.shared.tracks(in: playlist.id).count) 首歌曲", seed: playlist.name)
            cell.accessoryType = .disclosureIndicator
        case .songs:
            let track = displayedTracks[indexPath.row]
            cell.configure(title: track.title, subtitle: "\(track.artist) · \(track.album)", seed: track.title)
            cell.accessoryType = .none
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        switch displaySections[indexPath.section] {
        case .playlists:
            pushPlaylist(displayedPlaylists[indexPath.row], from: cell)
        case .songs:
            let track = displayedTracks[indexPath.row]
            PlaybackManager.shared.play(track, from: tracks)
            presentMuseNowPlaying()
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        switch displaySections[indexPath.section] {
        case .playlists:
            let playlist = displayedPlaylists[indexPath.row]
            let delete = UIContextualAction(style: .destructive, title: "删除") { _, _, done in
                PlaylistStore.shared.deletePlaylist(id: playlist.id)
                done(true)
            }
            return UISwipeActionsConfiguration(actions: [delete])
        case .songs:
            let track = displayedTracks[indexPath.row]
            let delete = UIContextualAction(style: .destructive, title: "删除") { _, _, done in
                LibraryStore.shared.remove(track)
                done(true)
            }
            return UISwipeActionsConfiguration(actions: [delete])
        }
    }

    private func pushPlaylist(_ playlist: Playlist, from cell: UIView?) {
        let detail = PlaylistDetailViewController(playlistID: playlist.id)
        guard let cell = cell else {
            navigationController?.pushViewController(detail, animated: true)
            return
        }
        UIView.animate(withDuration: 0.12, animations: {
            cell.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        }, completion: { _ in
            UIView.animate(withDuration: 0.22, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, animations: {
                cell.transform = .identity
            })
            self.navigationController?.pushViewController(detail, animated: true)
        })
    }
}

private final class LibraryCell: UITableViewCell {
    private let artwork = ArtworkView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(artwork)
        artwork.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            artwork.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            artwork.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            artwork.widthAnchor.constraint(equalToConstant: 40),
            artwork.heightAnchor.constraint(equalToConstant: 40)
        ])
        textLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        detailTextLabel?.font = .systemFont(ofSize: 12)
        detailTextLabel?.textColor = .secondaryLabel
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        let inset: CGFloat = 64
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

private final class RecentCell: UICollectionViewCell {
    private let artwork = ArtworkView()
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(artwork)
        contentView.addSubview(label)
        artwork.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            artwork.topAnchor.constraint(equalTo: contentView.topAnchor),
            artwork.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            artwork.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            artwork.heightAnchor.constraint(equalToConstant: 118),
            label.topAnchor.constraint(equalTo: artwork.bottomAnchor, constant: 8),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            label.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor)
        ])
        artwork.corner = 10
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.numberOfLines = 2
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(playlist: Playlist) {
        artwork.seed = playlist.name
        label.text = playlist.name
    }
}
