[CmdletBinding()]
param(
  [string]$Process,
  [string]$Title,
  [string]$Class,
  [int]$ProcessId,
  [long]$Hwnd,
  [switch]$Foreground,
  [switch]$List,
  [switch]$IncludeHidden,
  [switch]$Show,
  [switch]$NoScreenFallback,
  [string]$Out,
  [string]$OutDir = "$env:TEMP"
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

Add-Type @"
using System;
using System.Text;
using System.Collections.Generic;
using System.Runtime.InteropServices;

public class WinShot {
  delegate bool EnumProc(IntPtr h, IntPtr p);
  [DllImport("user32.dll")] static extern bool EnumWindows(EnumProc cb, IntPtr p);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int GetClassNameW(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int GetWindowTextW(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll")] static extern int GetWindowTextLengthW(IntPtr h);
  [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll")] static extern bool IsIconic(IntPtr h);
  [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  [DllImport("user32.dll")] static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] static extern bool PrintWindow(IntPtr h, IntPtr dc, uint f);
  [DllImport("user32.dll")] static extern bool ShowWindow(IntPtr h, int n);
  [DllImport("user32.dll")] static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] static extern bool BringWindowToTop(IntPtr h);
  [DllImport("user32.dll")] static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] static extern bool AttachThreadInput(uint a, uint b, bool attach);
  [DllImport("kernel32.dll")] static extern uint GetCurrentThreadId();
  [DllImport("user32.dll")] static extern int GetWindowLong(IntPtr h, int i);
  [DllImport("dwmapi.dll")] static extern int DwmGetWindowAttribute(IntPtr h, int attr, out RECT v, int sz);
  [DllImport("dwmapi.dll")] static extern int DwmGetWindowAttribute(IntPtr h, int attr, out int v, int sz);
  [DllImport("user32.dll")] static extern bool SetProcessDpiAwarenessContext(IntPtr ctx);
  [DllImport("user32.dll")] static extern bool SetProcessDPIAware();

  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
  public struct WinInfo { public IntPtr Hwnd; public uint Pid; public int W; public int H; public string Title; public string Class; }

  const int GWL_EXSTYLE = -20;
  const int WS_EX_TOOLWINDOW = 0x80;
  const int DWMWA_CLOAKED = 14;
  const int DWMWA_EXTENDED_FRAME_BOUNDS = 9;

  public static void DpiAware() {
    try { if (SetProcessDpiAwarenessContext((IntPtr)(-4))) return; } catch {}
    try { SetProcessDPIAware(); } catch {}
  }

  static bool Cloaked(IntPtr h) {
    int v = 0;
    if (DwmGetWindowAttribute(h, DWMWA_CLOAKED, out v, sizeof(int)) == 0 && v != 0) return true;
    return false;
  }

  static string Text(IntPtr h) {
    int n = GetWindowTextLengthW(h);
    if (n <= 0) return "";
    var sb = new StringBuilder(n + 1); GetWindowTextW(h, sb, sb.Capacity); return sb.ToString();
  }
  static string Cls(IntPtr h) { var sb = new StringBuilder(256); GetClassNameW(h, sb, 256); return sb.ToString(); }

  static List<WinInfo> acc; static bool inclHidden;
  static bool Cb(IntPtr h, IntPtr p) {
    bool vis = IsWindowVisible(h);
    if (!inclHidden && (!vis || Cloaked(h))) return true;
    int ex = GetWindowLong(h, GWL_EXSTYLE);
    string title = Text(h);
    if ((ex & WS_EX_TOOLWINDOW) != 0 && title.Length == 0) return true;
    RECT r; GetWindowRect(h, out r);
    int w = r.Right - r.Left, ht = r.Bottom - r.Top;
    if (!inclHidden && (w < 8 || ht < 8)) return true;
    uint pid; GetWindowThreadProcessId(h, out pid);
    acc.Add(new WinInfo { Hwnd = h, Pid = pid, W = w, H = ht, Title = title, Class = Cls(h) });
    return true;
  }
  public static WinInfo[] Enumerate(bool includeHidden) {
    acc = new List<WinInfo>(); inclHidden = includeHidden; EnumWindows(Cb, IntPtr.Zero); return acc.ToArray();
  }

  public static bool Iconic(IntPtr h) { return IsIconic(h); }

  public static void Foreground(IntPtr h) {
    if (IsIconic(h)) ShowWindow(h, 9); else ShowWindow(h, 5);
    uint dummy;
    uint fg = GetWindowThreadProcessId(GetForegroundWindow(), out dummy);
    uint cur = GetCurrentThreadId();
    uint tgt = GetWindowThreadProcessId(h, out dummy);
    AttachThreadInput(cur, fg, true); AttachThreadInput(cur, tgt, true);
    BringWindowToTop(h); SetForegroundWindow(h);
    AttachThreadInput(cur, fg, false); AttachThreadInput(cur, tgt, false);
  }

  static int[] FrameBounds(IntPtr h) {
    RECT r;
    if (DwmGetWindowAttribute(h, DWMWA_EXTENDED_FRAME_BOUNDS, out r, Marshal.SizeOf(typeof(RECT))) != 0)
      GetWindowRect(h, out r);
    return new int[] { r.Left, r.Top, r.Right - r.Left, r.Bottom - r.Top };
  }

  static bool Blank(System.Drawing.Bitmap b) {
    for (int x = 0; x < b.Width; x += 13)
      for (int y = 0; y < b.Height; y += 13) {
        var c = b.GetPixel(x, y);
        if (c.R + c.G + c.B > 24) return false;
      }
    return true;
  }

  public static string PrintShot(IntPtr h, string path) {
    int[] f = FrameBounds(h);
    if (f[2] < 1 || f[3] < 1) return "no-size";
    using (var bmp = new System.Drawing.Bitmap(f[2], f[3])) {
      using (var g = System.Drawing.Graphics.FromImage(bmp)) {
        IntPtr dc = g.GetHdc(); PrintWindow(h, dc, 0x2); g.ReleaseHdc(dc);
      }
      if (Blank(bmp)) return "blank";
      bmp.Save(path, System.Drawing.Imaging.ImageFormat.Png); return "ok";
    }
  }

  public static string ScreenShot(IntPtr h, string path) {
    int[] f = FrameBounds(h);
    if (f[2] < 1 || f[3] < 1) return "no-size";
    using (var bmp = new System.Drawing.Bitmap(f[2], f[3])) {
      using (var g = System.Drawing.Graphics.FromImage(bmp))
        g.CopyFromScreen(f[0], f[1], 0, 0, new System.Drawing.Size(f[2], f[3]));
      if (Blank(bmp)) return "blank";
      bmp.Save(path, System.Drawing.Imaging.ImageFormat.Png); return "ok";
    }
  }
}
"@ -ReferencedAssemblies System.Drawing

[WinShot]::DpiAware()

$all = [WinShot]::Enumerate([bool]$IncludeHidden)

if ($Foreground) {
  Add-Type @"
using System;using System.Runtime.InteropServices;
public class FG { [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow(); }
"@
  $fg = [FG]::GetForegroundWindow()
  $all = $all | Where-Object { $_.Hwnd -eq $fg }
}

$matches = $all
if ($PSBoundParameters.ContainsKey('Hwnd')) { $matches = $matches | Where-Object { [long]$_.Hwnd -eq $Hwnd } }
if ($PSBoundParameters.ContainsKey('ProcessId')) { $matches = $matches | Where-Object { $_.Pid -eq $ProcessId } }
if ($Class) { $matches = $matches | Where-Object { $_.Class -eq $Class } }
if ($Title) { $matches = $matches | Where-Object { $_.Title -match $Title } }
if ($Process) {
  $procIds = (Get-Process -Name $Process -ErrorAction SilentlyContinue).Id
  $matches = $matches | Where-Object { $procIds -contains [int]$_.Pid }
}

function Win-Row($w) {
  $pname = (Get-Process -Id $w.Pid -ErrorAction SilentlyContinue).ProcessName
  [pscustomobject]@{ Hwnd = [long]$w.Hwnd; Pid = [int]$w.Pid; Process = $pname; Size = "$($w.W)x$($w.H)"; Class = $w.Class; Title = $w.Title }
}

if ($List) {
  $matches | ForEach-Object { Win-Row $_ } | Sort-Object Process | Format-Table -AutoSize | Out-String -Width 240 | Write-Output
  return
}

$matches = @($matches)
if ($matches.Count -eq 0) { Write-Error "No window matched the given criteria. Use -List to see candidates."; exit 1 }
if ($matches.Count -gt 1) {
  $matches = $matches | Sort-Object { - ($_.W * $_.H) }
  Write-Warning "Multiple windows matched; capturing the largest. Others:"
  $matches | Select-Object -Skip 1 | ForEach-Object { Win-Row $_ } | Format-Table -AutoSize | Out-String -Width 240 | Write-Warning
}
$target = $matches[0]
$h = [IntPtr][long]$target.Hwnd

if ($Out) { $outPath = $Out }
else {
  $pname = (Get-Process -Id $target.Pid -ErrorAction SilentlyContinue).ProcessName
  $safe = ($pname + "-" + $target.Hwnd) -replace '[^\w\-]', '_'
  $outPath = Join-Path $OutDir "$safe.png"
}

if ($Show -or [WinShot]::Iconic($h)) { [WinShot]::Foreground($h); Start-Sleep -Milliseconds 500 }

$method = "printwindow"
$status = [WinShot]::PrintShot($h, $outPath)
if ($status -ne "ok" -and -not $NoScreenFallback) {
  [WinShot]::Foreground($h); Start-Sleep -Milliseconds 600
  $s2 = [WinShot]::ScreenShot($h, $outPath)
  if ($s2 -eq "ok") { $method = "screen"; $status = "ok" } else { $status = $s2 }
}

[pscustomobject]@{
  Status = $status; Method = $method; Hwnd = [long]$target.Hwnd; Pid = [int]$target.Pid
  Process = (Get-Process -Id $target.Pid -ErrorAction SilentlyContinue).ProcessName
  Title = $target.Title; Size = "$($target.W)x$($target.H)"; Path = $outPath
} | ConvertTo-Json -Compress

if ($status -ne "ok") { exit 2 }
