import UIKit

final class MiniPlayerView: UIControl, UIGestureRecognizerDelegate {
    private let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    private let artwork = ArtworkView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let previousButton = UIButton(type: .system)
    private let playButton = UIButton(type: .system)
    private let nextButton = UIButton(type: .system)
    private let progress = UIProgressView(progressViewStyle: .default)
    private var timer: Timer?
    var onTap: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 12
        layer.masksToBounds = true

        blur.frame = bounds
        blur.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        insertSubview(blur, at: 0)

        artwork.corner = 8
        artwork.seed = "Muse"
        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        subtitleLabel.font = .systemFont(ofSize: 11)
        subtitleLabel.textColor = .secondaryLabel

        let labels = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        labels.axis = .vertical
        labels.spacing = 2
        labels.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        previousButton.setImage(UIImage(systemName: "backward.end.fill"), for: .normal)
        playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        nextButton.setImage(UIImage(systemName: "forward.end.fill"), for: .normal)
        [previousButton, playButton, nextButton].forEach { button in
            button.tintColor = .label
            button.imageView?.contentMode = .scaleAspectFit
            button.isExclusiveTouch = true
        }
        previousButton.accessibilityLabel = "上一首"
        playButton.accessibilityLabel = "播放或暂停"
        nextButton.accessibilityLabel = "下一首"
        previousButton.addTarget(self, action: #selector(previousTrack), for: .touchUpInside)
        playButton.addTarget(self, action: #selector(toggle), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(nextTrack), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [artwork, labels, previousButton, playButton, nextButton])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        artwork.widthAnchor.constraint(equalToConstant: 40).isActive = true
        artwork.heightAnchor.constraint(equalToConstant: 40).isActive = true
        previousButton.widthAnchor.constraint(equalToConstant: 24).isActive = true
        playButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        nextButton.widthAnchor.constraint(equalToConstant: 24).isActive = true
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 7),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -9)
        ])

        progress.translatesAutoresizingMaskIntoConstraints = false
        progress.progressTintColor = .label
        progress.trackTintColor = .clear
        addSubview(progress)
        NSLayoutConstraint.activate([
            progress.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            progress.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            progress.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -3),
            progress.heightAnchor.constraint(equalToConstant: 2)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        tap.delegate = self
        addGestureRecognizer(tap)

        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: .playbackDidChange, object: nil)
        refresh()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit {
        NotificationCenter.default.removeObserver(self)
        timer?.invalidate()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
                self?.updateProgress()
            }
        } else {
            timer?.invalidate()
            timer = nil
        }
    }

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer is UITapGestureRecognizer else { return true }
        let point = gestureRecognizer.location(in: self)
        guard let hit = hitTest(point, with: nil) else { return true }
        return !(hit is UIButton)
    }

    @objc func refresh() {
        if let track = PlaybackManager.shared.currentTrack {
            titleLabel.text = track.title
            subtitleLabel.text = track.artist
            artwork.seed = track.title
        } else {
            titleLabel.text = "Muse"
            subtitleLabel.text = "从文件导入本地音乐"
            artwork.seed = "Muse"
        }
        let image = PlaybackManager.shared.isPlaying ? "pause.fill" : "play.fill"
        playButton.setImage(UIImage(systemName: image), for: .normal)
        updateProgress()
    }

    private func updateProgress() {
        let manager = PlaybackManager.shared
        let duration = manager.duration
        progress.progress = duration > 0 ? Float(min(max(manager.currentTime / duration, 0), 1)) : 0
    }

    @objc private func toggle() { PlaybackManager.shared.togglePlayPause(); refresh() }
    @objc private func previousTrack() { PlaybackManager.shared.previous(); refresh() }
    @objc private func nextTrack() { PlaybackManager.shared.next(); refresh() }
    @objc private func tapped() { onTap?() }
}
