import UIKit

final class SearchViewController: UIViewController, UISearchResultsUpdating, UITableViewDataSource, UITableViewDelegate {
    private enum Row {
        case track(Track)
        case playlist(Playlist)
        case detail(title: String, subtitle: String, symbol: String)
        case category(String)
    }

    private struct Section {
        let title: String
        let rows: [Row]
    }

    private let searchController = UISearchController(searchResultsController: nil)
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let emptyView = UILabel()
    private var sections: [Section] = []
    private var selectedCategory: String?

    private var query: String {
        searchController.searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private var isSearching: Bool { !query.isEmpty }
    private var tracks: [Track] { LibraryStore.shared.tracks }
    private var playlists: [Playlist] { PlaylistStore.shared.playlists }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "搜索"
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.prefersLargeTitles = true

        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "艺人、歌曲或专辑"
        searchController.searchBar.tintColor = .label
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true

        emptyView.text = "没有找到结果\n试试其他关键词"
        emptyView.numberOfLines = 0
        emptyView.textColor = .secondaryLabel
        emptyView.textAlignment = .center
        emptyView.font = .systemFont(ofSize: 15)

        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .systemBackground
        tableView.rowHeight = 58
        tableView.register(RowCell.self, forCellReuseIdentifier: "SearchRow")
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
        refresh()
    }

    func updateSearchResults(for searchController: UISearchController) {
        if isSearching { selectedCategory = nil }
        refresh()
    }

    @objc private func refresh() {
        rebuildSections()
        tableView.reloadData()
        tableView.backgroundView = sections.isEmpty ? emptyView : nil
    }

    private func rebuildSections() {
        if isSearching {
            let q = query.lowercased()
            let matchedTracks = tracks.filter {
                $0.title.lowercased().contains(q) || $0.artist.lowercased().contains(q) || $0.album.lowercased().contains(q)
            }
            let matchedArtists = Array(Set(matchedTracks.map { $0.artist })).sorted()
            let matchedAlbums = Array(Set(matchedTracks.map { $0.album })).sorted()
            let matchedPlaylists = playlists.filter { $0.name.lowercased().contains(q) }

            sections = []
            if !matchedTracks.isEmpty {
                sections.append(Section(title: "歌曲", rows: matchedTracks.map { .track($0) }))
            }
            if !matchedArtists.isEmpty {
                sections.append(Section(title: "艺人", rows: matchedArtists.map {
                    .detail(title: $0, subtitle: "", symbol: "person.crop.circle")
                }))
            }
            if !matchedAlbums.isEmpty {
                sections.append(Section(title: "专辑", rows: matchedAlbums.map {
                    .detail(title: $0, subtitle: "", symbol: "square.stack")
                }))
            }
            if !matchedPlaylists.isEmpty {
                sections.append(Section(title: "播放列表", rows: matchedPlaylists.map { .playlist($0) }))
            }
            return
        }

        if let category = selectedCategory {
            switch category {
            case "歌曲":
                sections = tracks.isEmpty ? [] : [Section(title: "歌曲", rows: tracks.map { .track($0) })]
            case "艺人":
                let names = Array(Set(tracks.map { $0.artist })).sorted()
                sections = names.isEmpty ? [] : [Section(title: "艺人", rows: names.map {
                    .detail(title: $0, subtitle: "", symbol: "person.crop.circle")
                })]
            case "专辑":
                let names = Array(Set(tracks.map { $0.album })).sorted()
                sections = names.isEmpty ? [] : [Section(title: "专辑", rows: names.map {
                    .detail(title: $0, subtitle: "", symbol: "square.stack")
                })]
            case "播放列表":
                sections = playlists.isEmpty ? [] : [Section(title: "播放列表", rows: playlists.map { .playlist($0) })]
            default:
                sections = []
            }
            return
        }

        sections = [Section(title: "浏览", rows: [
            .category("歌曲"),
            .category("艺人"),
            .category("专辑"),
            .category("播放列表")
        ])]
    }

