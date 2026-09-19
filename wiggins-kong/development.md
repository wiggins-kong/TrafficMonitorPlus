# TrafficMonitorPlus 开发文档

> 目的：让任何一台电脑上的开发者 / agent 能无缝接手本项目。
> 最后更新：2026-09-18（对应版本 V1.86.1，分支 `master`）

---

## 1. 项目定位与仓库

| 角色 | 仓库 | 说明 |
| --- | --- | --- |
| 本仓库 | https://github.com/wiggins-kong/TrafficMonitorPlus | 发布线，`master` 即发布分支 |
| 直接上游（fork 自） | https://github.com/mackid1993/TrafficMonitor | `feature/reserve-taskbar-space` 分支提供"在系统托盘中预留空间"功能 |
| 原作者 | https://github.com/zhongyang219/TrafficMonitor | 原始项目，使用说明见其 README / Help.md |

### 远程与分支约定

- `origin` = `mackid1993/TrafficMonitor`（只用于对比、合并上游，**不要**往这里推）
- `plus`（本地建议新增）= `wiggins-kong/TrafficMonitorPlus`（本仓库，推送目标）

```
git remote add plus https://github.com/wiggins-kong/TrafficMonitorPlus
```

- `master` = 上游 master + mackid1993 的 `feature/reserve-taskbar-space` + 本仓库的修改（**发布线**）。
  当前 master 的历史脉络：`... → 430f14d(上游 1.86) → 69974ac..617dcd7(mackid1993 的预留空间功能) → 本仓库 V1.86.1 的提交`。
- 工作分支命名参考：`fix/hardware-monitor-crash-taskbar`（V1.86.1 的修复就是在这条分支上做的）。
- 发布：在 `master` 上打 `V<版本>` 标签并推送，工作流会自动编译并发布 Release（见第 7 节）。

---

## 2. 版本号与发版修改清单

发版前需要同步修改的 **4 个位置**：

| 文件 | 需要修改的内容 | 作用 |
| --- | --- | --- |
| `TrafficMonitor/stdafx.h` | `#define VERSION L"1.86.1"` | 程序显示的版本（关于对话框、崩溃日志的 `Version:`、`config.ini` 的 `[app] version`） |
| `TrafficMonitor/TrafficMonitor.rc` | `FILEVERSION 1,86,1,0`、`PRODUCTVERSION 1,86,1,0`、`VALUE "FileVersion", "1.86.1.0"`、`VALUE "ProductVersion", "1.86.1.0"` | 可执行文件属性里的版本 |
| `version.info` | `<version>1.86.1</version>` | 更新信息文件元数据（Gitee 用） |
| `version_utf8.info` | `<version>1.86.1</version>` | 更新信息文件元数据（GitHub 用） |

注意事项：

- `TrafficMonitor.rc` 是 **UTF-16LE** 编码，请用支持 UTF-16 的编辑器修改；命令行里 grep 要加 `-a`。
- `FILEVERSION` 的编码方式：上游把 1.86 写成 `1,8,6,0`（把 86 视作 8.6）。本仓库从 1.86.1 起改成与显示版本一致的 `1,86,1,0`，**不要改回 `1,8,6,1`**。
- 程序运行时**不读**本地的 `version.info` / `version_utf8.info`；它们只是随包提供的元数据。程序内置的更新检查请求的是上游仓库的 URL（见 `TrafficMonitor/UpdateHelper.cpp`，仍然是 `zhongyang219`），如果要改成 TrafficMonitorPlus 自己的更新通道，需要同时改这里和上面的下载链接（见第 8 节待办）。

---

## 3. 构建

### 3.1 需要的环境

Visual Studio 2022（本机为 Community 17.14，MSVC 工具集 14.44 / v143）+ Windows SDK（10.0.26100 已验证），并且必须安装以下组件：

| 组件 ID | 内容 | 为什么需要 |
| --- | --- | --- |
| `Microsoft.VisualStudio.Component.VC.Tools.x86.x64` | MSVC v143 | 编译器 |
| `Microsoft.VisualStudio.Component.VC.ATLMFC` | C++ MFC/ATL | 主程序是 MFC 程序 |
| `Microsoft.VisualStudio.Component.VC.CLI.Support` | C++/CLI 支持 | 桥接项目 `OpenHardwareMonitorApi` 是 `/clr` 项目 |
| `Microsoft.Net.Component.4.7.2.TargetingPack` | .NET Framework 4.7.2 目标包 | 桥接项目 `TargetFrameworkVersion=v4.7.2` |

