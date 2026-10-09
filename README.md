# TrafficMonitorPlus

TrafficMonitorPlus 是 [mackid1993/TrafficMonitor](https://github.com/mackid1993/TrafficMonitor) 的二次修改版本（fork），而 mackid1993 的版本又是 [zhongyang219/TrafficMonitor](https://github.com/zhongyang219/TrafficMonitor) 的修改版。

## 当前版本

**V1.86.4** —— 基于上游 1.86 与 mackid1993 的 `feature/reserve-taskbar-space` 分支。

本 README 只做项目总览，不按版本记录细节。完整版本历史和 Release note 见 [changelog.md](changelog.md)。

## 主要特性

### 皮肤跟随 Windows 深浅色主题自动切换

可以为 Windows 深色模式和浅色模式分别指定一套皮肤。程序启动时会应用当前系统模式对应的皮肤，系统主题变化后自动切换，修改映射并确认后也会立即生效。

该功能使用两套完整皮肤，不会仅根据文件夹名称自动推断深浅色。推荐分别制作 `MySkin-Light` 和 `MySkin-Dark`，然后在“更换皮肤 → 自动切换设置”中选择。

### 硬件监控稳定性

启用 CPU、显卡、硬盘或主板监控时，第三方库初始化失败不再导致程序崩溃。失败项会提示一次并自动改回禁用，程序继续运行。

相关修复覆盖 C++/CLI 桥接层的异常捕获、应用层 SEH 保护，以及硬件监控对象析构过程。

### 任务栏窗口空间预留

保留 mackid1993 `feature/reserve-taskbar-space` 分支的系统托盘空间预留功能，用于避免任务栏图标与 TrafficMonitorPlus 窗口重叠。

### 深浅色主题切换稳定

切换 Windows 深浅色主题时，通知区图标改为原地更新，任务栏窗口与托盘空间预留不再被反复销毁重建，任务栏不会假死；通知区图标黑白配色依旧自动跟随主题。

### 显示桌面时悬浮窗保持可见

点击任务栏右下角或按 Win+D / Win+M 显示桌面时，悬浮窗不再被抬升的桌面窗口遮住，也不会被最小化后无法还原；即使窗口被系统命令最小化，程序也会自动将其还原，悬浮窗始终可见。

## 文档

- 使用说明：[上游 Help.md](https://github.com/zhongyang219/TrafficMonitor/blob/master/Help.md)
- 版本更新记录与 Release note：[changelog.md](changelog.md)
- 构建、架构、发布和交接说明：[AGENTS.md](AGENTS.md)
- 皮肤制作教程：[皮肤制作教程.md](皮肤制作教程.md)

## 下载

见 [Releases](https://github.com/wiggins-kong/TrafficMonitorPlus/releases)。当前发行版提供：

- `TrafficMonitorPlus_V1.86.4_x64.zip`：完整版，包含硬件监控；
- `TrafficMonitorPlus_V1.86.4_x64_Lite.zip`：Lite 版，不含硬件监控相关 DLL。

## 使用硬件监控时的注意事项

- 程序目录下必须有 `LibreHardwareMonitorLib.dll`。本仓库的发行包提供的是 **0.9.4**，与源码引用的版本一致，开箱即用。
- 如果你自行把该 DLL 换成 **0.9.5 或更高版本**（0.9.5 起硬盘实现基于 CrystalDiskInfo），必须同时放入新增依赖：`DiskInfoToolkit.dll`（1.1.2）与 `BlackSharp.Core.dll`（1.0.7），否则硬盘监控会启用失败。
- 硬件监控需要管理员权限（程序清单已要求）。
- 部分硬件取不到数据时，对应项目显示 `--`。例如某些 Intel 核显无法通过 LibreHardwareMonitor 读取温度，属于库或硬件限制。

## 许可证与致谢

- 许可证沿用上游，见 [LICENSE](LICENSE) 与 [LICENSE_CN](LICENSE_CN)。
- 感谢原作者 zhongyang219 与 mackid1993 的工作。
