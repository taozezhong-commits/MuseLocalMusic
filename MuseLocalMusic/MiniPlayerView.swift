import UIKit

final class MiniPlayerView: UIControl {
    private let icon = UIImageView(image: UIImage(systemName: "waveform"))
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let playButton = UIButton(type: .system)
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
        playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playButton.tintColor = .label
        playButton.addTarget(self, action: #selector(toggle), for: .touchUpInside)
        let stack = UIStackView(arrangedSubviews: [icon, labels, playButton])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        icon.widthAnchor.constraint(equalToConstant: 26).isActive = true
        playButton.widthAnchor.constraint(equalToConstant: 34).isActive = true
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 13),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6)
        ])
        addTarget(self, action: #selector(tapped), for: .touchUpInside)
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: .playbackDidChange, object: nil)
        refresh()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit {
        NotificationCenter.default.removeObserver(self)
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
    @objc private func tapped() { onTap?() }
}
