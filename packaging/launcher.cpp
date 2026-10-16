// Copyright (c) 2026 Cut-it contributors. SPDX-License-Identifier: GPL-3.0-or-later
#include <windows.h>
#include <shlobj.h>
#include <string>
int WINAPI wWinMain(HINSTANCE, HINSTANCE, PWSTR args, int) {
    wchar_t path[32768];
    GetModuleFileNameW(nullptr, path, 32768);
    std::wstring root(path);
    root.resize(root.find_last_of(L"\\/"));
    const auto runtime = root + L"\\runtime";
    wchar_t windows[32768];
    GetWindowsDirectoryW(windows, 32768);
    SetEnvironmentVariableW(L"PATH", (runtime + L";" + windows + L"\\System32;" + windows).c_str());
    SetEnvironmentVariableW(L"QT_PLUGIN_PATH", runtime.c_str());
    SetEnvironmentVariableW(L"QML_IMPORT_PATH", (runtime + L"\\qml").c_str());
    SetEnvironmentVariableW(L"MLT_REPOSITORY", (root + L"\\lib\\mlt").c_str());
    SetEnvironmentVariableW(L"MLT_DATA", (root + L"\\share\\mlt").c_str());
    SetEnvironmentVariableW(L"FREI0R_PATH", (root + L"\\lib\\frei0r-1").c_str());
    SetEnvironmentVariableW(L"LADSPA_PATH", (root + L"\\lib\\ladspa").c_str());
    SetEnvironmentVariableW(L"LV2_PATH", (root + L"\\lib\\lv2").c_str());
    SetEnvironmentVariableW(L"VAMP_PATH", (root + L"\\lib\\vamp").c_str());
    SetEnvironmentVariableW(L"QSG_RHI_BACKEND", L"d3d11");
    PWSTR appdata = nullptr;
    if (FAILED(SHGetKnownFolderPath(FOLDERID_RoamingAppData, 0, nullptr, &appdata))) return 1;
    std::wstring settings = std::wstring(appdata) + L"\\Cut-it";
    CoTaskMemFree(appdata);
    std::wstring command = L"\"" + runtime + L"\\shotcut.exe\" --appdata \"" + settings + L"\" " + args;
    STARTUPINFOW startup{};
    startup.cb = sizeof(startup);
    PROCESS_INFORMATION process{};
    if (!CreateProcessW(nullptr, command.data(), nullptr, nullptr, FALSE, 0, nullptr, root.c_str(), &startup, &process)) {
        MessageBoxW(nullptr, L"Cut-it could not start. Please reinstall Cut-it.", L"Cut-it", MB_OK | MB_ICONERROR);
        return 1;
    }
    CloseHandle(process.hThread);
    CloseHandle(process.hProcess);
    return 0;
}
