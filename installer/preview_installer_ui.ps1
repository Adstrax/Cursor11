param(
    [ValidateSet('en-US', 'zh-CN')]
    [string]$Locale = 'zh-CN'
)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

$dist = Join-Path $PSScriptRoot '..\dist\V1.0'
$installer = Join-Path $dist "$Locale\_internal\Install_Cursor11.ps1"
$output = Join-Path $PSScriptRoot 'screenshots'
$installButtonName = if ($Locale -eq 'en-US') {
    'Install Cursor11'
}
else {
    '安装 Cursor11'
}
$doneButtonName = if ($Locale -eq 'en-US') { 'Done' } else { '完成' }
New-Item -ItemType Directory -Path $output -Force | Out-Null

function Wait-Cursor11Window {
    param(
        [int]$ProcessId,
        [int]$TimeoutSeconds = 10
    )

    $root = [System.Windows.Automation.AutomationElement]::RootElement
    $condition = New-Object System.Windows.Automation.PropertyCondition(
        [System.Windows.Automation.AutomationElement]::ProcessIdProperty,
        $ProcessId
    )
    $deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
    do {
        $window = $root.FindFirst(
            [System.Windows.Automation.TreeScope]::Children,
            $condition
        )
        if ($null -ne $window) {
            return $window
        }
        Start-Sleep -Milliseconds 150
    } while ([DateTime]::UtcNow -lt $deadline)

    throw 'Timed out waiting for the Cursor11 installer window.'
}

function Save-WindowScreenshot {
    param(
        [System.Windows.Automation.AutomationElement]$Window,
        [string]$Path
    )

    $rect = $Window.Current.BoundingRectangle
    $bitmap = New-Object System.Drawing.Bitmap(
        [int]$rect.Width,
        [int]$rect.Height
    )
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    try {
        $graphics.CopyFromScreen(
            [int]$rect.X,
            [int]$rect.Y,
            0,
            0,
            $bitmap.Size
        )
    }
    finally {
        $graphics.Dispose()
    }
    $bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    $bitmap.Dispose()
}

function Find-ButtonByName {
    param(
        [System.Windows.Automation.AutomationElement]$Window,
        [string]$NamePrefix
    )

    $condition = New-Object System.Windows.Automation.PropertyCondition(
        [System.Windows.Automation.AutomationElement]::ControlTypeProperty,
        [System.Windows.Automation.ControlType]::Button
    )
    $buttons = $Window.FindAll(
        [System.Windows.Automation.TreeScope]::Descendants,
        $condition
    )
    foreach ($button in $buttons) {
        if ($button.Current.Name.StartsWith(
            $NamePrefix,
            [StringComparison]::Ordinal
        )) {
            return $button
        }
    }
    throw "Button not found: $NamePrefix"
}

$process = Start-Process `
    -FilePath 'powershell.exe' `
    -ArgumentList @(
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-STA',
        '-WindowStyle',
        'Hidden',
        '-File',
        $installer,
        '-UiPreview'
    ) `
    -PassThru

try {
    $picker = Wait-Cursor11Window -ProcessId $process.Id
    Start-Sleep -Milliseconds 400
    Save-WindowScreenshot `
        -Window $picker `
        -Path (Join-Path $output "Cursor11_${Locale}_Picker.png")

    $installButton = Find-ButtonByName `
        -Window $picker `
        -NamePrefix $installButtonName
    $invoke = $installButton.GetCurrentPattern(
        [System.Windows.Automation.InvokePattern]::Pattern
    )
    $invoke.Invoke()

    Start-Sleep -Milliseconds 650
    $complete = Wait-Cursor11Window -ProcessId $process.Id
    Save-WindowScreenshot `
        -Window $complete `
        -Path (Join-Path $output "Cursor11_${Locale}_Complete.png")

    $doneButton = Find-ButtonByName `
        -Window $complete `
        -NamePrefix $doneButtonName
    $invoke = $doneButton.GetCurrentPattern(
        [System.Windows.Automation.InvokePattern]::Pattern
    )
    $invoke.Invoke()
    [void]$process.WaitForExit(5000)
    Write-Output $output
}
finally {
    if (-not $process.HasExited) {
        Stop-Process -Id $process.Id -Force
    }
}

$restoreProcess = Start-Process `
    -FilePath 'powershell.exe' `
    -ArgumentList @(
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-STA',
        '-WindowStyle',
        'Hidden',
        '-File',
        $installer,
        '-Action',
        'Restore',
        '-UiPreview'
    ) `
    -PassThru

try {
    $restoreWindow = Wait-Cursor11Window -ProcessId $restoreProcess.Id
    Start-Sleep -Milliseconds 400
    Save-WindowScreenshot `
        -Window $restoreWindow `
        -Path (Join-Path $output "Cursor11_${Locale}_Restore.png")

    $doneButton = Find-ButtonByName `
        -Window $restoreWindow `
        -NamePrefix $doneButtonName
    $invoke = $doneButton.GetCurrentPattern(
        [System.Windows.Automation.InvokePattern]::Pattern
    )
    $invoke.Invoke()
    [void]$restoreProcess.WaitForExit(5000)
}
finally {
    if (-not $restoreProcess.HasExited) {
        Stop-Process -Id $restoreProcess.Id -Force
    }
}
