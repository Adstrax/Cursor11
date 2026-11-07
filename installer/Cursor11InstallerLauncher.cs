using System;
using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;

internal static class Cursor11InstallerLauncher
{
    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    private static extern int MessageBoxW(
        IntPtr owner,
        string text,
        string caption,
        uint type
    );

    [STAThread]
    private static void Main()
    {
        string root = AppDomain.CurrentDomain.BaseDirectory;
        string script = Path.Combine(root, "_internal", "Install_Cursor11.ps1");
        if (!File.Exists(script))
        {
            MessageBoxW(
                IntPtr.Zero,
                "Installer data is missing. Please extract the complete ZIP package first.",
                "Cursor11",
                0x10
            );
            return;
        }

        string powershell = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.System),
            @"WindowsPowerShell\v1.0\powershell.exe"
        );
        ProcessStartInfo startInfo = new ProcessStartInfo
        {
            FileName = powershell,
            Arguments =
                "-NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File "
                + Quote(script),
            WorkingDirectory = root,
            UseShellExecute = false,
            CreateNoWindow = true
        };
        Process.Start(startInfo);
    }

    private static string Quote(string value)
    {
        return "\"" + value.Replace("\"", "\\\"") + "\"";
    }
}
