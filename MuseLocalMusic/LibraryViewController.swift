import UIKit
import UniformTypeIdentifiers

final class LibraryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIDocumentPickerDelegate, UISearchResultsUpdating {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let miniPlayer = MiniPlayerView()
    private let searchController = UISearchController(searchResultsController: nil)
    private let emptyView = UILabel()
    private var filteredTracks: [Track] = []
    private var tracks: [Track] { LibraryStore.shared.tracks }
    private var isSearching: Bool { !(searchController.searchBar.text ?? "").isEmpty }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "资料库"
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(importMusic))
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        navigationItem.searchController = searchController
        definesPresentationContext = true

        emptyView.text = "还没有音乐\n点击右上角 + 从「文件」导入"
        emptyView.numberOfLines = 0
        emptyView.textColor = .secondaryLabel
        emptyView.textAlignment = .center
        emptyView.font = .systemFont(ofSize: 15)

        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .systemBackground
        tableView.tintColor = .museAccent
        view.addSubview(tableView)
        view.addSubview(miniPlayer)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        miniPlayer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            miniPlayer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            miniPlayer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            miniPlayer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -6),
            miniPlayer.heightAnchor.constraint(equalToConstant: 62),
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: miniPlayer.topAnchor, constant: -8)
        ])
        miniPlayer.onTap = { [weak self] in self?.showNowPlaying() }
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: .libraryDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: .playbackDidChange, object: nil)
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
        if let firstFailure = failures.first {
            let message = failures.count == 1
                ? firstFailure
                : "\(failures.count) 个文件无法导入。\(firstFailure)"
            let alert = UIAlertController(title: "部分文件导入失败", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "好", style: .default))
            present(alert, animated: true)
        }
        refresh()
    }

    @objc private func refresh() {
        applyFilter()
        tableView.reloadData()
        updateEmptyState()
        miniPlayer.refresh()
    }

    func updateSearchResults(for searchController: UISearchController) {
        applyFilter()
        tableView.reloadData()
        updateEmptyState()
    }

    private func updateEmptyState() {
        tableView.backgroundView = displayedTracks.isEmpty ? emptyView : nil
    }

    private func applyFilter() {
        let q = (searchController.searchBar.text ?? "").lowercased()
        filteredTracks = tracks.filter {
            $0.title.lowercased().contains(q) || $0.artist.lowercased().contains(q) || $0.album.lowercased().contains(q)
        }
    }

    private var displayedTracks: [Track] {
        isSearching ? filteredTracks : tracks
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { displayedTracks.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TrackCell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "TrackCell")
        let track = displayedTracks[indexPath.row]
        cell.textLabel?.text = track.title
        cell.detailTextLabel?.text = "\(track.artist) · \(track.album)"
        cell.imageView?.image = UIImage(systemName: "music.note")
        cell.imageView?.tintColor = .secondaryLabel
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let track = displayedTracks[indexPath.row]
        PlaybackManager.shared.play(track, from: tracks)
        showNowPlaying()
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let track = displayedTracks[indexPath.row]
        let delete = UIContextualAction(style: .destructive, title: "删除") { _, _, done in
            LibraryStore.shared.remove(track)
            done(true)
        }
        return UISwipeActionsConfiguration(actions: [delete])
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
