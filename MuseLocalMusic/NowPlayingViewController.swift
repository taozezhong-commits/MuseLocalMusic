import UIKit

final class NowPlayingViewController: UIViewController {
    private let artwork = UIView()
    private let artworkIcon = UIImageView(image: UIImage(systemName: "waveform"))
    private let titleLabel = UILabel()
    private let artistLabel = UILabel()
    private let slider = UISlider()
    private let elapsedLabel = UILabel()
    private let remainingLabel = UILabel()
    private let playButton = UIButton(type: .system)
    private let shuffleButton = UIButton(type: .system)
    private let repeatButton = UIButton(type: .system)
    private var timer: Timer?

    deinit {
        NotificationCenter.default.removeObserver(self)
        timer?.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        buildUI()
        refresh()
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: .playbackDidChange, object: nil)
    }

    private func buildUI() {
        artwork.backgroundColor = .secondarySystemBackground
        artwork.layer.cornerRadius = 22
        artwork.clipsToBounds = true
        artworkIcon.tintColor = .systemRed
        artworkIcon.contentMode = .scaleAspectFit
        artwork.addSubview(artworkIcon)
        artworkIcon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            artworkIcon.centerXAnchor.constraint(equalTo: artwork.centerXAnchor),
            artworkIcon.centerYAnchor.constraint(equalTo: artwork.centerYAnchor),
            artworkIcon.widthAnchor.constraint(equalTo: artwork.widthAnchor, multiplier: 0.35),
            artworkIcon.heightAnchor.constraint(equalTo: artworkIcon.widthAnchor)
        ])

        titleLabel.font = .systemFont(ofSize: 23, weight: .bold)
        titleLabel.numberOfLines = 2
        artistLabel.font = .systemFont(ofSize: 16)
        artistLabel.textColor = .secondaryLabel
        elapsedLabel.font = .monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        remainingLabel.font = .monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        elapsedLabel.textColor = .secondaryLabel
        remainingLabel.textColor = .secondaryLabel
        slider.minimumTrackTintColor = .systemRed
        slider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)

        let timeRow = UIStackView(arrangedSubviews: [elapsedLabel, UIView(), remainingLabel])
        let transport = UIStackView(arrangedSubviews: [
            makeButton("backward.end.fill", action: #selector(previous)),
            playButton,
            makeButton("forward.end.fill", action: #selector(nextTrack))
        ])
        transport.axis = .horizontal
        transport.alignment = .center
        transport.distribution = .equalSpacing
        playButton.titleLabel?.font = .systemFont(ofSize: 42)
        playButton.addTarget(self, action: #selector(toggle), for: .touchUpInside)

        let options = UIStackView(arrangedSubviews: [
            shuffleButton,
            UIView(),
            repeatButton
        ])
        shuffleButton.setImage(UIImage(systemName: "shuffle"), for: .normal)
        repeatButton.setImage(UIImage(systemName: "repeat"), for: .normal)
        shuffleButton.addTarget(self, action: #selector(shuffle), for: .touchUpInside)
        repeatButton.addTarget(self, action: #selector(repeatTapped), for: .touchUpInside)
        shuffleButton.tintColor = .secondaryLabel
        repeatButton.tintColor = .secondaryLabel

        let stack = UIStackView(arrangedSubviews: [artwork, titleLabel, artistLabel, slider, timeRow, transport, options])
        stack.axis = .vertical
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 26),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -26),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            artwork.heightAnchor.constraint(equalTo: artwork.widthAnchor),
            artwork.heightAnchor.constraint(lessThanOrEqualToConstant: 300),
            transport.heightAnchor.constraint(equalToConstant: 62)
        ])
    }

    private func makeButton(_ image: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: image), for: .normal)
        button.tintColor = .label
        button.titleLabel?.font = .systemFont(ofSize: 25)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    @objc private func toggle() { PlaybackManager.shared.togglePlayPause(); refresh() }
    @objc private func previous() { PlaybackManager.shared.previous(); refresh() }
    @objc private func nextTrack() { PlaybackManager.shared.next(); refresh() }
    @objc private func sliderChanged() { PlaybackManager.shared.seek(to: Double(slider.value)) }
    @objc private func shuffle() {
        PlaybackManager.shared.isShuffleEnabled.toggle()
        refresh()
    }
    @objc private func repeatTapped() {
        PlaybackManager.shared.repeatMode = (PlaybackManager.shared.repeatMode + 1) % 3
        refresh()
    }

    @objc private func refresh() {
        let manager = PlaybackManager.shared
        titleLabel.text = manager.currentTrack?.title ?? "尚未播放"
        artistLabel.text = manager.currentTrack?.artist ?? "请先导入音乐"
        playButton.setImage(UIImage(systemName: manager.isPlaying ? "pause.fill" : "play.fill"), for: .normal)

        slider.maximumValue = Float(max(manager.duration, 1))
        if !slider.isTracking {
            slider.value = Float(manager.currentTime)
        }
        elapsedLabel.text = format(manager.currentTime)
        remainingLabel.text = "-\(format(max(0, manager.duration - manager.currentTime)))"

        let mode = manager.repeatMode
        shuffleButton.tintColor = manager.isShuffleEnabled ? .systemRed : .secondaryLabel
        repeatButton.tintColor = mode == 0 ? .secondaryLabel : .systemRed
        repeatButton.setImage(UIImage(systemName: mode == 2 ? "repeat.1" : "repeat"), for: .normal)
    }

    private func format(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite else { return "0:00" }
        let value = max(0, Int(seconds))
        return String(format: "%d:%02d", value / 60, value % 60)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in self?.refresh() }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
        timer = nil
    }
}
