import UIKit

final class SettingsViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "设置"
        view.backgroundColor = .systemGroupedBackground
        navigationController?.navigationBar.prefersLargeTitles = true

        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.dataSource = self
        table.delegate = self
        table.backgroundColor = .systemGroupedBackground
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
    func numberOfSections(in tableView: UITableView) -> Int { 2 }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { section == 0 ? 2 : 1 }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? "播放" : "关于"
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Setting") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "Setting")
        if indexPath.section == 0 && indexPath.row == 0 {
            cell.textLabel?.text = "音频格式"
            cell.detailTextLabel?.text = "MP3、M4A、AAC、WAV、AIFF（依系统解码能力）"
        } else if indexPath.section == 0 {
            cell.textLabel?.text = "音乐存储"
            cell.detailTextLabel?.text = "仅保存在本机 App 沙盒"
        } else {
            cell.textLabel?.text = "Muse Local Music"
            cell.detailTextLabel?.text = "版本 1.1 · 最低支持 iOS 13"
        }
        cell.selectionStyle = .none
        return cell
    }
}
