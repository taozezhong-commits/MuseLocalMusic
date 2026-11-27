import Foundation
import AVFoundation

struct Track: Codable, Equatable {
    let id: UUID
    var fileName: String
    var title: String
    var artist: String
    var album: String
    var duration: TimeInterval

    var url: URL {
        LibraryStore.musicDirectory.appendingPathComponent(fileName)
    }

    static func from(url: URL, storedAs fileName: String) -> Track {
        let asset = AVURLAsset(url: url)

        func text(_ key: AVMetadataKey, fallback: String) -> String {
            if let item = asset.commonMetadata.first(where: { $0.commonKey == key }),
               let value = item.stringValue, !value.isEmpty {
                return value
            }
            return fallback
        }

        let player = try? AVAudioPlayer(contentsOf: url)
        let base = url.deletingPathExtension().lastPathComponent
        return Track(
            id: UUID(),
            fileName: fileName,
            title: text(.commonKeyTitle, fallback: base),
            artist: text(.commonKeyArtist, fallback: "未知艺人"),
            album: text(.commonKeyAlbumName, fallback: "未知专辑"),
            duration: player?.duration ?? 0
        )
    }

    static func isPlayable(at url: URL) -> Bool {
        guard let player = try? AVAudioPlayer(contentsOf: url) else { return false }
        return player.duration.isFinite && player.duration > 0
    }
}
