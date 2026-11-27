import Foundation
import AVFoundation

enum LibraryError: LocalizedError {
    case unsupportedFile(String)
    case inaccessible(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedFile(let name):
            return "“\(name)” 不是可播放的音频文件，或文件已损坏。"
        case .inaccessible(let name):
            return "无法读取“\(name)”，请检查文件权限。"
        }
    }
}

final class LibraryStore {
    static let shared = LibraryStore()
    static var musicDirectory: URL = {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folder = documents.appendingPathComponent("Music", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }()

    private(set) var tracks: [Track] = []
    private let indexURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("library.json")

    private init() { load() }

    func addImportedFile(at sourceURL: URL) throws {
        let accessed = sourceURL.startAccessingSecurityScopedResource()
        defer { if accessed { sourceURL.stopAccessingSecurityScopedResource() } }

        guard FileManager.default.fileExists(atPath: sourceURL.path) else {
            throw LibraryError.inaccessible(sourceURL.lastPathComponent)
        }
        guard Track.isPlayable(at: sourceURL) else {
            throw LibraryError.unsupportedFile(sourceURL.lastPathComponent)
        }

        let ext = sourceURL.pathExtension.isEmpty ? "audio" : sourceURL.pathExtension
        let base = sourceURL.deletingPathExtension().lastPathComponent
        var destination = LibraryStore.musicDirectory.appendingPathComponent("\(base).\(ext)")
        var suffix = 2
        while FileManager.default.fileExists(atPath: destination.path) {
            destination = LibraryStore.musicDirectory.appendingPathComponent("\(base)-\(suffix).\(ext)")
            suffix += 1
        }

        try FileManager.default.copyItem(at: sourceURL, to: destination)
        let track = Track.from(url: destination, storedAs: destination.lastPathComponent)
        tracks.append(track)
        save()
        NotificationCenter.default.post(name: .libraryDidChange, object: nil)
    }

    func remove(_ track: Track) {
        guard tracks.contains(where: { $0.id == track.id }) else { return }
        tracks.removeAll { $0.id == track.id }
        try? FileManager.default.removeItem(at: track.url)
        save()
        NotificationCenter.default.post(
            name: .libraryDidRemoveTrack,
            object: nil,
            userInfo: ["trackID": track.id]
        )
        NotificationCenter.default.post(name: .libraryDidChange, object: nil)
    }

    func save() {
        guard let data = try? JSONEncoder().encode(tracks) else { return }
        try? data.write(to: indexURL, options: .atomic)
    }

    private func load() {
        guard let data = try? Data(contentsOf: indexURL),
              let decoded = try? JSONDecoder().decode([Track].self, from: data) else { return }
        let valid = decoded.filter { FileManager.default.fileExists(atPath: $0.url.path) }
        tracks = valid
        if valid.count != decoded.count { save() }
    }
}

extension Notification.Name {
    static let libraryDidChange = Notification.Name("MuseLibraryDidChange")
    static let libraryDidRemoveTrack = Notification.Name("MuseLibraryDidRemoveTrack")
    static let playbackDidChange = Notification.Name("MusePlaybackDidChange")
}
