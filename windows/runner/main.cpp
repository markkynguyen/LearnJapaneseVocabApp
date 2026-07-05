#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>
#include <string>

#include "flutter_window.h"
#include "utils.h"

namespace {
void RegisterAuthProtocol() {
  wchar_t executable[MAX_PATH];
  if (::GetModuleFileName(nullptr, executable, MAX_PATH) == 0) return;

  HKEY key = nullptr;
  const wchar_t* protocol_key = L"Software\\Classes\\nanaapp";
  if (::RegCreateKeyEx(HKEY_CURRENT_USER, protocol_key, 0, nullptr, 0,
                       KEY_WRITE, nullptr, &key, nullptr) != ERROR_SUCCESS) {
    return;
  }
  const wchar_t* description = L"URL:Nana App authentication";
  ::RegSetValueEx(key, nullptr, 0, REG_SZ,
                  reinterpret_cast<const BYTE*>(description),
                  static_cast<DWORD>((wcslen(description) + 1) * sizeof(wchar_t)));
  const wchar_t empty[] = L"";
  ::RegSetValueEx(key, L"URL Protocol", 0, REG_SZ,
                  reinterpret_cast<const BYTE*>(empty), sizeof(empty));
  ::RegCloseKey(key);

  const wchar_t* command_key =
      L"Software\\Classes\\nanaapp\\shell\\open\\command";
  if (::RegCreateKeyEx(HKEY_CURRENT_USER, command_key, 0, nullptr, 0,
                       KEY_WRITE, nullptr, &key, nullptr) != ERROR_SUCCESS) {
    return;
  }
  const std::wstring command = L"\"" + std::wstring(executable) + L"\" \"%1\"";
  ::RegSetValueEx(key, nullptr, 0, REG_SZ,
                  reinterpret_cast<const BYTE*>(command.c_str()),
                  static_cast<DWORD>((command.size() + 1) * sizeof(wchar_t)));
  ::RegCloseKey(key);
}
}  // namespace

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
  RegisterAuthProtocol();

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"jvocab", origin, size)) {
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
