#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

void RegisterTagarProtocol() {
  wchar_t full_path[MAX_PATH];
  if (!GetModuleFileNameW(nullptr, full_path, MAX_PATH)) {
    return;
  }

  HKEY key;
  LSTATUS result = RegCreateKeyExW(
      HKEY_CURRENT_USER,
      L"Software\\Classes\\tagar",
      0, nullptr, REG_OPTION_NON_VOLATILE,
      KEY_SET_VALUE, nullptr, &key, nullptr);
  if (result != ERROR_SUCCESS) return;

  DWORD nullLen = static_cast<DWORD>(sizeof(wchar_t));
  RegSetValueExW(key, L"URL Protocol", 0, REG_SZ,
                 reinterpret_cast<const BYTE*>(L""), nullLen);

  std::wstring command = L"\"" + std::wstring(full_path) + L"\" \"%1\"";
  HKEY shellKey;
  if (RegCreateKeyExW(key, L"shell\\open\\command", 0, nullptr,
                      REG_OPTION_NON_VOLATILE, KEY_SET_VALUE,
                      nullptr, &shellKey, nullptr) == ERROR_SUCCESS) {
    DWORD cmdLen = static_cast<DWORD>((command.size() + 1) * sizeof(wchar_t));
    RegSetValueExW(shellKey, nullptr, 0, REG_SZ,
                   reinterpret_cast<const BYTE*>(command.c_str()), cmdLen);
    RegCloseKey(shellKey);
  }
  RegCloseKey(key);
}

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  RegisterTagarProtocol();

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"tagar", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
