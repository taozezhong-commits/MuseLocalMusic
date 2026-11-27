import UIKit
import MediaPlayer

final class NowPlayingViewController: UIViewController {
    private let gradient = CAGradientLayer()
    private let artwork = ArtworkView()
    private let titleLabel = UILabel()
    private let artistLabel = UILabel()
    private let albumLabel = UILabel()
    private let slider = UISlider()
    private let elapsedLabel = UILabel()
    private let remainingLabel = UILabel()
    private let previousButton = UIButton(type: .system)
    private let playButton = UIButton(type: .system)
    private let nextButton = UIButton(type: .system)
    private let shuffleButton = UIButton(type: .system)
    private let repeatButton = UIButton(type: .system)
    private let routeView = MPVolumeView(frame: CGRect(x: 0, y: 0, width: 34, height: 34))
    private var timer: Timer?

    deinit {
        NotificationCenter.default.removeObserver(self)
        timer?.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.title = "正在播放"
        gradient.frame = view.bounds
        view.layer.insertSublayer(gradient, at: 0)
        applyGradient()
        buildUI()
        refresh()
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: .playbackDidChange, object: nil)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradient.frame = view.bounds
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applyGradient()
    }

    private func applyGradient() {
        if traitCollection.userInterfaceStyle == .dark {
            gradient.colors = [
                UIColor.black.cgColor,
                UIColor.systemGray.cgColor,
                UIColor.black.cgColor
            ]
        } else {
            gradient.colors = [
                UIColor.systemGray5.cgColor,
                UIColor.white.cgColor,
                UIColor.systemGray4.cgColor
            ]
        }
        gradient.startPoint = CGPoint(x: 0.1, y: 0)
        gradient.endPoint = CGPoint(x: 0.9, y: 1)
    }

    private func buildUI() {
        artwork.corner = 16
        artwork.seed = "Muse"

        titleLabel.font = .systemFont(ofSize: 26, weight: .bold)
        titleLabel.numberOfLines = 2
        titleLabel.textAlignment = .center
        artistLabel.font = .systemFont(ofSize: 18, weight: .medium)
        artistLabel.textColor = .secondaryLabel
        artistLabel.textAlignment = .center
        albumLabel.font = .systemFont(ofSize: 13)
        albumLabel.textColor = .tertiaryLabel
        albumLabel.textAlignment = .center

        elapsedLabel.font = .monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        remainingLabel.font = .monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        elapsedLabel.textColor = .secondaryLabel
        remainingLabel.textColor = .secondaryLabel

        slider.minimumTrackTintColor = .label
        slider.maximumTrackTintColor = UIColor.tertiaryLabel
        slider.thumbTintColor = .label
        slider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)

        previousButton.setImage(UIImage(systemName: "backward.end.fill"), for: .normal)
        playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        nextButton.setImage(UIImage(systemName: "forward.end.fill"), for: .normal)
        playButton.tintColor = .label
        [previousButton, nextButton].forEach { $0.tintColor = .label }
        previousButton.addTarget(self, action: #selector(previousTrack), for: .touchUpInside)
        playButton.addTarget(self, action: #selector(toggle), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(nextTrack), for: .touchUpInside)

        shuffleButton.setImage(UIImage(systemName: "shuffle"), for: .normal)
        repeatButton.setImage(UIImage(systemName: "repeat"), for: .normal)
        shuffleButton.tintColor = .secondaryLabel
        repeatButton.tintColor = .secondaryLabel
        shuffleButton.addTarget(self, action: #selector(shuffle), for: .touchUpInside)
        repeatButton.addTarget(self, action: #selector(repeatTapped), for: .touchUpInside)

        routeView.showsVolumeSlider = false
        routeView.showsRouteButton = true
        routeView.tintColor = .label
        routeView.translatesAutoresizingMaskIntoConstraints = false
        routeView.widthAnchor.constraint(equalToConstant: 34).isActive = true
        routeView.heightAnchor.constraint(equalToConstant: 34).isActive = true

        let timeRow = UIStackView(arrangedSubviews: [elapsedLabel, UIView(), remainingLabel])
        let transport = UIStackView(arrangedSubviews: [previousButton, playButton, nextButton])
        transport.axis = .horizontal
        transport.alignment = .center
        transport.distribution = .equalSpacing
        transport.heightAnchor.constraint(equalToConstant: 64).isActive = true

        let options = UIStackView(arrangedSubviews: [shuffleButton, routeView, repeatButton])
        options.axis = .horizontal
        options.alignment = .center
        options.distribution = .equalSpacing
        options.heightAnchor.constraint(equalToConstant: 40).isActive = true

        let info = UIStackView(arrangedSubviews: [titleLabel, artistLabel, albumLabel])
        info.axis = .vertical
        info.spacing = 4
        info.alignment = .center

        let stack = UIStackView(arrangedSubviews: [artwork, info, slider, timeRow, transport, options])
        stack.axis = .vertical
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 26),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -26),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 18),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            artwork.widthAnchor.constraint(equalTo: stack.widthAnchor),
            artwork.heightAnchor.constraint(equalTo: artwork.widthAnchor),
            artwork.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor, multiplier: 0.42)
        ])
    }

    private func pulse(_ view: UIView) {
        let down = UIViewPropertyAnimator(duration: 0.12, dampingRatio: 1) {
            view.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }
        let up = UIViewPropertyAnimator(duration: 0.28, dampingRatio: 0.55) {
            view.transform = .identity
        }
        down.addCompletion { _ in up.startAnimation() }
        down.startAnimation()
    }

    @objc func closeTapped() { dismiss(animated: true) }

    @objc func queueTapped() {
        let upNext = UpNextViewController()
        let nav = UINavigationController(rootViewController: upNext)
        nav.navigationBar.tintColor = .label
        upNext.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissQueue))
        present(nav, animated: true)
    }

    @objc func moreTapped() {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "播放队列", style: .default) { [weak self] _ in self?.queueTapped() })
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        sheet.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItems?.last
        present(sheet, animated: true)
    }

    @objc private func dismissQueue() { dismiss(animated: true) }

    @objc private func toggle() { pulse(playButton); PlaybackManager.shared.togglePlayPause(); refresh() }
    @objc private func previousTrack() { pulse(previousButton); PlaybackManager.shared.previous(); refresh() }
    @objc private func nextTrack() { pulse(nextButton); PlaybackManager.shared.next(); refresh() }
    @objc private func sliderChanged() { PlaybackManager.shared.seek(to: Double(slider.value)) }
    @objc private func shuffle() {
        pulse(shuffleButton)
        PlaybackManager.shared.isShuffleEnabled.toggle()
        refresh()
    }
    @objc private func repeatTapped() {
        pulse(repeatButton)
        PlaybackManager.shared.repeatMode = (PlaybackManager.shared.repeatMode + 1) % 3
        refresh()
    }

    @objc private func refresh() {
        let manager = PlaybackManager.shared
        let track = manager.currentTrack
        titleLabel.text = track?.title ?? "尚未播放"
        artistLabel.text = track?.artist ?? "请先导入音乐"
        albumLabel.text = track?.album ?? ""
        artwork.seed = track?.title ?? "Muse"
        playButton.setImage(UIImage(systemName: manager.isPlaying ? "pause.fill" : "play.fill"), for: .normal)

        slider.maximumValue = Float(max(manager.duration, 1))
        if !slider.isTracking { slider.value = Float(manager.currentTime) }
        elapsedLabel.text = format(manager.currentTime)
        remainingLabel.text = "-\(format(max(0, manager.duration - manager.currentTime)))"

        shuffleButton.tintColor = manager.isShuffleEnabled ? .label : .secondaryLabel
        repeatButton.tintColor = manager.repeatMode == 0 ? .secondaryLabel : .label
        repeatButton.setImage(UIImage(systemName: manager.repeatMode == 2 ? "repeat.1" : "repeat"), for: .normal)
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

extension UIViewController {
    func presentMuseNowPlaying() {
        let player = NowPlayingViewController()
        let nav = UINavigationController(rootViewController: player)
        nav.navigationBar.tintColor = .label
        nav.navigationBar.setBackgroundImage(UIImage(), for: .default)
        nav.navigationBar.shadowImage = UIImage()
        nav.navigationBar.isTranslucent = true
        player.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.down"), style: .plain, target: player, action: #selector(NowPlayingViewController.closeTapped))
        let queue = UIBarButtonItem(image: UIImage(systemName: "list.bullet"), style: .plain, target: player, action: #selector(NowPlayingViewController.queueTapped))
        let more = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), style: .plain, target: player, action: #selector(NowPlayingViewController.moreTapped))
        player.navigationItem.rightBarButtonItems = [queue, more]
        nav.modalPresentationStyle = .pageSheet
        if #available(iOS 15.0, *) {
            nav.sheetPresentationController?.detents = [.large()]
            nav.sheetPresentationController?.prefersGrabberVisible = true
        }
        present(nav, animated: true)
    }
}

final class UpNextViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let emptyView = UILabel()
    private var queue: [Track] { PlaybackManager.shared.queue }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "播放队列"
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.prefersLargeTitles = true

        emptyView.text = "队列是空的\n从资料库选择歌曲开始播放"
        emptyView.numberOfLines = 0
        emptyView.textColor = .secondaryLabel
        emptyView.textAlignment = .center
        emptyView.font = .systemFont(ofSize: 15)

        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .systemBackground
        tableView.rowHeight = 56
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: .playbackDidChange, object: nil)
        refresh()
    }

    @objc private func refresh() {
        tableView.reloadData()
        tableView.backgroundView = queue.isEmpty ? emptyView : nil
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { queue.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "QueueCell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "QueueCell")
        let track = queue[indexPath.row]
        cell.textLabel?.text = track.title
        cell.detailTextLabel?.text = track.artist
        cell.imageView?.image = UIImage(systemName: PlaybackManager.shared.currentTrack?.id == track.id ? "waveform" : "music.note")
        cell.imageView?.tintColor = .label
        cell.accessoryType = PlaybackManager.shared.currentTrack?.id == track.id ? .checkmark : .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        PlaybackManager.shared.play(queue[indexPath.row], from: queue)
        refresh()
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