    func numberOfSections(in tableView: UITableView) -> Int { sections.count }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { sections[section].rows.count }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { sections[section].title }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchRow", for: indexPath) as? RowCell
            ?? RowCell(style: .default, reuseIdentifier: "SearchRow")
        switch sections[indexPath.section].rows[indexPath.row] {
        case .track(let track):
            cell.configure(title: track.title, subtitle: "\(track.artist) · \(track.album)", seed: track.title, symbol: nil)
            cell.accessoryType = .none
        case .playlist(let playlist):
            let count = PlaylistStore.shared.tracks(in: playlist.id).count
            cell.configure(title: playlist.name, subtitle: "\(count) 首歌曲", seed: playlist.name, symbol: nil)
            cell.accessoryType = .disclosureIndicator
        case .detail(let title, let subtitle, let symbol):
            cell.configure(title: title, subtitle: subtitle, seed: title, symbol: symbol)
            cell.accessoryType = .disclosureIndicator
        case .category(let title):
            let symbol: String
            let subtitle: String
            switch title {
            case "歌曲": symbol = "music.note"; subtitle = "\(tracks.count) 首"
            case "艺人": symbol = "person.crop.circle"; subtitle = "\(Set(tracks.map { $0.artist }).count) 位"
            case "专辑": symbol = "square.stack"; subtitle = "\(Set(tracks.map { $0.album }).count) 张"
            default: symbol = "music.note.list"; subtitle = "\(playlists.count) 个"
            }
            cell.configure(title: title, subtitle: subtitle, seed: title, symbol: symbol)
            cell.accessoryType = .disclosureIndicator
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = sections[indexPath.section].rows[indexPath.row]
        let cell = tableView.cellForRow(at: indexPath)
        switch row {
        case .track(let track):
            PlaybackManager.shared.play(track, from: tracks)
            presentMuseNowPlaying()
        case .playlist(let playlist):
            pushPlaylist(playlist, from: cell)
        case .detail(let title, _, _):
            searchController.searchBar.text = title
            selectedCategory = nil
            refresh()
        case .category(let title):
            selectedCategory = title
            refresh()
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    private func pushPlaylist(_ playlist: Playlist, from cell: UITableViewCell?) {
        let detail = PlaylistDetailViewController(playlistID: playlist.id)
        animatePush(detail, from: cell)
    }

    private func animatePush(_ viewController: UIViewController, from cell: UITableViewCell?) {
        guard let cell = cell else {
            navigationController?.pushViewController(viewController, animated: true)
            return
        }
        UIView.animate(withDuration: 0.12, animations: {
            cell.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
        }, completion: { _ in
            UIView.animate(withDuration: 0.22, animations: {
                cell.transform = .identity
            })
            self.navigationController?.pushViewController(viewController, animated: true)
        })
    }
}

private final class RowCell: UITableViewCell {
    private let artwork = ArtworkView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(artwork)
        artwork.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            artwork.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            artwork.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            artwork.widthAnchor.constraint(equalToConstant: 42),
            artwork.heightAnchor.constraint(equalToConstant: 42)
        ])
        textLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        detailTextLabel?.font = .systemFont(ofSize: 12)
        detailTextLabel?.textColor = .secondaryLabel
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        let imageInset: CGFloat = 66
        textLabel?.frame.origin.x = imageInset
        detailTextLabel?.frame.origin.x = imageInset
        textLabel?.frame.size.width = contentView.bounds.width - imageInset - 36
        detailTextLabel?.frame.size.width = textLabel?.frame.width ?? 0
    }

    func configure(title: String, subtitle: String, seed: String, symbol: String?) {
        textLabel?.text = title
        detailTextLabel?.text = subtitle
        if let symbol = symbol {
            artwork.isHidden = false
            artwork.seed = seed
            artwork.corner = 8
        } else {
            artwork.isHidden = false
            artwork.seed = seed
            artwork.corner = 8
        }
    }
}
