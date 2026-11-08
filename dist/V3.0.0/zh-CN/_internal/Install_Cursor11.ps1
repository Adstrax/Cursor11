param(
    [ValidateSet("", "Install", "Restore")]
    [string]$Action = "",
    [switch]$UiPreview,
    [switch]$RestoreDryRun
)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

if (-not ('Cursor11CursorApi' -as [type])) {
    $cursor11UiAssemblies = @(
        [System.Drawing.Color].Assembly.Location
        [System.Windows.Forms.Form].Assembly.Location
    )
    Add-Type -ReferencedAssemblies $cursor11UiAssemblies -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Runtime.InteropServices;
using System.Windows.Forms;

public static class Cursor11CursorApi
{
    [DllImport("user32.dll")]
    public static extern bool SetProcessDPIAware();

    [DllImport("user32.dll")]
    public static extern uint GetDpiForSystem();

    [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern IntPtr LoadCursorFromFileW(string path);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern IntPtr CopyIcon(IntPtr cursor);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SetSystemCursor(IntPtr cursor, uint id);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool DestroyCursor(IntPtr cursor);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SystemParametersInfo(uint action, uint param, IntPtr data, uint flags);
}

public class Cursor11RoundedButton : System.Windows.Forms.Button
{
    private bool hovered;
    private bool pressed;

    public Color NormalBackColor { get; set; }
    public Color HoverBackColor { get; set; }
    public Color PressedBackColor { get; set; }
    public Color BorderColor { get; set; }
    public int CornerRadius { get; set; }

    public Cursor11RoundedButton()
    {
        SetStyle(
            System.Windows.Forms.ControlStyles.UserPaint |
            System.Windows.Forms.ControlStyles.AllPaintingInWmPaint |
            System.Windows.Forms.ControlStyles.OptimizedDoubleBuffer |
            System.Windows.Forms.ControlStyles.ResizeRedraw |
            System.Windows.Forms.ControlStyles.SupportsTransparentBackColor,
            true
        );
        NormalBackColor = Color.White;
        HoverBackColor = Color.FromArgb(247, 248, 250);
        PressedBackColor = Color.FromArgb(235, 237, 241);
        BorderColor = Color.FromArgb(190, 193, 199);
        CornerRadius = 10;
        FlatStyle = System.Windows.Forms.FlatStyle.Flat;
        UseCompatibleTextRendering = false;
        Cursor = System.Windows.Forms.Cursors.Hand;
    }

    private static GraphicsPath RoundedPath(Rectangle bounds, int radius)
    {
        int diameter = Math.Max(2, radius * 2);
        GraphicsPath path = new GraphicsPath();
        Rectangle arc = new Rectangle(
            bounds.Left,
            bounds.Top,
            Math.Min(diameter, bounds.Width),
            Math.Min(diameter, bounds.Height)
        );
        path.AddArc(arc, 180, 90);
        arc.X = bounds.Right - arc.Width;
        path.AddArc(arc, 270, 90);
        arc.Y = bounds.Bottom - arc.Height;
        path.AddArc(arc, 0, 90);
        arc.X = bounds.Left;
        path.AddArc(arc, 90, 90);
        path.CloseFigure();
        return path;
    }

    protected override void OnPaint(PaintEventArgs e)
    {
        e.Graphics.SmoothingMode =
            System.Drawing.Drawing2D.SmoothingMode.AntiAlias;
        e.Graphics.PixelOffsetMode =
            System.Drawing.Drawing2D.PixelOffsetMode.HighQuality;
        e.Graphics.Clear(Parent == null ? Color.Transparent : Parent.BackColor);

        Rectangle bounds = new Rectangle(
            1,
            1,
            Math.Max(1, ClientSize.Width - 3),
            Math.Max(1, ClientSize.Height - 3)
        );
        Color background = pressed
            ? PressedBackColor
            : (hovered ? HoverBackColor : NormalBackColor);
        Color border = Focused
            ? Color.FromArgb(0, 120, 212)
            : BorderColor;

        using (GraphicsPath path = RoundedPath(bounds, CornerRadius))
        using (SolidBrush fill = new SolidBrush(background))
        using (Pen outline = new Pen(border, Focused ? 2.0f : 1.0f))
        {
            e.Graphics.FillPath(fill, path);
            e.Graphics.DrawPath(outline, path);
        }

        TextFormatFlags flags =
            TextFormatFlags.HorizontalCenter |
            TextFormatFlags.VerticalCenter |
            TextFormatFlags.WordBreak |
            TextFormatFlags.NoPrefix;
        Rectangle textBounds = Rectangle.Inflate(ClientRectangle, -8, -6);
        TextRenderer.DrawText(
            e.Graphics,
            Text,
            Font,
            textBounds,
            ForeColor,
            flags
        );
    }

    protected override void OnMouseEnter(EventArgs e)
    {
        hovered = true;
        Invalidate();
        base.OnMouseEnter(e);
    }

    protected override void OnMouseLeave(EventArgs e)
    {
        hovered = false;
        pressed = false;
        Invalidate();
        base.OnMouseLeave(e);
    }

    protected override void OnMouseDown(MouseEventArgs e)
    {
        pressed = true;
        Invalidate();
        base.OnMouseDown(e);
    }

    protected override void OnMouseUp(MouseEventArgs e)
    {
        pressed = false;
        Invalidate();
        base.OnMouseUp(e);
    }

    protected override void OnGotFocus(EventArgs e)
    {
        Invalidate();
        base.OnGotFocus(e);
    }

    protected override void OnLostFocus(EventArgs e)
    {
        Invalidate();
        base.OnLostFocus(e);
    }
}
'@
}

[void][Cursor11CursorApi]::SetProcessDPIAware()
[System.Windows.Forms.Application]::EnableVisualStyles()
try {
    [void][System.Windows.Forms.Application]::SetHighDpiMode(
        [System.Windows.Forms.HighDpiMode]::PerMonitorV2
    )
}
catch {
}

$version = 'V3.0.0'
$packageName = 'Cursor11_Light'
$schemeName = 'Cursor11 V3.0.0'
$language = 'zh-CN'
if ($language -eq 'en-US') {
    $text = @{
        FormTitle = 'Cursor11 Installer'
        AppTitle = 'Cursor11 Installer'
        Subtitle = "Windows 11 rounded cursors · Light · $version"
        Prompt = 'Choose an action'
        InstallButton = "Install Cursor11`r`nWhite fill / black outline"
        RestoreButton = "Restore Defaults`r`nWindows default cursors"
        ActionNote = 'The current session refreshes after installing or restoring.'
        Cancel = 'Cancel'
        Close = 'Close'
        Done = 'Done'
        OpenSettings = 'Open Mouse Settings'
        RestorePreviewWindow = 'Cursor11 Restore Preview'
        RestorePreviewTitle = 'Restore Windows Default Cursors'
        PreviewStatus = 'Preview only: no system settings were changed.'
        RestorePreviewBody = "Restore contents`r`n`r`n• Windows Aero default pointers`r`n• Default scheme name`r`n`r`nOpen apps may need to be reopened after restoring."
        InstallFailureTitle = 'Cursor11 Installation Failed'
        RestoreFailureTitle = 'Cursor11 Restore Failed'
        RestoreWindowTitle = 'Cursor11 Restore Complete'
        RestoreDoneTitle = 'Windows default cursors restored'
        RestoreDoneBody = "Reminders`r`n`r`n1. Open browsers, editors, or games may cache old cursors; reopen them.`r`n2. If system cursors still do not update, sign out and sign in again.`r`n3. Current scheme: Windows Aero"
        InstallPreviewWindow = 'Cursor11 Installation Preview'
        InstallPreviewTitle = "Cursor11 $version Installation Preview"
        InstallPreviewBody = "Installation contents`r`n`r`n• Light set with 17 cursor roles`r`n• Current scheme: $schemeName`r`n`r`nYou can confirm the active scheme in Mouse settings."
        ResourceMissing = "Cursor resources were not found:`r`n"
        InstallWindowTitle = 'Cursor11 Installation Complete'
        InstallDoneTitle = "Cursor11 $version installed"
        RefreshAll = 'All mapped system pointers were refreshed.'
        RefreshPartial = 'Some pointers will take effect after signing in again: '
        InstallBody = "Reminders`r`n`r`n1. Open browsers, editors, or games may cache old cursors; reopen them.`r`n2. If system cursors still do not update, sign out and sign in again.`r`n3. Confirm the scheme in Settings > Accessibility > Mouse pointer and touch.`r`n`r`nCurrent scheme: $schemeName"
        MappedReadFailure = 'unable to read'
        MappedCopyFailure = 'unable to copy'
        MappedApplyFailure = 'could not be applied to this session'
        DefaultSchemeMissing = 'The Windows Aero default cursor scheme is not registered.'
        DefaultSchemeIncomplete = 'The Windows Aero scheme is incomplete.'
        DefaultReadFailure = 'unable to read default file'
        DefaultCopyFailure = 'unable to copy default cursor'
        DefaultApplyFailure = 'could not be restored in this session'
        RestoreAll = 'Windows default cursors were restored and refreshed.'
        RestorePartial = 'Some default pointers will take effect after signing in again: '
        MissingDefaultPrefix = 'These Windows default cursor files are missing: '
    }
}
else {
    $text = @{
        FormTitle = 'Cursor11 安装器'
        AppTitle = 'Cursor11 安装器'
        Subtitle = "Windows 11 圆角光标 · 亮色版 · $version"
        Prompt = '请选择操作'
        InstallButton = "安装 Cursor11`r`n亮色版 · 白色主体 / 黑色描边"
        RestoreButton = "恢复默认`r`nWindows 默认光标"
        ActionNote = '安装或恢复后会立即刷新当前会话，并提示需要重新打开的程序。'
        Cancel = '取消'
        Close = '关闭'
        Done = '完成'
        OpenSettings = '打开鼠标指针设置'
        RestorePreviewWindow = 'Cursor11 恢复预览'
        RestorePreviewTitle = '恢复 Windows 默认光标'
        PreviewStatus = '界面预览：没有修改任何系统设置。'
        RestorePreviewBody = "恢复内容`r`n`r`n• Windows Aero 默认指针`r`n• 默认方案名称`r`n`r`n完成恢复后，已打开的程序可能需要重新打开。"
        InstallFailureTitle = 'Cursor11 安装失败'
        RestoreFailureTitle = 'Cursor11 恢复失败'
        RestoreWindowTitle = 'Cursor11 恢复完成'
        RestoreDoneTitle = '已恢复 Windows 默认光标'
        RestoreDoneBody = "使用提醒`r`n`r`n1. 已打开的浏览器、编辑器或游戏可能缓存旧光标，请关闭后重新打开。`r`n2. 如果系统范围的指针仍未更新，请注销并重新登录 Windows。`r`n3. 当前方案：Windows Aero"
        InstallPreviewWindow = 'Cursor11 安装预览'
        InstallPreviewTitle = "Cursor11 $version 安装预览"
        InstallPreviewBody = "安装内容`r`n`r`n• 亮色版 17 种光标角色`r`n• 当前方案：$schemeName`r`n`r`n安装完成后可在设置中确认指针方案。"
        ResourceMissing = "找不到光标资源：`r`n"
        InstallWindowTitle = 'Cursor11 安装完成'
        InstallDoneTitle = "Cursor11 $version 已安装"
        RefreshAll = '全部系统指针已尝试立即刷新。'
        RefreshPartial = '部分指针需要重新登录后才能生效：'
        InstallBody = "使用提醒`r`n`r`n1. 已打开的浏览器、编辑器或游戏可能缓存旧光标，请关闭后重新打开。`r`n2. 如果系统范围的指针仍未更新，请注销并重新登录 Windows。`r`n3. 可在「设置 > 辅助功能 > 鼠标指针和触控」中确认方案。`r`n`r`n当前方案：$schemeName"
        MappedReadFailure = '无法读取'
        MappedCopyFailure = '无法复制'
        MappedApplyFailure = '当前会话应用失败'
        DefaultSchemeMissing = 'Windows Aero 默认光标方案未在系统中注册。'
        DefaultSchemeIncomplete = 'Windows Aero 默认光标方案格式不完整。'
        DefaultReadFailure = '无法读取默认文件'
        DefaultCopyFailure = '无法复制默认图标'
        DefaultApplyFailure = '当前会话恢复失败'
        RestoreAll = 'Windows 默认光标已恢复并尝试立即刷新。'
        RestorePartial = '部分默认指针需要重新登录后生效：'
        MissingDefaultPrefix = '以下 Windows 默认光标文件不存在：'
    }
}
$script:Cursor11SelectedAction = $null
$script:Cursor11OpenSettings = $false
$script:Cursor11Dpi = [Cursor11CursorApi]::GetDpiForSystem()
if ($script:Cursor11Dpi -lt 96) {
    $script:Cursor11Dpi = 96
}
$script:Cursor11Scale = $script:Cursor11Dpi / 96.0

function New-Cursor11Point {
    param([int]$X, [int]$Y)
    return [System.Drawing.Point]::new(
        [int][Math]::Round($X * $script:Cursor11Scale),
        [int][Math]::Round($Y * $script:Cursor11Scale)
    )
}

function New-Cursor11Size {
    param([int]$Width, [int]$Height)
    return [System.Drawing.Size]::new(
        [int][Math]::Round($Width * $script:Cursor11Scale),
        [int][Math]::Round($Height * $script:Cursor11Scale)
    )
}

function New-Cursor11Padding {
    param([int]$Left, [int]$Top, [int]$Right, [int]$Bottom)
    return [System.Windows.Forms.Padding]::new(
        [int][Math]::Round($Left * $script:Cursor11Scale),
        [int][Math]::Round($Top * $script:Cursor11Scale),
        [int][Math]::Round($Right * $script:Cursor11Scale),
        [int][Math]::Round($Bottom * $script:Cursor11Scale)
    )
}

function New-Cursor11Font {
    param(
        [single]$Size,
        [System.Drawing.FontStyle]$Style = [System.Drawing.FontStyle]::Regular
    )

    return New-Object System.Drawing.Font(
        'Microsoft YaHei UI',
        $Size,
        $Style,
        [System.Drawing.GraphicsUnit]::Point
    )
}

function Set-Cursor11ButtonStyle {
    param(
        [System.Windows.Forms.Button]$Button,
        [System.Drawing.Color]$Background,
        [System.Drawing.Color]$Foreground,
        [System.Drawing.Color]$Border,
        [System.Drawing.Font]$Font,
        [int]$CornerRadius = 10
    )

    $Button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $Button.FlatAppearance.BorderSize = 1
    $Button.FlatAppearance.BorderColor = $Border
    $Button.BackColor = $Background
    $Button.ForeColor = $Foreground
    $Button.Font = $Font
    $Button.Cursor = [System.Windows.Forms.Cursors]::Hand
    $Button.UseCompatibleTextRendering = $false
    $Button.NormalBackColor = $Background
    $Button.HoverBackColor = [System.Windows.Forms.ControlPaint]::Light(
        $Background,
        0.08
    )
    $Button.PressedBackColor = [System.Windows.Forms.ControlPaint]::Dark(
        $Background,
        0.07
    )
    $Button.BorderColor = $Border
    $Button.CornerRadius = $CornerRadius
}

function Show-Cursor11ActionPicker {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = $text.FormTitle
    $form.ClientSize = New-Cursor11Size 640 390
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.ShowIcon = $false
    $form.BackColor = [System.Drawing.Color]::FromArgb(246, 247, 249)
    $form.Font = New-Cursor11Font 10
    $form.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::None

    $title = New-Object System.Windows.Forms.Label
    $title.Text = $text.AppTitle
    $title.Font = New-Cursor11Font 18 ([System.Drawing.FontStyle]::Bold)
    $title.ForeColor = [System.Drawing.Color]::FromArgb(24, 24, 27)
    $title.AutoSize = $true
    $title.Location = New-Cursor11Point 34 26
    $form.Controls.Add($title)

    $subtitle = New-Object System.Windows.Forms.Label
    $subtitle.Text = $text.Subtitle
    $subtitle.Font = New-Cursor11Font 10
    $subtitle.ForeColor = [System.Drawing.Color]::FromArgb(92, 96, 104)
    $subtitle.AutoSize = $true
    $subtitle.Location = New-Cursor11Point 36 72
    $form.Controls.Add($subtitle)

    $instruction = New-Object System.Windows.Forms.Label
    $instruction.Text = $text.Prompt
    $instruction.Font = New-Cursor11Font 10.5 ([System.Drawing.FontStyle]::Bold)
    $instruction.ForeColor = [System.Drawing.Color]::FromArgb(50, 53, 59)
    $instruction.AutoSize = $true
    $instruction.Location = New-Cursor11Point 36 116
    $form.Controls.Add($instruction)

    $installButton = New-Object Cursor11RoundedButton
    $installButton.Text = $text.InstallButton
    $installButton.Location = New-Cursor11Point 34 150
    $installButton.Size = New-Cursor11Size 272 100
    $installButton.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    Set-Cursor11ButtonStyle `
        -Button $installButton `
        -Background ([System.Drawing.Color]::FromArgb(0, 103, 192)) `
        -Foreground ([System.Drawing.Color]::White) `
        -Border ([System.Drawing.Color]::FromArgb(0, 90, 168)) `
        -Font (New-Cursor11Font 12 ([System.Drawing.FontStyle]::Bold)) `
        -CornerRadius 18
    $form.Controls.Add($installButton)

    $restoreButton = New-Object Cursor11RoundedButton
    $restoreButton.Text = $text.RestoreButton
    $restoreButton.Location = New-Cursor11Point 334 150
    $restoreButton.Size = New-Cursor11Size 272 100
    $restoreButton.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    Set-Cursor11ButtonStyle `
        -Button $restoreButton `
        -Background ([System.Drawing.Color]::White) `
        -Foreground ([System.Drawing.Color]::FromArgb(24, 24, 27)) `
        -Border ([System.Drawing.Color]::FromArgb(180, 184, 190)) `
        -Font (New-Cursor11Font 12 ([System.Drawing.FontStyle]::Bold)) `
        -CornerRadius 18
    $form.Controls.Add($restoreButton)

    $note = New-Object System.Windows.Forms.Label
    $note.Text = $text.ActionNote
    $note.Font = New-Cursor11Font 9
    $note.ForeColor = [System.Drawing.Color]::FromArgb(108, 112, 120)
    $note.AutoSize = $false
    $note.Location = New-Cursor11Point 36 274
    $note.Size = New-Cursor11Size 570 30
    $form.Controls.Add($note)

    $cancelButton = New-Object Cursor11RoundedButton
    $cancelButton.Text = $text.Cancel
    $cancelButton.Location = New-Cursor11Point 512 328
    $cancelButton.Size = New-Cursor11Size 94 36
    Set-Cursor11ButtonStyle `
        -Button $cancelButton `
        -Background ([System.Drawing.Color]::FromArgb(234, 235, 238)) `
        -Foreground ([System.Drawing.Color]::FromArgb(45, 48, 54)) `
        -Border ([System.Drawing.Color]::FromArgb(190, 193, 199)) `
        -Font (New-Cursor11Font 10) `
        -CornerRadius 10
    $cancelButton.Add_Click({
        $form.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        $form.Close()
    })
    $form.Controls.Add($cancelButton)
    $form.CancelButton = $cancelButton

    $installButton.Add_Click({
        $script:Cursor11SelectedAction = 'Install'
        $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $form.Close()
    })
    $restoreButton.Add_Click({
        $script:Cursor11SelectedAction = 'Restore'
        $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $form.Close()
    })
    $form.AcceptButton = $installButton

    [void]$form.ShowDialog()
    $form.Dispose()
    return $script:Cursor11SelectedAction
}

function Show-Cursor11Complete {
    param(
        [string]$WindowTitle = '',
        [string]$TitleText,
        [string]$StatusText,
        [string]$BodyText
    )

    if (-not $WindowTitle) {
        $WindowTitle = $text.AppTitle
    }
    $script:Cursor11OpenSettings = $false
    $form = New-Object System.Windows.Forms.Form
    $form.Text = $WindowTitle
    $form.ClientSize = New-Cursor11Size 720 470
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.ShowIcon = $false
    $form.BackColor = [System.Drawing.Color]::FromArgb(246, 247, 249)
    $form.Font = New-Cursor11Font 10
    $form.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::None

    $title = New-Object System.Windows.Forms.Label
    $title.Text = $TitleText
    $title.Font = New-Cursor11Font 17 ([System.Drawing.FontStyle]::Bold)
    $title.ForeColor = [System.Drawing.Color]::FromArgb(24, 24, 27)
    $title.AutoSize = $true
    $title.Location = New-Cursor11Point 34 28
    $form.Controls.Add($title)

    $status = New-Object System.Windows.Forms.Label
    $status.Text = $StatusText
    $status.Font = New-Cursor11Font 10.5
    $status.ForeColor = [System.Drawing.Color]::FromArgb(35, 122, 75)
    $status.AutoSize = $false
    $status.Location = New-Cursor11Point 36 76
    $status.Size = New-Cursor11Size 646 32
    $form.Controls.Add($status)

    $body = New-Object System.Windows.Forms.Label
    $body.Text = $BodyText
    $body.Font = New-Cursor11Font 10.5
    $body.ForeColor = [System.Drawing.Color]::FromArgb(55, 58, 64)
    $body.AutoSize = $false
    $body.Location = New-Cursor11Point 36 122
    $body.Size = New-Cursor11Size 646 238
    $body.Padding = New-Cursor11Padding 18 14 18 14
    $body.BackColor = [System.Drawing.Color]::White
    $form.Controls.Add($body)

    $doneButton = New-Object Cursor11RoundedButton
    $doneButton.Text = $text.Done
    $doneButton.Location = New-Cursor11Point 582 396
    $doneButton.Size = New-Cursor11Size 100 38
    Set-Cursor11ButtonStyle `
        -Button $doneButton `
        -Background ([System.Drawing.Color]::FromArgb(0, 120, 212)) `
        -Foreground ([System.Drawing.Color]::White) `
        -Border ([System.Drawing.Color]::FromArgb(0, 105, 185)) `
        -Font (New-Cursor11Font 10.5 ([System.Drawing.FontStyle]::Bold)) `
        -CornerRadius 10
    $doneButton.Add_Click({
        $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $form.Close()
    })
    $form.Controls.Add($doneButton)

    $settingsButton = New-Object Cursor11RoundedButton
    $settingsButton.Text = $text.OpenSettings
    $settingsButton.Location = New-Cursor11Point 398 396
    $settingsButton.Size = New-Cursor11Size 168 38
    Set-Cursor11ButtonStyle `
        -Button $settingsButton `
        -Background ([System.Drawing.Color]::FromArgb(234, 235, 238)) `
        -Foreground ([System.Drawing.Color]::FromArgb(45, 48, 54)) `
        -Border ([System.Drawing.Color]::FromArgb(190, 193, 199)) `
        -Font (New-Cursor11Font 10) `
        -CornerRadius 10
    $settingsButton.Add_Click({
        $script:Cursor11OpenSettings = $true
        $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $form.Close()
    })
    $form.Controls.Add($settingsButton)
    $form.AcceptButton = $doneButton

    [void]$form.ShowDialog()
    $form.Dispose()
}

function Show-Cursor11Error {
    param(
        [string]$Text,
        [string]$Title = ''
    )

    if (-not $Title) {
        $Title = $text.InstallFailureTitle
    }
    $form = New-Object System.Windows.Forms.Form
    $form.Text = $Title
    $form.ClientSize = New-Cursor11Size 640 260
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.ShowIcon = $false
    $form.BackColor = [System.Drawing.Color]::FromArgb(246, 247, 249)
    $form.Font = New-Cursor11Font 10.5

    $label = New-Object System.Windows.Forms.Label
    $label.Text = $Text
    $label.Font = New-Cursor11Font 10.5
    $label.ForeColor = [System.Drawing.Color]::FromArgb(55, 58, 64)
    $label.AutoSize = $false
    $label.Location = New-Cursor11Point 34 34
    $label.Size = New-Cursor11Size 572 138
    $form.Controls.Add($label)

    $button = New-Object Cursor11RoundedButton
    $button.Text = $text.Close
    $button.Location = New-Cursor11Point 506 198
    $button.Size = New-Cursor11Size 100 36
    Set-Cursor11ButtonStyle `
        -Button $button `
        -Background ([System.Drawing.Color]::FromArgb(234, 235, 238)) `
        -Foreground ([System.Drawing.Color]::FromArgb(45, 48, 54)) `
        -Border ([System.Drawing.Color]::FromArgb(190, 193, 199)) `
        -Font (New-Cursor11Font 10) `
        -CornerRadius 10
    $button.Add_Click({
        $form.Close()
    })
    $form.Controls.Add($button)
    $form.AcceptButton = $button

    [void]$form.ShowDialog()
    $form.Dispose()
}

function Set-Cursor11RestoreValue {
    param(
        [string]$Name,
        [string]$Value
    )

    $cursorKey = 'HKCU:\Control Panel\Cursors'
    if ([string]::IsNullOrWhiteSpace($Value)) {
        Remove-ItemProperty `
            -LiteralPath $cursorKey `
            -Name $Name `
            -ErrorAction SilentlyContinue
        return
    }
    New-ItemProperty `
        -LiteralPath $cursorKey `
        -Name $Name `
        -Value $Value `
        -PropertyType String `
        -Force | Out-Null
}

function Get-Cursor11WindowsDefaultEntries {
    $schemeKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Control Panel\Cursors\Schemes'
    $scheme = (Get-ItemProperty `
        -LiteralPath $schemeKey `
        -Name 'Windows Aero').'Windows Aero'
    if ([string]::IsNullOrWhiteSpace($scheme)) {
        throw $text.DefaultSchemeMissing
    }
    $entries = @($scheme.Split(','))
    if ($entries.Count -lt 17) {
        throw $text.DefaultSchemeIncomplete
    }
    return $entries[0..16]
}

function Restore-Cursor11WindowsDefault {
    $entries = @(Get-Cursor11WindowsDefaultEntries)
    $defaultMapping = @(
        @{ Name = 'Arrow';       Index = 0;  Id = 32512 },
        @{ Name = 'Help';        Index = 1;  Id = 32651 },
        @{ Name = 'AppStarting'; Index = 2;  Id = 32650 },
        @{ Name = 'Wait';        Index = 3;  Id = 32514 },
        @{ Name = 'Crosshair';   Index = 4;  Id = 32515 },
        @{ Name = 'IBeam';       Index = 5;  Id = 32513 },
        @{ Name = 'NWPen';       Index = 6;  Id = 32631 },
        @{ Name = 'No';          Index = 7;  Id = 32648 },
        @{ Name = 'SizeNS';      Index = 8;  Id = 32645 },
        @{ Name = 'SizeWE';      Index = 9;  Id = 32644 },
        @{ Name = 'SizeNWSE';    Index = 10; Id = 32642 },
        @{ Name = 'SizeNESW';    Index = 11; Id = 32643 },
        @{ Name = 'SizeAll';     Index = 12; Id = 32646 },
        @{ Name = 'UpArrow';     Index = 13; Id = 32516 },
        @{ Name = 'Hand';        Index = 14; Id = 32649 },
        @{ Name = 'Pin';         Index = 15; Id = 32671 },
        @{ Name = 'Person';      Index = 16; Id = 32672 }
    )

    $applyFailures = @()
    foreach ($item in $defaultMapping) {
        $path = $entries[$item.Index]
        Set-Cursor11RestoreValue -Name $item.Name -Value $path
        if ([string]::IsNullOrWhiteSpace($path)) {
            continue
        }

        [IntPtr]$loaded = [Cursor11CursorApi]::LoadCursorFromFileW($path)
        if ($loaded -eq [IntPtr]::Zero) {
            $applyFailures += "$($item.Name): $($text.DefaultReadFailure)"
            continue
        }
        [IntPtr]$copy = [Cursor11CursorApi]::CopyIcon($loaded)
        [void][Cursor11CursorApi]::DestroyCursor($loaded)
        if ($copy -eq [IntPtr]::Zero) {
            $applyFailures += "$($item.Name): $($text.DefaultCopyFailure)"
            continue
        }
        if (-not [Cursor11CursorApi]::SetSystemCursor($copy, [uint32]$item.Id)) {
            $applyFailures += "$($item.Name): $($text.DefaultApplyFailure)"
        }
    }

    Remove-ItemProperty `
        -LiteralPath 'HKCU:\Control Panel\Cursors' `
        -Name 'precisionhair' `
        -ErrorAction SilentlyContinue
    Set-Item -Path 'HKCU:\Control Panel\Cursors' -Value 'Windows Aero'
    New-ItemProperty `
        -LiteralPath 'HKCU:\Control Panel\Cursors' `
        -Name 'Scheme Source' `
        -Value 1 `
        -PropertyType DWord `
        -Force | Out-Null
    Remove-ItemProperty `
        -LiteralPath 'HKCU:\Control Panel\Cursors\Schemes' `
        -Name $schemeName `
        -ErrorAction SilentlyContinue

    [void][Cursor11CursorApi]::SystemParametersInfo(
        0x0057,
        0,
        [IntPtr]::Zero,
        3
    )

    if ($applyFailures.Count -eq 0) {
        return $text.RestoreAll
    }
    return $text.RestorePartial + ($applyFailures -join '; ')
}

if ($RestoreDryRun) {
    $entries = @(Get-Cursor11WindowsDefaultEntries)
    $missingDefaultFiles = @($entries | Where-Object {
        -not [string]::IsNullOrWhiteSpace($_) -and
        -not (Test-Path -LiteralPath $_)
    })
    if ($missingDefaultFiles.Count -gt 0) {
        throw (
            $text.MissingDefaultPrefix +
            ($missingDefaultFiles -join '; ')
        )
    }
    Write-Output 'RestoreDryRunOK'
    exit 0
}

if (-not $Action) {
    $Action = Show-Cursor11ActionPicker
}

if (-not $Action) {
    exit
}

if ($Action -eq 'Restore') {
    if ($UiPreview) {
        Show-Cursor11Complete `
            -WindowTitle $text.RestorePreviewWindow `
            -TitleText $text.RestorePreviewTitle `
            -StatusText $text.PreviewStatus `
            -BodyText $text.RestorePreviewBody
        exit
    }

    try {
        $restoreNote = Restore-Cursor11WindowsDefault
    }
    catch {
        Show-Cursor11Error `
            -Text $_.Exception.Message `
            -Title $text.RestoreFailureTitle
        exit 1
    }
    Show-Cursor11Complete `
        -WindowTitle $text.RestoreWindowTitle `
        -TitleText $text.RestoreDoneTitle `
        -StatusText $restoreNote `
        -BodyText $text.RestoreDoneBody
    if ($script:Cursor11OpenSettings) {
        Start-Process 'ms-settings:accessibility-cursors'
    }
    exit
}

if ($UiPreview) {
    Show-Cursor11Complete `
        -WindowTitle $text.InstallPreviewWindow `
        -TitleText $text.InstallPreviewTitle `
        -StatusText $text.PreviewStatus `
        -BodyText $text.InstallPreviewBody
    exit
}

$source = Join-Path $PSScriptRoot $packageName
if (-not (Test-Path -LiteralPath $source)) {
    Show-Cursor11Error -Text ($text.ResourceMissing + "`r`n$source")
    exit 1
}

$destination = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Cursors\$packageName"
New-Item -ItemType Directory -Path $destination -Force | Out-Null
Copy-Item -Path (Join-Path $source '*.cur') -Destination $destination -Force
Copy-Item -Path (Join-Path $source '*.ani') -Destination $destination -Force

$mapping = @(
    @{ Name = 'Arrow';       File = 'pointer.cur';     Id = 32512 },
    @{ Name = 'IBeam';       File = 'beam.cur';        Id = 32513 },
    @{ Name = 'Wait';        File = 'busy.ani';        Id = 32514 },
    @{ Name = 'Crosshair';   File = 'precision.cur';   Id = 32515 },
    @{ Name = 'UpArrow';     File = 'alternate.cur';   Id = 32516 },
    @{ Name = 'SizeNWSE';    File = 'dgn1.cur';        Id = 32642 },
    @{ Name = 'SizeNESW';    File = 'dgn2.cur';        Id = 32643 },
    @{ Name = 'SizeWE';      File = 'horz.cur';        Id = 32644 },
    @{ Name = 'SizeNS';      File = 'vert.cur';        Id = 32645 },
    @{ Name = 'SizeAll';     File = 'move.cur';        Id = 32646 },
    @{ Name = 'No';          File = 'unavailable.cur'; Id = 32648 },
    @{ Name = 'Hand';        File = 'link.cur';        Id = 32649 },
    @{ Name = 'AppStarting'; File = 'working.ani';     Id = 32650 },
    @{ Name = 'Help';        File = 'help.cur';        Id = 32651 },
    @{ Name = 'Pin';         File = 'pin.cur';         Id = 32671 },
    @{ Name = 'Person';      File = 'person.cur';      Id = 32672 }
)

$schemeOrder = @(
    'pointer.cur',
    'help.cur',
    'working.ani',
    'busy.ani',
    'precision.cur',
    'beam.cur',
    'handwriting.cur',
    'unavailable.cur',
    'vert.cur',
    'horz.cur',
    'dgn1.cur',
    'dgn2.cur',
    'move.cur',
    'alternate.cur',
    'link.cur',
    'person.cur',
    'pin.cur'
)

$schemeValue = ($schemeOrder | ForEach-Object {
    Join-Path $destination $_
}) -join ','

New-Item -Path 'HKCU:\Control Panel\Cursors\Schemes' -Force | Out-Null
Set-ItemProperty `
    -Path 'HKCU:\Control Panel\Cursors\Schemes' `
    -Name $schemeName `
    -Value $schemeValue

foreach ($item in $mapping) {
    Set-ItemProperty `
        -Path 'HKCU:\Control Panel\Cursors' `
        -Name $item.Name `
        -Value (Join-Path $destination $item.File)
}
Set-ItemProperty `
    -Path 'HKCU:\Control Panel\Cursors' `
    -Name 'NWPen' `
    -Value (Join-Path $destination 'handwriting.cur')
Set-ItemProperty `
    -Path 'HKCU:\Control Panel\Cursors' `
    -Name 'precisionhair' `
    -Value (Join-Path $destination 'precision.cur')
Set-Item -Path 'HKCU:\Control Panel\Cursors' -Value $schemeName

$applyFailures = @()
foreach ($item in $mapping) {
    $path = Join-Path $destination $item.File
    [IntPtr]$loaded = [Cursor11CursorApi]::LoadCursorFromFileW($path)
    if ($loaded -eq [IntPtr]::Zero) {
        $applyFailures += "$($item.Name): $($text.MappedReadFailure)"
        continue
    }

    [IntPtr]$copy = [Cursor11CursorApi]::CopyIcon($loaded)
    [void][Cursor11CursorApi]::DestroyCursor($loaded)
    if ($copy -eq [IntPtr]::Zero) {
        $applyFailures += "$($item.Name): $($text.MappedCopyFailure)"
        continue
    }

    if (-not [Cursor11CursorApi]::SetSystemCursor($copy, [uint32]$item.Id)) {
        $applyFailures += "$($item.Name): $($text.MappedApplyFailure)"
    }
}

[void][Cursor11CursorApi]::SystemParametersInfo(0x0057, 0, [IntPtr]::Zero, 3)

$refreshNote = if ($applyFailures.Count -eq 0) {
    $text.RefreshAll
}
else {
    $text.RefreshPartial + ($applyFailures -join '; ')
}

Show-Cursor11Complete `
    -WindowTitle $text.InstallWindowTitle `
    -TitleText $text.InstallDoneTitle `
    -StatusText $refreshNote `
    -BodyText $text.InstallBody

if ($script:Cursor11OpenSettings) {
    Start-Process 'ms-settings:accessibility-cursors'
}
