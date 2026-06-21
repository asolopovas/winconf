param(
  [ValidateSet("launcher", "settings", "both")]
  [string]$Target = "launcher",
  [string]$OutDir = "$env:TEMP",
  [switch]$KeepSettingsOpen
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

Add-Type @"
using System;
using System.Text;
using System.Runtime.InteropServices;
public class LynCap {
  delegate bool EnumProc(IntPtr h, IntPtr p);
  [DllImport("user32.dll")] static extern bool EnumWindows(EnumProc cb, IntPtr p);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int GetClassNameW(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll")] static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] static extern bool PrintWindow(IntPtr h, IntPtr dc, uint f);
  [DllImport("user32.dll")] static extern bool ShowWindow(IntPtr h, int n);
  [DllImport("user32.dll")] static extern bool SetForegroundWindow(IntPtr h);
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
  static IntPtr found; static string target;
  static bool Cb(IntPtr h, IntPtr p) {
    var sb = new StringBuilder(256); GetClassNameW(h, sb, 256);
    if (sb.ToString() == target) { found = h; return false; }
    return true;
  }
  public static IntPtr Find(string cls) { target = cls; found = IntPtr.Zero; EnumWindows(Cb, IntPtr.Zero); return found; }
  public static bool Visible(IntPtr h) { return IsWindowVisible(h); }
  public static void Show(IntPtr h) { ShowWindow(h, 5); SetForegroundWindow(h); }
  public static int[] Rect(IntPtr h) { RECT r; GetWindowRect(h, out r); return new int[] { r.Right - r.Left, r.Bottom - r.Top }; }
  public static bool Shot(IntPtr h, int w, int ht, string path) {
    var bmp = new System.Drawing.Bitmap(w, ht);
    var g = System.Drawing.Graphics.FromImage(bmp);
    IntPtr dc = g.GetHdc(); bool ok = PrintWindow(h, dc, 0x2); g.ReleaseHdc(dc); g.Dispose();
    bmp.Save(path, System.Drawing.Imaging.ImageFormat.Png);
    bool blank = true;
    for (int x = 0; x < w && blank; x += 17)
      for (int y = 0; y < ht && blank; y += 17)
        if (bmp.GetPixel(x, y).R + bmp.GetPixel(x, y).G + bmp.GetPixel(x, y).B > 24) blank = false;
    bmp.Dispose();
    return ok && !blank;
  }
}
"@ -ReferencedAssemblies System.Drawing

function Find-LynExe {
  foreach ($name in "lyn-dev", "lyn") {
    $p = Get-Process $name -ErrorAction SilentlyContinue | Where-Object { $_.Path } | Select-Object -First 1
    if ($p) { return $p.Path }
  }
  return $null
}

function Capture-Window {
  param([string]$Class, [string]$OutPath, [switch]$ForceShow)
  $h = [LynCap]::Find($Class)
  if ($h -eq [IntPtr]::Zero) { return $null }
  foreach ($attempt in 1..3) {
    if ($ForceShow -or -not [LynCap]::Visible($h)) { [LynCap]::Show($h) }
    Start-Sleep -Milliseconds (700 * $attempt)
    $d = [LynCap]::Rect($h)
    if ($d[0] -lt 1 -or $d[1] -lt 1) { continue }
    if ([LynCap]::Shot($h, $d[0], $d[1], $OutPath)) {
      return [pscustomobject]@{ Class = $Class; Hwnd = $h; Width = $d[0]; Height = $d[1]; Path = $OutPath }
    }
  }
  return [pscustomobject]@{ Class = $Class; Hwnd = $h; Width = $d[0]; Height = $d[1]; Path = $OutPath; Warning = "captured but frame may be blank" }
}

$results = @()

if ($Target -eq "launcher" -or $Target -eq "both") {
  $out = Join-Path $OutDir "lyn-launcher.png"
  $r = Capture-Window -Class "LynLauncherWindow" -OutPath $out -ForceShow
  if (-not $r) { Write-Error "Launcher window not found. Is Lyn running? Start it with 'just dev' or launch lyn.exe." }
  $results += $r
}

if ($Target -eq "settings" -or $Target -eq "both") {
  $out = Join-Path $OutDir "lyn-settings.png"
  $spawned = $false
  if ([LynCap]::Find("LynSettingsWindow") -eq [IntPtr]::Zero) {
    $exe = Find-LynExe
    if (-not $exe) { Write-Error "Lyn is not running, cannot open settings. Start it first." }
    Start-Process -FilePath $exe -ArgumentList "--settings-window"
    $spawned = $true
    foreach ($i in 1..20) {
      Start-Sleep -Milliseconds 400
      if ([LynCap]::Find("LynSettingsWindow") -ne [IntPtr]::Zero) { break }
    }
    Start-Sleep -Milliseconds 1200
  }
  $r = Capture-Window -Class "LynSettingsWindow" -OutPath $out
  if (-not $r) { Write-Error "Settings window did not appear." }
  $results += $r
  if ($spawned -and -not $KeepSettingsOpen) {
    Get-Process lyn-dev, lyn -ErrorAction SilentlyContinue |
      Where-Object { $_.MainWindowTitle -eq "Lyn Settings" } |
      Stop-Process -Force -ErrorAction SilentlyContinue
  }
}

$results | ForEach-Object { $_ | ConvertTo-Json -Compress }
