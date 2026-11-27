import UIKit

final class SettingsViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "设置"
        view.backgroundColor = .systemGroupedBackground
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.tintColor = .label

        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.dataSource = self
        table.delegate = self
        table.backgroundColor = .systemGroupedBackground
        table.tintColor = .label
        table.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(table)
        NSLayoutConstraint.activate([
            table.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            table.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            table.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            table.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

extension SettingsViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { 3 }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { section == 0 ? 2 : 1 }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "播放"
        case 1: return "外观"
        default: return "关于"
        }
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Setting") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "Setting")
        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            cell.textLabel?.text = "音频格式"
            cell.detailTextLabel?.text = "MP3、M4A、AAC、WAV、AIFF（依系统解码能力）"
        case (0, 1):
            cell.textLabel?.text = "音乐存储"
            cell.detailTextLabel?.text = "仅保存在本机 App 沙盒"
        case (1, _):
            cell.textLabel?.text = "外观"
            cell.detailTextLabel?.text = "跟随系统浅色 / 深色模式"
        default:
            cell.textLabel?.text = "Muse Local Music"
            cell.detailTextLabel?.text = "版本 2.0 · 最低支持 iOS 13"
        }
        cell.selectionStyle = .none
        return cell
    }
}
