# Geometry and state of the Sheetopia windows (run in the desktop session
# through desktop.ps1, SSH sessions can't see them).
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.Text;
public static class E2eWindows {
  public delegate bool EnumProc(IntPtr hwnd, IntPtr param);
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
  [DllImport("user32")] public static extern bool EnumWindows(EnumProc proc, IntPtr param);
  [DllImport("user32")] public static extern bool IsWindowVisible(IntPtr hwnd);
  [DllImport("user32")] public static extern uint GetWindowThreadProcessId(IntPtr hwnd, out uint pid);
  [DllImport("user32")] public static extern bool GetWindowRect(IntPtr hwnd, out RECT rect);
  [DllImport("user32")] public static extern bool GetClientRect(IntPtr hwnd, out RECT rect);
  [DllImport("user32")] public static extern bool IsZoomed(IntPtr hwnd);
  [DllImport("user32")] public static extern bool IsIconic(IntPtr hwnd);
  [DllImport("user32")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32", CharSet = CharSet.Unicode)] public static extern int GetWindowText(IntPtr hwnd, StringBuilder text, int max);
  [DllImport("user32")] public static extern int GetSystemMetrics(int index);
}
'@
$pids = @(Get-Process sheetopia -ErrorAction SilentlyContinue | ForEach-Object Id)
$screenW = [E2eWindows]::GetSystemMetrics(0)
$screenH = [E2eWindows]::GetSystemMetrics(1)
$foreground = [E2eWindows]::GetForegroundWindow()
$lines = New-Object System.Collections.Generic.List[string]
$callback = [E2eWindows+EnumProc] {
  param($hwnd, $param)
  $windowPid = [uint32]0
  [void][E2eWindows]::GetWindowThreadProcessId($hwnd, [ref]$windowPid)
  if ($pids -contains $windowPid -and [E2eWindows]::IsWindowVisible($hwnd)) {
    $r = New-Object E2eWindows+RECT
    [void][E2eWindows]::GetWindowRect($hwnd, [ref]$r)
    $w = $r.Right - $r.Left
    $h = $r.Bottom - $r.Top
    if ($w -ge 50) {
      $title = New-Object System.Text.StringBuilder 256
      [void][E2eWindows]::GetWindowText($hwnd, $title, 256)
      $state = @()
      if ([E2eWindows]::IsIconic($hwnd)) { $state += 'MINIMIZED' }
      if ([E2eWindows]::IsZoomed($hwnd)) { $state += 'MAXIMIZED' }
      # The runner keeps the caption style in fullscreen and drops the frame
      # instead, so the client area is the whole window.
      $c = New-Object E2eWindows+RECT
      [void][E2eWindows]::GetClientRect($hwnd, [ref]$c)
      $frameless = ($c.Right - $c.Left) -eq $w -and ($c.Bottom - $c.Top) -eq $h
      if ($frameless -and $r.Left -eq 0 -and $r.Top -eq 0 -and $w -eq $screenW -and $h -eq $screenH) { $state += 'FULLSCREEN' }
      if ($hwnd -eq $foreground) { $state += 'FOREGROUND' }
      $lines.Add("window $hwnd ${w}x${h}+$($r.Left)+$($r.Top) '$title' $($state -join ' ')")
    }
  }
  return $true
}
[void][E2eWindows]::EnumWindows($callback, [IntPtr]::Zero)
if ($lines.Count -eq 0) { 'no Sheetopia window' } else { $lines; "screen ${screenW}x${screenH}" }
