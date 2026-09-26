#include "flutter_window.h"

#include <dwmapi.h>
#include <flutter/standard_method_codec.h>
#include <shobjidl.h>

#include <optional>

#include "flutter/generated_plugin_registrant.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());

  window_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(), "sheetopia/window",
          &flutter::StandardMethodCodec::GetInstance());
  window_channel_->SetMethodCallHandler([this](const auto& call, auto result) {
    if (call.method_name() == "isFullScreen") {
      result->Success(flutter::EncodableValue(fullscreen_));
    } else if (call.method_name() == "setFullScreen") {
      const auto* enabled = std::get_if<bool>(call.arguments());
      if (!enabled) {
        result->Error("bad-args", "Expected a bool");
        return;
      }
      SetFullScreen(*enabled);
      result->Success();
    } else {
      result->NotImplemented();
    }
  });
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  window_channel_ = nullptr;
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

namespace {

// Windows 11 only. The calls fail harmlessly on older versions.
constexpr DWORD kDwmWindowCornerPreference = 33;
constexpr DWORD kDwmBorderColor = 34;
constexpr DWORD kDwmCornerDefault = 0;
constexpr DWORD kDwmCornerDoNotRound = 1;
constexpr DWORD kDwmColorNone = 0xFFFFFFFE;
constexpr DWORD kDwmColorDefault = 0xFFFFFFFF;

void MarkFullScreenForTaskbar(HWND hwnd, bool fullscreen) {
  ITaskbarList2* taskbar = nullptr;
  if (FAILED(CoCreateInstance(CLSID_TaskbarList, nullptr,
                              CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&taskbar)))) {
    return;
  }
  if (SUCCEEDED(taskbar->HrInit())) {
    taskbar->MarkFullscreenWindow(hwnd, fullscreen);
  }
  taskbar->Release();
}

void SetCornersAndBorder(HWND hwnd, bool fullscreen) {
  DWORD corner = fullscreen ? kDwmCornerDoNotRound : kDwmCornerDefault;
  DwmSetWindowAttribute(hwnd, kDwmWindowCornerPreference, &corner,
                        sizeof(corner));
  DWORD border = fullscreen ? kDwmColorNone : kDwmColorDefault;
  DwmSetWindowAttribute(hwnd, kDwmBorderColor, &border, sizeof(border));
}

RECT GetMonitorRect(HWND hwnd) {
  MONITORINFO monitor = {sizeof(MONITORINFO)};
  GetMonitorInfo(MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST), &monitor);
  return monitor.rcMonitor;
}

bool CoversMonitor(HWND hwnd) {
  RECT window;
  GetWindowRect(hwnd, &window);
  RECT monitor = GetMonitorRect(hwnd);
  return EqualRect(&window, &monitor);
}

void FitToMonitor(HWND hwnd, UINT flags) {
  RECT rect = GetMonitorRect(hwnd);
  SetWindowPos(hwnd, nullptr, rect.left, rect.top, rect.right - rect.left,
               rect.bottom - rect.top, SWP_NOZORDER | SWP_NOACTIVATE | flags);
}

}  // namespace

void FlutterWindow::SetFullScreen(bool fullscreen) {
  if (fullscreen == fullscreen_) {
    return;
  }
  HWND hwnd = GetHandle();

  // The frame styles stay untouched: removing and restoring WS_CAPTION makes
  // Windows briefly paint the classic frame. Instead, WM_NCCALCSIZE removes
  // the non-client area while in fullscreen.
  if (fullscreen) {
    saved_maximized_ = IsZoomed(hwnd);
    GetWindowRect(hwnd, &saved_rect_);
    GetWindowPlacement(hwnd, &saved_placement_);

    fullscreen_ = true;
    SetCornersAndBorder(hwnd, true);
    // A maximized window is kept inside the work area and doesn't count as
    // fullscreen for the taskbar.
    if (saved_maximized_) {
      SetWindowLong(hwnd, GWL_STYLE,
                    GetWindowLong(hwnd, GWL_STYLE) & ~WS_MAXIMIZE);
    }
    FitToMonitor(hwnd, SWP_FRAMECHANGED);
  } else {
    fullscreen_ = false;
    SetCornersAndBorder(hwnd, false);
    if (saved_maximized_) {
      SetWindowLong(hwnd, GWL_STYLE,
                    GetWindowLong(hwnd, GWL_STYLE) | WS_MAXIMIZE);
    }
    SetWindowPos(hwnd, nullptr, saved_rect_.left, saved_rect_.top,
                 saved_rect_.right - saved_rect_.left,
                 saved_rect_.bottom - saved_rect_.top,
                 SWP_NOZORDER | SWP_NOACTIVATE | SWP_FRAMECHANGED);
    if (saved_maximized_) {
      // Moving the window while it wasn't maximized overwrote the position it
      // restores to when un-maximized. The window is already in place, so
      // this only puts that position back.
      saved_placement_.flags = 0;
      saved_placement_.showCmd = SW_SHOWMAXIMIZED;
      SetWindowPlacement(hwnd, &saved_placement_);
    }
  }
  MarkFullScreenForTaskbar(hwnd, fullscreen);
}

void FlutterWindow::OnMovedOutOfFullScreen() {
  HWND hwnd = GetHandle();
  fullscreen_ = false;
  SetCornersAndBorder(hwnd, false);
  MarkFullScreenForTaskbar(hwnd, false);
  // Brings the frame back at the window's new position.
  SetWindowPos(hwnd, nullptr, 0, 0, 0, 0,
               SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE |
                   SWP_FRAMECHANGED);

  // Changes requested over the channel are already tracked by the framework,
  // so only this one is reported.
  if (window_channel_) {
    window_channel_->InvokeMethod(
        "onFullScreenChanged",
        std::make_unique<flutter::EncodableValue>(false));
  }
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Leaving the proposed rect untouched makes the client area cover the whole
  // window, so no frame is drawn in fullscreen.
  if (message == WM_NCCALCSIZE && wparam && fullscreen_) {
    return 0;
  }

  // A resolution change resizes the monitor under the window, so the window
  // follows it instead of leaving fullscreen.
  if (message == WM_DISPLAYCHANGE && fullscreen_ && !IsIconic(hwnd)) {
    FitToMonitor(hwnd, 0);
  }

  // Snapping or moving to another monitor can resize the window without going
  // through SetFullScreen.
  if (message == WM_WINDOWPOSCHANGED && fullscreen_ && !IsIconic(hwnd) &&
      !CoversMonitor(hwnd)) {
    OnMovedOutOfFullScreen();
  }

  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
    case WM_DPICHANGED:
      // The suggested rect scales the window for the new DPI, which would no
      // longer cover the monitor and drop fullscreen.
      if (fullscreen_ && !IsIconic(hwnd)) {
        FitToMonitor(hwnd, 0);
        return 0;
      }
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
