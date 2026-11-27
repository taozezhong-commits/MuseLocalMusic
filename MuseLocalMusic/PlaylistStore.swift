import Foundation
import UIKit

struct Playlist: Codable, Equatable, Identifiable {
    let id: UUID
    var name: String
    var trackIDs: [UUID]
    var createdAt: Date

    init(id: UUID = UUID(), name: String, trackIDs: [UUID] = [], createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.trackIDs = trackIDs
        self.createdAt = createdAt
    }
}

final class PlaylistStore {
    static let shared = PlaylistStore()

    private(set) var playlists: [Playlist] = []
    private let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("playlists.json")

    private init() {
        load()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTrackRemoved(_:)),
            name: .libraryDidRemoveTrack,
            object: nil
        )
    }

    func createPlaylist(named rawName: String) -> Playlist {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        let playlist = Playlist(name: name.isEmpty ? "新建歌单" : name)
        playlists.append(playlist)
        persist()
        return playlist
    }

    func renamePlaylist(id: UUID, to rawName: String) {
        guard let index = playlists.firstIndex(where: { $0.id == id }) else { return }
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        playlists[index].name = name.isEmpty ? playlists[index].name : name
        persist()
    }

    func deletePlaylist(id: UUID) {
        playlists.removeAll { $0.id == id }
        persist()
    }

    func tracks(in playlistID: UUID) -> [Track] {
        guard let playlist = playlists.first(where: { $0.id == playlistID }) else { return [] }
        let library = LibraryStore.shared.tracks
        return playlist.trackIDs.compactMap { id in library.first { $0.id == id } }
    }

    func contains(trackID: UUID, in playlistID: UUID) -> Bool {
        playlists.first { $0.id == playlistID }?.trackIDs.contains(trackID) ?? false
    }

    func add(trackID: UUID, to playlistID: UUID) {
        guard let index = playlists.firstIndex(where: { $0.id == playlistID }) else { return }
        guard !playlists[index].trackIDs.contains(trackID) else { return }
        playlists[index].trackIDs.append(trackID)
        persist()
    }

    func remove(trackID: UUID, from playlistID: UUID) {
        guard let index = playlists.firstIndex(where: { $0.id == playlistID }) else { return }
        playlists[index].trackIDs.removeAll { $0 == trackID }
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(playlists) else { return }
        try? data.write(to: storeURL, options: .atomic)
        NotificationCenter.default.post(name: .playlistsDidChange, object: nil)
    }

    private func load() {
        guard let data = try? Data(contentsOf: storeURL),
              let decoded = try? JSONDecoder().decode([Playlist].self, from: data) else { return }
        playlists = decoded
    }

    @objc private func handleTrackRemoved(_ notification: Notification) {
        guard let removedID = notification.userInfo?["trackID"] as? UUID else { return }
        var changed = false
        for index in playlists.indices where playlists[index].trackIDs.contains(removedID) {
            playlists[index].trackIDs.removeAll { $0 == removedID }
            changed = true
        }
        if changed { persist() }
    }
}

extension Notification.Name {
    static let playlistsDidChange = Notification.Name("MusePlaylistsDidChange")
}

extension UIColor {
    static var museAccent: UIColor {
        UIColor(named: "AccentColor") ?? .systemRed
    }
}