检查是否已安装（返回路径表示已装，为空表示缺失）：

```
"%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -products * -requires Microsoft.VisualStudio.Component.VC.ATLMFC -property installationPath
```

补装（**需要管理员权限**，`--passive` 会显示安装界面；`--quiet` 全静默）：

```
"%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\setup.exe" modify ^
  --installPath "C:\Program Files\Microsoft Visual Studio\2022\Community" ^
  --add Microsoft.VisualStudio.Component.VC.ATLMFC ^
  --add Microsoft.VisualStudio.Component.VC.CLI.Support ^
  --add Microsoft.Net.Component.4.7.2.TargetingPack ^
  --passive --norestart
```

> 注意：`setup.exe` **没有** `--wait` 参数（写了会报 "Option 'wait' is unknown" 并直接退出，什么都不装）；需要等待时用 `Start-Process ... -Wait` 包一层。

### 3.2 编译命令

```
MSBuild.exe TrafficMonitor.sln      /p:Configuration=Release            /p:Platform=x64 /m
MSBuild.exe TrafficMonitor_Lite.sln /p:"Configuration=Release (lite)"   /p:Platform=x64 /m
```

- 完整版输出：`Bin\x64\Release\`（`TrafficMonitor.exe`、`OpenHardwareMonitorApi.dll`、`LibreHardwareMonitorLib.dll` 会自动复制到输出目录）
- Lite 版输出：`Bin\x64\Release (lite)\`（定义了 `WITHOUT_TEMPERATURE`，无硬件监控、无额外 DLL）
- ⚠️ **不要**用 `TrafficMonitor_Lite.sln` 编译完整版；完整版必须用 `TrafficMonitor.sln`。
- MSBuild 路径示例：`C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe`
- 预生成事件会执行 `TrafficMonitor/print_compile_time.bat`，把编译时间写进程序（崩溃日志里的 `Last compiled date`）。

### 3.3 发布包还需要复制这些运行时资源

编译产物之外，发行压缩包还需要（打包脚本 `.github/scripts/package_release.ps1` 已自动处理）：

- `TrafficMonitor/language/*.ini`（18 个语言文件，缺了界面文字会显示成 `TXT_*` 占位符）
- `TrafficMonitor/skins/**`（皮肤，缺了悬浮窗没有皮肤）
- `LICENSE`、`LICENSE_CN`
- **完整版**额外需要 `LibreHardwareMonitorLib.dll`（见第 4 节），**Lite 版不要**带任何硬件监控相关 DLL

---

## 4. 硬件监控子系统

### 4.1 架构与调用链

```
TrafficMonitor.exe (MFC, 原生)
   └─ OpenHardwareMonitorApi.dll (C++/CLI 桥接层, 项目 OpenHardwareMonitorApi/)
        └─ LibreHardwareMonitorLib.dll (托管库, .NET Framework 4.7.2)
             └─ LibreHardwareMonitor 的内核驱动（内嵌在 DLL 中，Ring0.Open() 时加载，需要管理员权限）
```

- 接口定义：`include/OpenHardwareMonitor/OpenHardwareMonitorApi.h`（`IOpenHardwareMonitor`）
- 桥接实现：`OpenHardwareMonitorApi/OpenHardwareMonitorImp.cpp` / `.h`
- 应用侧使用：`TrafficMonitor/TrafficMonitor.cpp`（初始化与启用状态）、`TrafficMonitor/TrafficMonitorDlg.cpp`（取数、设置应用）
- 相关设置：`TrafficMonitor/CommonData.h` 的 `HardwareItem`（`HI_CPU=1`、`HI_GPU=2`、`HI_HDD=4`、`HI_MBD=8`）与 `hardware_monitor_item` 位掩码；`cpu_core_name`、`hard_disk_name` 保存用户选中的传感器/硬盘名

关键流程：

| 流程 | 入口 | 说明 |
| --- | --- | --- |
| 启动初始化 | `CTrafficMonitorApp::InitOpenHardwareLibInThread()` → `InitOpenHardwareMonitorLibThreadFunc()` | 后台线程里 `CreateInstance()`（内部 `computer->Open()`），随后调用 `UpdateOpenHardwareMonitorEnableState()` |
| 启用状态变更 | 选项对话框应用 → `CTrafficMonitorDlg::ApplySettings()` → `CTrafficMonitorApp::UpdateOpenHardwareMonitorEnableState()` | **这里就是 V1.86.1 修复的崩溃点**：设置 `IsXxxEnabled = true` 会让库立即枚举并初始化对应硬件分组 |
| 周期取数 | `CTrafficMonitorDlg::OnTimer` → `DoMonitorAcquisition()` → `m_pMonitor->GetHardwareInfo()` | 上游已用 `__try/__except` + 托管 `catch` 双保险 |
| 关闭硬件监控 | 四项全部取消勾选 → `ApplySettings()` → `SafeDestroyMonitor()` | 析构时库内部会 `computer->Close()` |

### 4.2 异常保护现状（V1.86.1 之后）

| 调用 | 保护方式 | 位置 |
| --- | --- | --- |
| `SetCpuEnable` / `SetGpuEnable` / `SetHddEnable` / `SetMainboardEnable` | 托管 `try/catch`，失败返回 `false` 并把错误信息写入 `error_message`（可用 `OpenHardwareMonitorApi::GetErrorMessage()` 取到） | `OpenHardwareMonitorImp.cpp` |
| `MonitorGlobal::UnInit()`（关闭硬件） | 托管 `try/catch` | `OpenHardwareMonitorImp.cpp` |
| 上述四个 setter 的调用 | 原生 SEH `__try/__except(EXCEPTION_EXECUTE_HANDLER)`（捕获访问冲突等 `catch` 抓不到的异常） | `CTrafficMonitorApp::SafeSetHardwareEnable()` |
| 硬件监控对象析构 | 同上（单独的小函数 `ResetMonitorWithSEH`，因为 `__try` 不能出现在需要对象析构的函数里，否则报 C2712） | `TrafficMonitor.cpp` |
| `GetHardwareInfo` | 上游已有：lambda 内 `__try/__except` + 库内 `catch` | `TrafficMonitorDlg.cpp` |

失败时的行为：`UpdateOpenHardwareMonitorEnableState()` 返回 `false`，把失败的项在 `m_general_data` 中改回禁用（避免每秒取数都失败），并弹出一次 `IDS_HARDWARE_INFO_ACQUIRE_FAILED_ERROR` 提示（附第三方库的原始错误信息）。

### 4.3 LibreHardwareMonitor 版本与依赖（重要）

- 仓库签入的 DLL：`OpenHardwareMonitorApi/LibreHardwareMonitorLib.dll` = **0.9.4**（712,192 字节），与源码引用的版本一致，**不需要**任何额外依赖。
- mackid1993 的发行包实际带的是 **0.9.6**（1,203,200 字节）+ `System.Memory.dll` / `System.Numerics.Vectors.dll` / `System.Runtime.CompilerServices.Unsafe.dll`，但**漏掉了** 0.9.6 必需的：

| 依赖 | 版本 | 提供者 | 用途 |
| --- | --- | --- | --- |
| `DiskInfoToolkit.dll` | 1.1.2 | NuGet 包 `DiskInfoToolkit`（`lib/net472`） | 0.9.5 起硬盘/SSD 的实现基础 |
| `BlackSharp.Core.dll` | 1.0.7 | NuGet 包 `BlackSharp.Core`（`lib/net472`） | DiskInfoToolkit 的依赖 |
| `System.Memory.dll` | 4.6.3 | 已有（版本正好是 4.6.3，不需更换） | span 相关 |

  缺少 `DiskInfoToolkit.dll`（或它的依赖 `BlackSharp.Core.dll`）时的报错原文：
  `未能加载文件或程序集"DiskInfoToolkit, Version=1.1.2.0, Culture=neutral, PublicKeyToken=null"或它的某一个依赖项。系统找不到指定的文件。`

- 0.9.4 与 0.9.6 读取到的硬盘温度可能不同（本机实测 J.ZAO SSD：0.9.4 报 47℃，0.9.6 报 64.7℃），排查温度异常时注意这一点。

---

## 5. V1.86.1 修复的崩溃：根因与复现

### 5.1 根因

勾选硬盘 → `Computer.IsStorageEnabled = true` → 库立即构造 `StorageGroup` → `StorageDevice` 引用 `DiskInfoToolkit` → 缺 DLL 抛 `FileNotFoundException` → 该路径无异常保护 → 异常穿过 C++/CLI 与 MFC 代码 → 进程退出（崩溃日志中 `RaiseException` → `VCRUNTIME140_1_CLR0400.dll` → `clr.dll` 的调用栈就是这么来的）。

原版 1.86 不崩的两个原因：① 用 0.9.4，没有 `DiskInfoToolkit` 依赖；② 0.9.4 的 `StorageGroup.AddHardware` 把整段磁盘枚举包在空的 `try/catch` 里，失败会被静默跳过，而 0.9.6 重写后没有这层保护。

### 5.2 如何在无界面环境下复现 / 验证

1. 复制一份程序目录（**不要放在 Temp 下**，见 5.3 第 3 条）。
2. 编辑该目录的 `config.ini`：把 `[general]` 段的 `hardware_monitor_item` 设为 `15`（= CPU+显卡+硬盘+主板全部启用），并加上 `no_multistart_warning = true`。
3. 用管理员权限启动 `TrafficMonitor.exe`（程序清单要求管理员）。启动时的后台初始化线程就会走"启用硬盘"这条路径：
   - 未修复的版本：约 1 秒后崩溃，目录下出现 `error.log`，`%TEMP%` 下多一个 `.dmp`；
   - 已修复的版本：不崩溃，弹出一次错误提示，硬盘项自动关闭（`config.ini` 里 `hardware_monitor_item` 会在退出保存时变回 11）。

### 5.3 本机调试时容易踩的坑

1. **多实例互斥**：程序用一个命名互斥体（`TrafficMonitor-e8Ahk24HP6JC8hDy`，见 `TrafficMonitor.cpp`）检查多实例，已有实例在运行时新实例会直接退出（`InitInstance` 里 `return FALSE`）。做端到端测试前必须先退出正在运行的程序，否则会误以为"测试实例一闪而过"。
2. **管理员权限 / UAC**：清单要求 `requireAdministrator`，非管理员启动会弹 UAC。若某台机器把 UAC 设为对管理员静默放行，可直接用 `Start-Process -Verb RunAs` 启动。
3. **程序目录在 Temp 下会被强制改为把配置写到 `%APPDATA%\TrafficMonitor\`**（`TrafficMonitor.cpp` 的 `LoadGlobalConfig()`：路径里含 Temp 目录时 `portable_mode` 被强制置否），于是你改的 `config.ini` 根本不生效、硬件监控也不启动。**测试目录请放在 Temp 之外。**
4. 便携模式判定：程序目录有 `global_cfg.ini`（其中 `portable_mode = true`）时读同目录的 `config.ini`，否则读 `%APPDATA%\TrafficMonitor\config.ini`。

---

## 6. 诊断工具：lhm_probe

源码在 `wiggins-kong/tools/lhm_probe/`，是一个直接调用桥接层 `OpenHardwareMonitorApi.dll` 的控制台程序，用来在没有界面的情况下确认"某项硬件能否启用、失败原因是什么、能读到哪些传感器"。排查硬件监控问题（尤其是别的电脑上的）时非常有用。

用法：

```
:: 1) 编译（需要先编译过完整版，因为要链接 OpenHardwareMonitorApi.lib）
cd wiggins-kong\tools\lhm_probe
build.bat

:: 2) 把 exe 复制到被测程序目录（与 OpenHardwareMonitorApi.dll、LibreHardwareMonitorLib.dll 同级）
copy tm_lhm_probe.exe D:\SomeWhere\TrafficMonitor\

:: 3) 用管理员身份运行，结果写入当前目录的 tm_lhm_probe_out.txt
```

输出内容示例（节选）：

```
CreateInstance OK
SetCpuEnable(true)       -> true
SetGpuEnable(true)       -> true
SetMainboardEnable(true) -> true
SetHddEnable(true)       -> false
    [SetHddEnable] error_message: 未能加载文件或程序集"DiskInfoToolkit, Version=1.1.2.0"...
    GpuTemperature             = -1.0
    AllCpuTemperature (15 items)
        CPU Core #1 = 43.0
        Core Average = 44.0
        CPU Core #1 Distance to TjMax = 57.0
```

它内部把 `SetHddEnable` / `GetHardwareInfo` 调用都用 SEH 包住（模拟打补丁后 TrafficMonitor 的行为），所以即使库内部发生访问冲突，它也能继续跑完并记录结果。**注意**：如果要在未打补丁的旧版桥接 DLL 上测试，SEH 依然有效，但崩溃点可能出现在别处。

---

## 7. 发布流程

### 7.1 打标签自动发版

```
git switch master && git pull
# 1) 更新第 2 节的 4 个版本号位置
# 2) 在 wiggins-kong/changelog.md 顶部新增一节：## V1.86.2
git commit -am "chore: 版本号更新到 V1.86.2"
git push plus master
git tag V1.86.2 && git push plus V1.86.2
```

工作流 `.github/workflows/release.yml` 会在标签推送后：

1. **create-release**（ubuntu）：解析标签得到版本号 → 用 `.github/scripts/extract_changelog.py` 从 `wiggins-kong/changelog.md` 提取该版本章节 → `gh release create` 创建 Release（标题 `TrafficMonitorPlus V1.86.2`）。
2. **build-and-upload**（windows-latest）：检查并按需补装 MFC/ATL、C++/CLI、.NET 4.7.2 目标包 → 编译完整版与 Lite 版（x64）→ 用 `.github/scripts/package_release.ps1` 打包 → `gh release upload` 上传两个 zip。

说明与注意事项：

- Release 与构建是**两个 job**，创建 Release 在前、构建上传在后；构建 job 设置了 `continue-on-error: true`，所以构建万一失败，Release 仍然存在（只是没有附件），不会出现"什么都没发布"的情况。
- 也支持手动触发（Actions → Release → Run workflow，填写标签名）。
- 标签前缀 `v` / `V` 都可以；`changelog.md` 中的章节标题必须能被版本号匹配到（`## V1.86.2`）。
- 附件命名：`TrafficMonitorPlus_V<版本>_x64.zip`（完整版）、`TrafficMonitorPlus_V<版本>_x64_Lite.zip`（Lite 版）。
- 目前只构建 x64；如需 x86 / ARM64EC，参照上游 `.github/workflows/main.yml` 增加 msbuild 调用与打包即可（Lite 解决方案已支持 `--p:Platform=x86` / `ARM64EC`）。

### 7.2 发行包内容

```
TrafficMonitor.exe
OpenHardwareMonitorApi.dll
LibreHardwareMonitorLib.dll        (仅完整版；Lite 版没有)
language/*.ini
skins/**
LICENSE
LICENSE_CN
```

---

## 8. 待办 / 已知问题

- [ ] **显卡温度**：本机（Intel 显卡）在 0.9.4 / 0.9.6 下都取不到 GPU 温度传感器（能取到利用率），"显卡温度"恒为 `--`。如需进一步确认，可在目标机器上跑官方 LibreHardwareMonitor GUI 看是否存在温度节点；这属于库/硬件限制，不是 TrafficMonitor 的 bug。
- [ ] **更新通道**：`TrafficMonitor/UpdateHelper.cpp` 仍指向 `zhongyang219` 的仓库；若要改成 TrafficMonitorPlus 自己的更新通道，需要同时更新 `version.info` / `version_utf8.info` 中的链接（目前只改了 `<version>`）。
- [ ] **发行包默认的 LibreHardwareMonitor 版本**：当前仓库签入 0.9.4（无需额外依赖）。若想随包提供 0.9.6（能读更细的硬盘/SSD 信息），必须同时打包 `DiskInfoToolkit.dll` + `BlackSharp.Core.dll`（见 4.3），并在 `package_release.ps1` 里补上这些文件。
- [ ] 构建产物默认只有 x64 完整版 + x64 Lite 版；x86 / ARM64EC 未接入自动发布。
- [ ] `TrafficMonitor.rc` 的 `FILEVERSION` 已改为 `1,86,1,0`（与显示版本一致），后续版本按 `1,86,N,0` 递增。
- [ ] 仓库根目录下 `Screenshots/`、`UpdateLog/`、`Help*.md` 仍是上游内容，未做本地化调整（需要时再更新）。
