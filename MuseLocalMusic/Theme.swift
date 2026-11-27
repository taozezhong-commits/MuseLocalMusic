import UIKit

enum Theme {
    // iOS 27.2 Apple Music still uses blue for the selected tab, while the rest of the UI is monochrome.
    static var blue: UIColor { UIColor(named: "AccentColor") ?? .systemBlue }
}

extension UIColor {
    static var museAccent: UIColor { Theme.blue }
}

final class ArtworkView: UIView {
    private let gradient = CAGradientLayer()
    private let noteView = UIImageView(image: UIImage(systemName: "music.note"))

    var seed: String = "" {
        didSet { applyGradient() }
    }

    var corner: CGFloat = 12 {
        didSet {
            layer.cornerRadius = corner
            layer.masksToBounds = true
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        layer.insertSublayer(gradient, at: 0)
        noteView.tintColor = UIColor.label.withAlphaComponent(0.72)
        noteView.contentMode = .scaleAspectFit
        addSubview(noteView)
        noteView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            noteView.centerXAnchor.constraint(equalTo: centerXAnchor),
            noteView.centerYAnchor.constraint(equalTo: centerYAnchor),
            noteView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.34),
            noteView.heightAnchor.constraint(equalTo: noteView.widthAnchor)
        ])
        corner = 12
        applyGradient()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = bounds
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applyGradient()
    }

    private func applyGradient() {
        let palettes: [(UIColor, UIColor)] = [
            (.systemGray2, .systemGray4),
            (.systemGray3, .systemGray5),
            (.systemGray4, .systemGray2),
            (.systemGray5, .systemGray3)
        ]
        let index = Int(seed.hashValue & Int.max) % palettes.count
        let pair = palettes[index]
        gradient.colors = [pair.0.cgColor, pair.1.cgColor]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        noteView.tintColor = UIColor.label.withAlphaComponent(0.72)
    }
}
