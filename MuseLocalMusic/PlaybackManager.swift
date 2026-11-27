import Foundation
import AVFoundation
import MediaPlayer

final class PlaybackManager: NSObject, AVAudioPlayerDelegate {
    static let shared = PlaybackManager()

    private(set) var player: AVAudioPlayer?
    private(set) var currentTrack: Track?
    private(set) var queue: [Track] = []
    private var currentIndex = 0
    private var progressTimer: Timer?
    private var shouldResumeAfterInterruption = false

    var isShuffleEnabled = false
    var repeatMode = 0 // 0: off, 1: all, 2: one

    var isPlaying: Bool { player?.isPlaying ?? false }
    var currentTime: TimeInterval { player?.currentTime ?? 0 }
    var duration: TimeInterval { player?.duration ?? currentTrack?.duration ?? 0 }

    private override init() {
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTrackRemoved(_:)),
            name: .libraryDidRemoveTrack,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange(_:)),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        progressTimer?.invalidate()
    }

    func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
        } catch {
            print("Audio session error: \(error)")
        }
        configureRemoteCommands()
        startProgressTimer()
    }

    func reactivateAudioSession() {
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    func play(_ track: Track, from tracks: [Track]? = nil) {
        if let tracks = tracks, !tracks.isEmpty {
            queue = tracks
            currentIndex = tracks.firstIndex(of: track) ?? 0
        } else if queue.isEmpty || !queue.contains(track) {
            queue = [track]
            currentIndex = 0
        } else {
            currentIndex = queue.firstIndex(of: track) ?? 0
        }
        startCurrentTrack()
    }

    func togglePlayPause() {
        guard let player = player else {
            if let first = LibraryStore.shared.tracks.first {
                play(first, from: LibraryStore.shared.tracks)
            }
            return
        }
        if player.isPlaying { player.pause() } else { player.play() }
        updateNowPlaying()
        postChange()
    }

    func seek(to time: TimeInterval) {
        player?.currentTime = max(0, min(time, duration))
        updateNowPlaying()
    }

    func next() {
        guard !queue.isEmpty else { return }
        if isShuffleEnabled && queue.count > 1 {
            var nextIndex = currentIndex
            while nextIndex == currentIndex { nextIndex = Int.random(in: 0..<queue.count) }
            currentIndex = nextIndex
        } else if currentIndex + 1 < queue.count {
            currentIndex += 1
        } else if repeatMode == 1 {
            currentIndex = 0
        } else {
            player?.stop()
            postChange()
            return
        }
        startCurrentTrack()
    }

    func previous() {
        guard !queue.isEmpty else { return }
        if currentTime > 3 {
            seek(to: 0)
        } else {
            currentIndex = max(0, currentIndex - 1)
            startCurrentTrack()
        }
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if repeatMode == 2 {
            startCurrentTrack()
        } else {
            next()
        }
    }

    // MARK: - Private

    private func startCurrentTrack(autoPlay: Bool = true) {
        guard queue.indices.contains(currentIndex) else { return }
        let track = queue[currentIndex]
        do {
            player?.stop()
            let newPlayer = try AVAudioPlayer(contentsOf: track.url)
            newPlayer.delegate = self
            newPlayer.prepareToPlay()
            player = newPlayer
            currentTrack = track
            if autoPlay { newPlayer.play() }
            updateNowPlaying()
            postChange()
        } catch {
            print("Cannot play \(track.fileName): \(error)")
        }
    }

    private func startProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, self.isPlaying else { return }
            self.updateNowPlaying()
        }
    }

    private func configureRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()

        center.playCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            if !self.isPlaying {
                if self.player == nil {
                    if let first = LibraryStore.shared.tracks.first {
                        self.play(first, from: LibraryStore.shared.tracks)
                    }
                } else {
                    self.player?.play()
                    self.updateNowPlaying()
                    self.postChange()
                }
            }
            return .success
        }

        center.pauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            if self.isPlaying {
                self.player?.pause()
                self.updateNowPlaying()
                self.postChange()
            }
            return .success
        }

        center.nextTrackCommand.addTarget { [weak self] _ in
            self?.next()
            return .success
        }
        center.previousTrackCommand.addTarget { [weak self] _ in
            self?.previous()
            return .success
        }
        center.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            self?.seek(to: event.positionTime)
            return .success
        }
    }

    @objc private func handleTrackRemoved(_ notification: Notification) {
        guard let removedID = notification.userInfo?["trackID"] as? UUID,
              let removedIndex = queue.firstIndex(where: { $0.id == removedID }) else { return }

        let removedCurrent = removedIndex == currentIndex
        let wasPlaying = isPlaying
        queue.remove(at: removedIndex)

        if queue.isEmpty {
            player?.stop()
            player = nil
            currentTrack = nil
            currentIndex = 0
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            postChange()
            return
        }

        if removedCurrent {
            currentIndex = min(currentIndex, queue.count - 1)
            startCurrentTrack(autoPlay: wasPlaying)
        } else if removedIndex < currentIndex {
            currentIndex -= 1
        }
        postChange()
    }

    @objc private func handleInterruption(_ notification: Notification) {
        guard let rawType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: rawType) else { return }

        switch type {
        case .began:
            shouldResumeAfterInterruption = isPlaying
            player?.pause()
            updateNowPlaying()
            postChange()
        case .ended:
            guard shouldResumeAfterInterruption else { return }
            shouldResumeAfterInterruption = false
            let rawOptions = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            let options = AVAudioSession.InterruptionOptions(rawValue: rawOptions)
            guard options.contains(.shouldResume) else { return }
            do {
                try AVAudioSession.sharedInstance().setActive(true)
                player?.play()
                updateNowPlaying()
                postChange()
            } catch {
                print("Resume audio session error: \(error)")
            }
        }
    }

    @objc private func handleRouteChange(_ notification: Notification) {
        guard let rawReason = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: rawReason),
              reason == .oldDeviceUnavailable else { return }
        player?.pause()
        updateNowPlaying()
        postChange()
    }

    private func updateNowPlaying() {
        guard let track = currentTrack else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        let info: [String: Any] = [
            MPMediaItemPropertyTitle: track.title,
            MPMediaItemPropertyArtist: track.artist,
            MPMediaItemPropertyAlbumTitle: track.album,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func postChange() {
        NotificationCenter.default.post(name: .playbackDidChange, object: nil)
    }
}
