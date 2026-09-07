#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include "win32_window.h"

#include <memory>

#include "flutter/flutter_view_controller.h"
#include "flutter/method_channel.h"
#include "flutter/standard_method_codec.h"

class FlutterWindow : public Win32Window {
 public:
  explicit FlutterWindow(const flutter::DartProject& project);
  virtual ~FlutterWindow();

 protected:
  bool OnCreate() override;
  void OnDestroy() override;

  LRESULT MessageHandler(
      HWND window,
      UINT const message,
      WPARAM const wparam,
      LPARAM const lparam) noexcept override;

 private:
  // Flutter project configuration.
  flutter::DartProject project_;

  // Flutter controller.
  std::unique_ptr<flutter::FlutterViewController>
      flutter_controller_;

  // Flutter <-> Windows communication channel.
  std::unique_ptr<
      flutter::MethodChannel<flutter::EncodableValue>>
      activity_channel_;
};

#endif  // RUNNER_FLUTTER_WINDOW_H_