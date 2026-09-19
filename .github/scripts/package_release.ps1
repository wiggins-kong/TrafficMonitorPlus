# 打包发布用的压缩包
#
# 用法:
#   pwsh -File .github/scripts/package_release.ps1 -Version 1.86.1
#
# 前置条件: 已编译完整版与 Lite 版（x64 Release），即存在
#   Bin\x64\Release\TrafficMonitor.exe
#   Bin\x64\Release (lite)\TrafficMonitor.exe
#
# 产物（默认输出到仓库根目录的 dist\ 下）:
#   TrafficMonitorPlus_V<版本>_x64.zip         完整版（含硬件监控）
#   TrafficMonitorPlus_V<版本>_x64_Lite.zip    Lite 版（无硬件监控）

param(
    [Parameter(Mandatory = $true)][string]$Version,
    [string]$OutDir = 'dist'
)

$ErrorActionPreference = 'Stop'

$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$outDir = Join-Path $root $OutDir
$fullBin = Join-Path $root 'Bin\x64\Release'
$liteBin = Join-Path $root 'Bin\x64\Release (lite)'

New-Item -ItemType Directory -Force -Path $outDir | Out-Null

# 按 ZIP 规范以正斜杠写入条目名（Compress-Archive / CreateFromDirectory 在 Windows 上会写成反斜杠）
function New-ZipArchive {
    param(
        [Parameter(Mandatory = $true)][string]$SourceDir,
        [Parameter(Mandatory = $true)][string]$ZipPath
    )

    Add-Type -AssemblyName System.IO.Compression | Out-Null
    Add-Type -AssemblyName System.IO.Compression.FileSystem | Out-Null

    if (Test-Path $ZipPath) { Remove-Item -Force $ZipPath }

    $sourceRoot = (Resolve-Path $SourceDir).Path.TrimEnd('\')
    $archive = [System.IO.Compression.ZipFile]::Open($ZipPath, [System.IO.Compression.ZipArchiveMode]::Create)
    try {
        Get-ChildItem -Path $sourceRoot -Recurse -File | ForEach-Object {
            $entryName = $_.FullName.Substring($sourceRoot.Length + 1).Replace('\', '/')
            [void][System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
                $archive, $_.FullName, $entryName, [System.IO.Compression.CompressionLevel]::Optimal)
        }
    }
    finally {
        $archive.Dispose()
    }
}

function New-ReleasePackage {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$BinDir,
        [switch]$WithHardwareMonitor
    )

    $exe = Join-Path $BinDir 'TrafficMonitor.exe'
    if (-not (Test-Path $exe)) {
        throw "找不到 $exe，请先编译（MSBuild.exe TrafficMonitor.sln /p:Configuration=Release /p:Platform=x64）"
    }

    $stage = Join-Path $env:TEMP ("tmp_" + $Name)
    if (Test-Path $stage) { Remove-Item -Recurse -Force $stage }
    New-Item -ItemType Directory -Force -Path $stage | Out-Null

    # 主程序与（完整版的）硬件监控相关 DLL
    Copy-Item $exe $stage
    if ($WithHardwareMonitor) {
        foreach ($dll in @('OpenHardwareMonitorApi.dll', 'LibreHardwareMonitorLib.dll')) {
            $source = Join-Path $BinDir $dll
            if (-not (Test-Path $source)) { throw "找不到 $source" }
            Copy-Item $source $stage
        }
    }

    # 语言文件
    New-Item -ItemType Directory -Force -Path (Join-Path $stage 'language') | Out-Null
    Copy-Item (Join-Path $root 'TrafficMonitor\language\*.ini') (Join-Path $stage 'language')

    # 皮肤
    Copy-Item (Join-Path $root 'TrafficMonitor\skins') (Join-Path $stage 'skins') -Recurse

    # 许可证
    foreach ($file in @('LICENSE', 'LICENSE_CN')) {
        Copy-Item (Join-Path $root $file) $stage
    }

    $zip = Join-Path $outDir "$Name.zip"
    New-ZipArchive -SourceDir $stage -ZipPath $zip
    Remove-Item -Recurse -Force $stage

    Write-Host ("[package] 已生成 {0} ({1:N1} MB)" -f $zip, ((Get-Item $zip).Length / 1MB))
}

New-ReleasePackage -Name "TrafficMonitorPlus_V${Version}_x64" -BinDir $fullBin -WithHardwareMonitor
New-ReleasePackage -Name "TrafficMonitorPlus_V${Version}_x64_Lite" -BinDir $liteBin

Get-ChildItem $outDir -Filter '*.zip' | Format-Table Name, Length
