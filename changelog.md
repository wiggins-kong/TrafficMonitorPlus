# 更新日志

本文件按版本号记录 TrafficMonitorPlus 的改动，比 README 更细。推送 `V*` 标签时，GitHub Actions 会自动提取对应版本的章节作为 Release note，因此**章节标题请保持 `## V<版本号>` 的格式**（例如 `## V1.86.2`），版本号要与标签去掉前缀后一致。

---

## V1.86.4

发布日期：2026-10-09

### 修复

- **修复“显示桌面”（任务栏右下角、Win+D）或按 Win+M 后悬浮窗被遮住 / 被最小化的问题。**
  - 新增 100 ms 定时器（`SHOW_DESKTOP_TIMER`）与 `CTrafficMonitorDlg::CheckShowDesktop()`：显示桌面时桌面窗口会被系统抬升到悬浮窗之上，检测到后用 `SetWindowPos` 把悬浮窗移回所有非置顶窗口之上。只识别真正的桌面窗口（`GetShellWindow()` 与宿主 `SHELLDLL_DefView` 的窗口），不会把右键桌面菜单等短暂出现的其他 `WorkerW` 窗口误判为桌面而导致悬浮窗闪烁。
  - `CTrafficMonitorDlg::OnSysCommand()` 忽略 `SC_MINIMIZE`：悬浮窗没有任务栏按钮，被最小化后无法手动还原。
  - 窗口仍被最小化时（`IsIconic`）自动用 `ShowWindow(SW_SHOWNOACTIVATE)` 还原。
  - 仅在悬浮窗未隐藏、当前可见且未勾选“总在最前”时生效，不影响原有置顶设置。

### 文档

- 根目录 `development.md` 重命名为 `AGENTS.md`（约定俗成的 agent 交接文档名），README、lhm_probe 构建脚本及相关引用同步更新。

### 版本

- 版本号由 **1.86.3** 提升到 **1.86.4**。
- README 更新当前版本、下载文件名与特性说明。

### 验证

- Visual Studio 2022 x64 Release 完整版与 Lite 版编译通过（0 错误）。

---

## V1.86.3

发布日期：2026-10-07

### 修复

- **修复切换系统深浅色主题时任务栏长时间假死的问题。**
  - 根因：深浅色切换时通知区图标黑白互换沿用“先删除再添加”的旧逻辑，而增删通知区图标前后会关闭并重开任务栏窗口，导致托盘预留功能的全部占位图标被销毁并重建；此时资源管理器正在重绘重排，几十次同步的 `Shell_NotifyIcon` 调用把程序界面线程与任务栏线程互相卡住，任务栏整体假死、甚至触发 explorer 自动重启。
  - 换图标改用 `Shell_NotifyIcon(NIM_MODIFY)` 就地更新：任务栏窗口与托盘预留全程不再销毁重建；“更换通知区图标”对话框同样生效。
  - 主题切换期间托盘预留静默 3 秒：不扫注册表、不发 `Shell_NotifyIcon`、不发 UIA 查询，静默结束后自动恢复维护并补齐缺失的占位图标。

### 文档

- development.md 更新当前版本、构建组件清单，并补充第 8.4 节“深浅色切换与托盘预留的协作约定”。

### 版本

- 版本号由 **1.86.2** 提升到 **1.86.3**。
- README 更新当前版本、下载文件名与特性说明。

### 验证

- Visual Studio 2022 x64 Release 完整版与 Lite 版编译通过（0 错误）。
- 实机连续切换系统深浅色多次：任务栏不再假死，主题即时切换完成，托盘预留位置正常恢复，通知区图标黑白配色正常跟随。

---

## V1.86.2

发布日期：2026-09-28

### 新增

- **新增皮肤跟随 Windows 深浅色主题自动切换功能。**
  - 在“更换皮肤”对话框中可以分别配置深色模式和浅色模式使用的皮肤。
  - 程序启动时会直接应用当前 Windows 系统模式对应的皮肤，不再等待下一次主题变化。
  - 修改自动切换设置并确认后立即应用当前模式对应的皮肤。
  - 在启用自动切换时，从皮肤列表手动选择另一套皮肤会更新当前模式对应的映射。
  - 当映射缺失、皮肤不存在或主题条件不满足时，安全回退到当前皮肤，不会误切到列表中的第一套皮肤。
  - 修复读取 Windows 主题注册表失败时可能关闭无效注册表句柄的问题。

### 文档

- 重写 `皮肤制作教程.md`，结合当前源码补充 PNG/BMP、`skin.xml`、`skin.ini`、布局、插件映射、高 DPI、遮罩和深浅色双皮肤制作方法。
- 新增根目录 `development.md`，用于新会话快速接手项目。
- 新增根目录 `changelog.md`，作为每次版本的更新记录和 GitHub Release note 来源。
- Release workflow 改为从根目录 `changelog.md` 提取对应版本说明。

### 变更

- 版本号由 **1.86.1** 提升到 **1.86.2**。
- README 更新当前版本、V1.86.2 功能说明和文档入口。

### 验证

- Visual Studio 2022 x64 Release 完整版编译通过，0 个错误。
- 皮肤教程中的文件名、XML/INI 节点和自动切换配置已与当前源码核对。

---

## V1.86.1

发布日期：2026-09-18

