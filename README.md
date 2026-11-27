# Muse — Local Music

一个面向 iOS 13+ 的轻量原生本地音乐播放器，使用 Swift + UIKit + AVFoundation。v1.1 已补齐 App 图标、主题色和可用的播放列表功能。

## 功能

- 从 iOS「文件」App 导入本地音频，复制到应用沙盒，不依赖网络
- 资料库列表、标题/艺人/专辑搜索、空状态引导
- 支持 MP3、M4A、AAC、WAV、AIFF 等系统可解码格式
- 播放、暂停、上一首/下一首、进度拖动；迷你播放条也支持上一首/下一首，点击歌曲信息区域进入播放页
- 随机播放、单曲循环、列表循环
- 后台音频、锁屏媒体信息与进度、耳机/控制中心播放命令
- 音频中断与耳机拔出后的播放状态处理
- 播放列表：新建、重命名、删除、添加/移除歌曲、播放整张歌单，数据本地持久化
- 自定义 App 图标与全局主题色，自动跟随系统浅色/深色模式

## 重要限制

1. 未经过完整真机 QA，属于自用/自签级别的原生工程。
2. FLAC/APE 不保证由 `AVAudioPlayer` 原生解码；不支持的格式会在导入时给出提示。
3. 歌词、专辑封面读取、均衡器暂未提供。
4. IPA 体积以实际构建产物为准，项目不内置大型第三方 SDK。
5. 默认 Bundle ID 为 `com.taozezhong.MuseLocalMusic`。自签或上架前请按自己的 Apple 开发者账号修改。

## 云端构建（不需要 Mac）

1. 在 GitHub 创建一个空仓库并上传本项目全部文件，保持 `.github/workflows/build-ipa.yml` 路径不变。
2. 打开仓库的 **Actions** 页面，选择 **Build unsigned iOS IPA**，点击 **Run workflow**。
3. 构建完成后，在运行记录底部的 Artifacts 下载 `Muse-unsigned-IPA`，解压得到 `Muse-unsigned.ipa`。

工作流使用 GitHub 提供的 macOS runner 和 Xcode 编译未签名 IPA。未签名 IPA 不能直接安装。

## 在 iPhone 上自签安装

可使用 AltStore / SideStore 等工具：

1. 按工具官方说明完成 Apple ID / 配对 / 本地服务所需设置。
2. 将 `Muse-unsigned.ipa` 导入签名工具。
3. 使用自己的 Apple ID 签名并安装。
4. 免费个人签名通常有有效期和 App 数量限制，证书过期后需要重新签名安装。

不要把 Apple ID 密码、双重认证验证码或证书私钥提交到 GitHub 仓库或公开 Issue。

## 相对初版的修复

- 修复 `project.pbxproj` 解析错误、`AVMetadataKey` 与 `String` 比较错误、`#selector(next)` 冲突。
- 删除歌曲时同步播放队列；导入/删除后即时刷新搜索结果。
- 定时更新锁屏播放进度；处理音频中断和音频路由变化。
- 不支持或已损坏的音频在导入时给出明确提示，不再静默写入曲库。
- 补充 shared scheme、正式 App 图标、主题色、空状态引导与播放列表功能。

## 修改 Bundle ID

打开 `MuseLocalMusic.xcodeproj/project.pbxproj`，将 `com.taozezhong.MuseLocalMusic` 替换为你自己的唯一 Bundle ID；也可在 Xcode 的 Signing & Capabilities 中修改。

## 版本规划

- v1.0：本地导入、基本播放、后台/锁屏控制
- v1.1：App 图标、主题色、空状态、播放列表管理
- v1.1.1：修复迷你播放条点击无法进入播放页，补齐上一首/下一首按钮
- v1.2：专辑封面读取、专辑/艺人分组、播放队列持久化
- v1.3：歌词、更多音频格式（按体积要求评估）
