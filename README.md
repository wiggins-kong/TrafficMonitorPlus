# TrafficMonitorPlus

TrafficMonitorPlus 是 [mackid1993/TrafficMonitor](https://github.com/mackid1993/TrafficMonitor) 的二次修改版本（fork），而 mackid1993 的版本又是 [zhongyang219/TrafficMonitor](https://github.com/zhongyang219/TrafficMonitor) 的修改版。

**原作者的说明文档请直接看下面这些，本仓库不再重复：**

- 原作者（zhongyang219）：[README](https://github.com/zhongyang219/TrafficMonitor/blob/master/README.md)｜[使用说明 Help.md](https://github.com/zhongyang219/TrafficMonitor/blob/master/Help.md)
- 本仓库直接 fork 的上游（mackid1993）：[README](https://github.com/mackid1993/TrafficMonitor/blob/master/README.md)

本 README 只记录 TrafficMonitorPlus 相对上游做了什么；按版本号排列的详细更新日志见 [wiggins-kong/changelog.md](wiggins-kong/changelog.md)，开发与构建说明见 [wiggins-kong/development.md](wiggins-kong/development.md)。

## 当前版本

**V1.86.1** —— 基于上游 1.86 与 mackid1993 的 `feature/reserve-taskbar-space` 分支。

## 本仓库相对上游的修改

### 1. 硬件监控不再因第三方库异常而崩溃（V1.86.1 修复）

硬件监控功能由第三方库 LibreHardwareMonitor 实现。启用某一项硬件监控（CPU / 显卡 / 硬盘 / 主板）时，该库会立即枚举并初始化对应的硬件分组；一旦这一步出错（例如程序目录里缺少该库需要的依赖 DLL），异常会穿过 C++/CLI 桥接层和 MFC 代码，直接终止进程——表现就是"勾选硬盘并应用后程序崩溃"。

本仓库的修改：

- 桥接层 `OpenHardwareMonitorApi`：四个 `SetXxxEnable` 接口改为返回 `bool`，并用 `try/catch` 捕获库抛出的异常；关闭硬件监控（`computer->Close()`）也加了同样的保护。
- 应用层：再用 SEH（`__try/__except`）包一层，捕获 `catch` 无法处理的访问冲突等异常；启用失败时弹出一次错误提示（含第三方库给出的原始错误信息），并把该项设置自动改回禁用，避免反复失败。
- 取数路径（`GetHardwareInfo`）上游本来就有两层保护，保持不变。

完整的根因分析、依赖清单和实测记录见 [wiggins-kong/development.md](wiggins-kong/development.md)。

### 2. 上游特性的保留说明

"在系统托盘中预留空间，防止任务栏图标与窗口重叠"（选项 → 任务栏窗口设置 → Windows 11 相关设置）来自 mackid1993 的 `feature/reserve-taskbar-space` 分支，本仓库沿用该功能，并在其基础上做修复与发版。

## 使用硬件监控时的注意事项

- 程序目录下必须有 `LibreHardwareMonitorLib.dll`。本仓库的发行包提供的是 **0.9.4**，与源码引用的版本一致，开箱即用。
- 如果你自行把该 DLL 换成 **0.9.5 或更高版本**（0.9.5 起硬盘实现改为基于 CrystalDiskInfo），必须同时放入它新增的依赖：`DiskInfoToolkit.dll`（1.1.2）与 `BlackSharp.Core.dll`（1.0.7），否则勾选"硬盘"会失败。使用本仓库 V1.86.1 及以后版本时，即使缺少依赖也只会提示一次错误、不会崩溃。
- 硬件监控需要管理员权限（程序清单已要求）。
- 部分硬件本身就取不到数据时，对应项目显示 `--`。例如某些 Intel 核显无法通过 LibreHardwareMonitor 读取温度（实测 0.9.4 / 0.9.6 都没有温度传感器），此时"显卡温度"会一直是 `--`，属于库/硬件限制，原版行为相同。

## 下载

见 [Releases](https://github.com/wiggins-kong/TrafficMonitorPlus/releases)。推送 `V*` 标签后，GitHub Actions 会自动编译 x64 完整版与 Lite 版并发布。

## 许可证与致谢

- 许可证沿用上游，见 [LICENSE](LICENSE) 与 [LICENSE_CN](LICENSE_CN)。
- 感谢原作者 zhongyang219 与 mackid1993 的工作。