### 修复

- **修复"选项 → 常规设置 → 硬件监控 → 勾选硬盘 → 应用"导致程序崩溃的问题。**
  - 崩溃原因：发行包内的 `LibreHardwareMonitorLib.dll` 是 0.9.6，而 0.9.5 起硬盘实现改为基于 CrystalDiskInfo 的实现，因此 0.9.6 新增了对 `DiskInfoToolkit`（以及后者的依赖 `BlackSharp.Core`）的引用，但发行包没有带上这两个 DLL。启用硬盘监控时 `Computer.IsStorageEnabled = true` 会立即构造存储分组并抛出 `FileNotFoundException`（"未能加载文件或程序集 DiskInfoToolkit, Version=1.1.2.0"）；这条路径在上游没有任何异常保护，异常穿过 C++/CLI 桥接层与 MFC 代码后进程直接退出，崩溃日志中可见 `clr.dll` / `VCRUNTIME140_1_CLR0400.dll` 的调用栈。
  - 为什么原版不崩：原版 1.86 使用 `LibreHardwareMonitorLib` 0.9.4，不依赖 `DiskInfoToolkit`，而且旧版存储实现会把磁盘枚举中的失败静默跳过（`StorageGroup.AddHardware` 内是一段空的 `try/catch`）。
  - 修复（源码级，具体文件与函数见开发文档）：
    - 桥接层 `OpenHardwareMonitorApi`：`SetCpuEnable` / `SetGpuEnable` / `SetHddEnable` / `SetMainboardEnable` 改为返回 `bool` 并用 `try/catch` 捕获异常；`MonitorGlobal::UnInit()`（关闭硬件监控）同样加保护。
    - 接口头 `include/OpenHardwareMonitor/OpenHardwareMonitorApi.h` 与 `OpenHardwareMonitorImp.h` 同步修改签名。
    - 应用层新增 `CTrafficMonitorApp::SafeSetHardwareEnable()`（SEH 保护调用桥接层，可捕获访问冲突等 `catch` 无法处理的异常）与 `CTrafficMonitorApp::SafeDestroyMonitor()`（SEH 保护硬件监控对象的析构）。
    - `CTrafficMonitorApp::UpdateOpenHardwareMonitorEnableState()` 改为返回 `bool`：逐项记录结果，启用失败的项自动把设置改回禁用，并弹一次错误提示（提示中附带第三方库返回的原始错误信息）。
    - `CTrafficMonitorDlg::ApplySettings()` 中销毁硬件监控对象改为调用 `SafeDestroyMonitor()`。

### 变更

- 版本号由 1.86 提升到 **1.86.1**（`TrafficMonitor/stdafx.h` 的 `VERSION`、`TrafficMonitor/TrafficMonitor.rc` 的版本资源、`version.info` 与 `version_utf8.info`）。
- 重写本仓库 README：不再沿用原作者的 README，只保留指向上游文档的链接并记录本仓库的修改。
- 新增 [changelog.md](changelog.md)（本文件）与 [development.md](development.md)（开发进度 / 交接文档）。
- 新增 GitHub Actions 工作流 `.github/workflows/release.yml`：推送 `v*` / `V*` 标签时自动创建 Release（Release note 取自本文件对应版本的章节），并编译 x64 完整版与 Lite 版压缩包作为附件。
- 新增诊断工具源码 `wiggins-kong/tools/lhm_probe/`：直接调用硬件监控桥接层，在没有界面的情况下确认各硬件的启用状态、错误信息和读数，便于排查同类问题。

### 验证

本机实测（Windows 11 build 26200，Intel CPU + Intel 显卡，分别使用 LibreHardwareMonitor 0.9.4 与 0.9.6）：

| 场景 | 结果 |
| --- | --- |
| 打补丁前 + 0.9.6（缺依赖），启用硬盘 | 崩溃，复现原问题（崩溃日志调用栈与用户反馈一致） |
| 打补丁后 + 0.9.6（缺依赖），启用硬盘 | 不崩溃；提示一次错误，硬盘监控项自动改回禁用，程序继续运行 |
| 打补丁后 + 0.9.4，启用硬盘 | 正常；读到 SSD 47℃、HDD 40℃ 及各自利用率 |
| 打补丁后 + 0.9.6 + 补齐 DiskInfoToolkit 1.1.2 / BlackSharp.Core 1.0.7 | 正常；读到 SSD 64.7℃、HDD 40℃ 及各自利用率 |
| 关闭硬件监控（析构硬件监控对象，`computer->Close()`） | 正常，无崩溃 |

### 已知问题

- LibreHardwareMonitor 读不到本机 Intel 显卡的温度（0.9.4 与 0.9.6 下均无温度传感器，但能读到显卡利用率），因此"显卡温度"显示 `--`；与上游行为一致，属于库/硬件限制。
- 程序内置的"检查更新"仍指向上游仓库（`TrafficMonitor/UpdateHelper.cpp` 中的 URL），尚未指向本仓库的 Releases。

---

## V1.86（上游基线）

- 基线为 zhongyang219 的 TrafficMonitor 1.86，并合入 mackid1993 的 `feature/reserve-taskbar-space` 分支（在系统托盘中预留空间、任务栏相关修复等）。
- 本仓库自 V1.86.1 起在此基础上迭代。
