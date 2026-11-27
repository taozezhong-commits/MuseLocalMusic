import UIKit

final class MiniPlayerView: UIControl, UIGestureRecognizerDelegate {
    private let icon = UIImageView(image: UIImage(systemName: "waveform"))
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let previousButton = UIButton(type: .system)
    private let playButton = UIButton(type: .system)
    private let nextButton = UIButton(type: .system)
    var onTap: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 13
        layer.masksToBounds = true

        icon.tintColor = .museAccent
        icon.contentMode = .scaleAspectFit
        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
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

        let stack = UIStackView(arrangedSubviews: [icon, labels, previousButton, playButton, nextButton])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        icon.widthAnchor.constraint(equalToConstant: 24).isActive = true
        previousButton.widthAnchor.constraint(equalToConstant: 24).isActive = true
        playButton.widthAnchor.constraint(equalToConstant: 32).isActive = true
        nextButton.widthAnchor.constraint(equalToConstant: 24).isActive = true
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6)
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
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer is UITapGestureRecognizer else { return true }
        let point = gestureRecognizer.location(in: self)
        guard let hit = hitTest(point, with: nil) else { return true }
        return !(hit is UIButton)
    }

    @objc func refresh() {
        if let track = PlaybackManager.shared.currentTrack {
            titleLabel.text = track.title
            subtitleLabel.text = track.artist
        } else {
            titleLabel.text = "欢迎使用 Muse"
            subtitleLabel.text = "从文件导入本地音乐"
        }
        let image = PlaybackManager.shared.isPlaying ? "pause.fill" : "play.fill"
        playButton.setImage(UIImage(systemName: image), for: .normal)
    }

    @objc private func toggle() { PlaybackManager.shared.togglePlayPause(); refresh() }
    @objc private func previousTrack() { PlaybackManager.shared.previous(); refresh() }
    @objc private func nextTrack() { PlaybackManager.shared.next(); refresh() }
    @objc private func tapped() { onTap?() }
}
