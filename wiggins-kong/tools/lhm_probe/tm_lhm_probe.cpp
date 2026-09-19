// tm_lhm_probe.cpp —— 直接调用 OpenHardwareMonitorApi.dll，用于验证硬件监控接口的行为
// 用法：把本程序编译出的 exe 放到 TrafficMonitor 所在目录（与 OpenHardwareMonitorApi.dll、
// LibreHardwareMonitorLib.dll 同级），以管理员身份运行，结果写入当前目录的 tm_lhm_probe_out.txt
// 说明：为了模拟 TrafficMonitor 打完补丁后的行为，对 SetHddEnable/GetHardwareInfo 的调用加了 SEH 保护
#include <cstdio>
#include <string>
#include <map>
#include <memory>
#include <windows.h>
#include "OpenHardwareMonitor/OpenHardwareMonitorApi.h"

static FILE* g_out = nullptr;

static void Log(const wchar_t* fmt, ...)
{
    va_list args;
    va_start(args, fmt);
    vfwprintf(g_out, fmt, args);
    va_end(args);
    fflush(g_out);
}

static void PrintErr(const wchar_t* tag)
{
    std::wstring err = OpenHardwareMonitorApi::GetErrorMessage();
    if (!err.empty())
        Log(L"    [%s] error_message: %s\n", tag, err.c_str());
}

static void PrintMap(const wchar_t* title, const std::map<std::wstring, float>& m)
{
    Log(L"--- %s (%zu items) ---\n", title, m.size());
    for (const auto& kv : m)
        Log(L"    %s = %.1f\n", kv.first.c_str(), kv.second);
}

//__try 不能出现在包含需要析构的对象的函数里，因此把带 SEH 保护的调用单独放在这两个函数中
static bool SetHddEnableWithSEH(OpenHardwareMonitorApi::IOpenHardwareMonitor* p, bool enable, bool& seh_fired)
{
    __try
    {
        return p->SetHddEnable(enable);
    }
    __except (EXCEPTION_EXECUTE_HANDLER)
    {
        seh_fired = true;
        return false;
    }
}

static bool GetHardwareInfoWithSEH(OpenHardwareMonitorApi::IOpenHardwareMonitor* p)
{
    __try
    {
        p->GetHardwareInfo();
        return true;
    }
    __except (EXCEPTION_EXECUTE_HANDLER)
    {
        return false;
    }
}

int wmain()
{
    _wfopen_s(&g_out, L"tm_lhm_probe_out.txt", L"w, ccs=UTF-8");
    if (g_out == nullptr)
        return 1;

    Log(L"=== TrafficMonitor hardware monitor probe ===\n");

    auto p = OpenHardwareMonitorApi::CreateInstance();
    if (p == nullptr)
    {
        Log(L"CreateInstance FAILED: %s\n", OpenHardwareMonitorApi::GetErrorMessage().c_str());
        fclose(g_out);
        return 1;
    }
    Log(L"CreateInstance OK\n");
    PrintErr(L"CreateInstance");

    Log(L"before SetCpuEnable(true)\n");
    Log(L"SetCpuEnable(true)       -> %s\n", p->SetCpuEnable(true) ? L"true" : L"false");
    PrintErr(L"SetCpuEnable");
    Log(L"SetGpuEnable(true)       -> %s\n", p->SetGpuEnable(true) ? L"true" : L"false");
    PrintErr(L"SetGpuEnable");
    Log(L"SetMainboardEnable(true) -> %s\n", p->SetMainboardEnable(true) ? L"true" : L"false");
    PrintErr(L"SetMainboardEnable");

    //模拟 TrafficMonitor 打补丁后的调用方式：用 SEH 包住，避免库内部的异常/访问冲突导致崩溃
    Log(L"calling SetHddEnable(true) under SEH guard...\n");
    bool seh_fired = false;
    bool hdd_result = SetHddEnableWithSEH(p.get(), true, seh_fired);
    Log(L"SetHddEnable(true) -> %s (seh_guard_caught=%s)\n", hdd_result ? L"true" : L"false", seh_fired ? L"YES" : L"no");
    PrintErr(L"SetHddEnable");

    Log(L"--- polling GetHardwareInfo() twice (SEH guarded) ---\n");
    for (int i = 0; i < 2; ++i)
    {
        if (!GetHardwareInfoWithSEH(p.get()))
            Log(L"    GetHardwareInfo: seh_guard_caught=YES\n");
        PrintErr(L"GetHardwareInfo");
        Sleep(1200);
    }

    Log(L"--- summary values ---\n");
    Log(L"    CpuTemperature (TM average) = %.1f\n", p->CpuTemperature());
    Log(L"    GpuTemperature             = %.1f\n", p->GpuTemperature());
    Log(L"    HddTemperature             = %.1f\n", p->HDDTemperature());
    Log(L"    MainboardTemperature       = %.1f\n", p->MainboardTemperature());
    Log(L"    GpuUsage                   = %.1f\n", p->GpuUsage());
    Log(L"    CpuUsage                   = %.1f\n", p->CpuUsage());
    Log(L"    CpuFreq                    = %.1f\n", p->CpuFreq());

    PrintMap(L"AllCpuTemperature", p->AllCpuTemperature());
    PrintMap(L"AllHDDTemperature", p->AllHDDTemperature());
    PrintMap(L"AllHDDUsage", p->AllHDDUsage());

    //模拟 TrafficMonitor 关闭硬件监控时析构硬件监控对象的过程
    Log(L"destroying monitor instance (computer->Close)...\n");
    p.reset();
    Log(L"monitor destroyed OK\n");

    Log(L"=== done ===\n");
    fclose(g_out);
    return 0;
}
