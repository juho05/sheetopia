#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <flutter/method_channel.h>

#include <memory>

#include "win32_window.h"

// A window that does nothing but host a Flutter view.
class FlutterWindow : public Win32Window {
 public:
  // Creates a new FlutterWindow hosting a Flutter view running |project|.
  explicit FlutterWindow(const flutter::DartProject& project);
  virtual ~FlutterWindow();

 protected:
  // Win32Window:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  // The project to run.
  flutter::DartProject project_;

  // The Flutter instance hosted by this window.
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;

  // Channel for window state the framework can't control on its own.
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
      window_channel_;

  bool fullscreen_ = false;
  bool saved_maximized_ = false;
  RECT saved_rect_ = {};
  WINDOWPLACEMENT saved_placement_ = {sizeof(WINDOWPLACEMENT)};

  // Enters or leaves borderless fullscreen with a single resize, so Flutter
  // doesn't lay out intermediate window sizes.
  void SetFullScreen(bool fullscreen);

  // Drops the fullscreen state after something else moved or resized the
  // window, and reports it to the framework.
  void OnMovedOutOfFullScreen();
};

#endif  // RUNNER_FLUTTER_WINDOW_H_
