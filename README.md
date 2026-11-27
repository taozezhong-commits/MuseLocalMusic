# Muse — Local Music

一个面向 iOS 13+ 的轻量原生本地音乐播放器原型，使用 Swift + UIKit + AVFoundation。

## 当前第一版功能

- 从 iOS「文件」App 导入本地音频（复制到应用沙盒）
- 本地曲库列表、标题/艺人/专辑搜索
- MP3、M4A、AAC、WAV、AIFF 等系统支持格式（实际解码能力取决于 iOS）
- 播放、暂停、上一首、下一首、进度拖动
- 随机播放、单曲循环、列表循环
- 后台音频模式、锁屏媒体信息、耳机/控制中心播放命令
- 自动跟随系统浅色/深色模式

## 重要限制

1. 这是第一版可构建工程，不是已经经过真机 QA 的正式发行版。
2. FLAC 不保证由 `AVAudioPlayer` 原生解码；后续如需 FLAC/APE，需要单独评估轻量解码库。
3. 当前播放列表页只是占位；封面图读取与显示、持久化播放队列、均衡器、歌词、完整播放列表管理将在后续版本完善。
4. 30 MB 是目标，不是实测承诺。实际 IPA/App 大小由 Xcode、架构、系统库链接及压缩结果决定。此项目不内置媒体资源或大型第三方 SDK，较有利于控制体积。
5. 默认 Bundle ID 为 `com.taozezhong.MuseLocalMusic`。自签/上架前请按自己的 Apple 开发者账号修改。

## 云端构建（不需要 Mac）

1. 在 GitHub 创建一个空仓库。
2. 上传本项目全部文件，保持 `.github/workflows/build-ipa.yml` 路径不变。
3. 打开仓库的 **Actions** 页面。
4. 选择 **Build unsigned iOS IPA**，点击 **Run workflow**。
5. 构建完成后，在运行记录底部的 Artifacts 下载 `Muse-unsigned-IPA`，解压得到 `Muse-unsigned.ipa`。

工作流使用 GitHub 提供的 macOS runner 和 Xcode 编译未签名 IPA。未签名 IPA 不能直接安装。

## 在 iPhone 上自签安装

可使用 AltStore / SideStore 等个人签名工具：

1. 先按工具官方说明完成 Apple ID / 配对 / JIT 或本地服务所需设置（不同工具要求不同）。
2. 将 `Muse-unsigned.ipa` 导入签名工具。
3. 使用自己的 Apple ID 签名并安装。
4. 免费个人签名通常有有效期和 App 数量限制；证书过期后需要重新签名安装。

不要把 Apple ID 密码、双重认证验证码或证书私钥提交到 GitHub 仓库或公开 Issue。

## 相对初版的修复

- 修复 `project.pbxproj` 中 `BuildIndependentTargetsInParallel` 拼写错误导致的工程解析失败。
- 修复 `AVMetadataKey` 与 `String` 比较导致的编译错误。
- 删除歌曲时同步播放队列；导入/删除后即时刷新搜索结果。
- 定时更新锁屏播放进度；处理音频中断和音频路由变化。
- 不支持或已损坏的音频在导入时给出明确提示，不再静默写入曲库。
- 补充 shared scheme、LaunchScreen.storyboard，CI 构建参数更明确。

## 修改 Bundle ID

打开 `MuseLocalMusic.xcodeproj/project.pbxproj`，将 `com.taozezhong.MuseLocalMusic` 替换为你自己的唯一 Bundle ID。也可在 Xcode 的 Signing & Capabilities 中修改。

## 版本规划

- v1.0：本地导入、基本播放、后台/锁屏控制
- v1.1：真正读取并展示专辑封面、专辑/艺人分组
- v1.2：创建/编辑播放列表、播放队列持久化
- v1.3：歌词、更多音频格式（按体积要求评估）
