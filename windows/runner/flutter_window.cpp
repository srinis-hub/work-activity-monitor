#include "flutter_window.h"

#include <optional>
#include <string>
#include <windows.h>

#include "flutter/generated_plugin_registrant.h"
#include "flutter/method_channel.h"
#include "flutter/standard_method_codec.h"

namespace {

// Convert Windows UTF-16 string to UTF-8 string.
// Windows APIs commonly return wchar_t/std::wstring,
// while Flutter's StandardMethodCodec works with UTF-8 strings.
std::string WideToUtf8(const std::wstring& wide_string) {
  if (wide_string.empty()) {
    return {};
  }

  const int size_needed = WideCharToMultiByte(
      CP_UTF8,
      0,
      wide_string.c_str(),
      static_cast<int>(wide_string.size()),
      nullptr,
      0,
      nullptr,
      nullptr);

  if (size_needed <= 0) {
    return {};
  }

  std::string result(size_needed, '\0');

  WideCharToMultiByte(
      CP_UTF8,
      0,
      wide_string.c_str(),
      static_cast<int>(wide_string.size()),
      result.data(),
      size_needed,
      nullptr,
      nullptr);

  return result;
}

}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // Create Flutter controller.
  flutter_controller_ =
      std::make_unique<flutter::FlutterViewController>(
          frame.right - frame.left,
          frame.bottom - frame.top,
          project_);

  // Make sure Flutter controller was created successfully.
  if (!flutter_controller_->engine() ||
      !flutter_controller_->view()) {
    return false;
  }

  // Register Flutter plugins.
  RegisterPlugins(flutter_controller_->engine());

  // ---------------------------------------------------------
  // Flutter <-> Windows MethodChannel
  // ---------------------------------------------------------

  activity_channel_ =
      std::make_unique<
          flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(),
          "work_activity_monitor/activity",
          &flutter::StandardMethodCodec::GetInstance());

  activity_channel_->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<
             flutter::MethodResult<flutter::EncodableValue>> result) {

        // ---------------------------------------------------
        // getActiveWindow
        // ---------------------------------------------------

        if (call.method_name() != "getActiveWindow") {
          result->NotImplemented();
          return;
        }

        // Get the currently active/foreground window.
        HWND foreground_window = GetForegroundWindow();

        if (foreground_window == nullptr) {
          result->Success(flutter::EncodableValue());
          return;
        }

        // ---------------------------------------------------
        // Get Window Title
        // ---------------------------------------------------

        wchar_t window_title[512] = {};

        const int title_length = GetWindowTextW(
            foreground_window,
            window_title,
            sizeof(window_title) / sizeof(wchar_t));

        std::wstring title(
            window_title,
            title_length);

        // ---------------------------------------------------
        // Get Process ID
        // ---------------------------------------------------

        DWORD process_id = 0;

        GetWindowThreadProcessId(
            foreground_window,
            &process_id);

        // ---------------------------------------------------
        // Get Process Name
        // ---------------------------------------------------

        std::wstring process_name = L"Unknown";

        HANDLE process_handle = OpenProcess(
            PROCESS_QUERY_LIMITED_INFORMATION,
            FALSE,
            process_id);

        if (process_handle != nullptr) {
          wchar_t process_path[MAX_PATH] = {};

          DWORD path_size = MAX_PATH;

          if (QueryFullProcessImageNameW(
                  process_handle,
                  0,
                  process_path,
                  &path_size)) {

            std::wstring full_path(
                process_path,
                path_size);

            const size_t last_separator =
                full_path.find_last_of(L"\\/");

            if (last_separator != std::wstring::npos) {
              process_name =
                  full_path.substr(last_separator + 1);
            } else {
              process_name = full_path;
            }
          }

          CloseHandle(process_handle);
        }

        // ---------------------------------------------------
        // Convert Windows Unicode strings to UTF-8.
        // ---------------------------------------------------

        const std::string application =
            WideToUtf8(process_name);

        const std::string window_title_utf8 =
            WideToUtf8(title);

        // ---------------------------------------------------
        // Create response for Flutter.
        // ---------------------------------------------------

        flutter::EncodableMap response;

        response[flutter::EncodableValue("application")] =
            flutter::EncodableValue(application);

        response[flutter::EncodableValue("windowTitle")] =
            flutter::EncodableValue(window_title_utf8);

        response[flutter::EncodableValue("processId")] =
            flutter::EncodableValue(
                static_cast<int64_t>(process_id));

        // Send response back to Flutter.
        result->Success(
            flutter::EncodableValue(response));
      });

  // Attach Flutter view to the Windows window.
  SetChildContent(
      flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Ensure first frame is rendered.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  // Destroy MethodChannel first.
  if (activity_channel_) {
    activity_channel_ = nullptr;
  }

  // Destroy Flutter controller.
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(
    HWND hwnd,
    UINT const message,
    WPARAM const wparam,
    LPARAM const lparam) noexcept {

  // Give Flutter and plugins an opportunity
  // to handle Windows messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(
            hwnd,
            message,
            wparam,
            lparam);

    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      if (flutter_controller_) {
        flutter_controller_->engine()->ReloadSystemFonts();
      }
      break;
  }

  return Win32Window::MessageHandler(
      hwnd,
      message,
      wparam,
      lparam);
}