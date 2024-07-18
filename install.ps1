################################################################################
# Repository: tommyvange/TeamViewerHost-Deployment-Scripts
# File: install.ps1
# Developer: Tommy Vange Rød
# License: GPL 3.0 License
#
# This file is part of "TeamViewerHost-Deployment-Scripts".
#
# "TeamViewerHost-Deployment-Scripts" is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/gpl-3.0.html#license-text>.
################################################################################

param (
    [string]$ConfigID,
    [string]$AssignmentID,
    [switch]$Logging,
    [switch]$NoShortcut,
    [string]$DeviceAlias,
    [string]$InstallerPath,
    [switch]$InstallSecurityKeyRedirection
)

# Path to configuration file
$configFilePath = "$PSScriptRoot\config.json"

# Initialize configuration variable
$config = $null

# Check if configuration file exists and load it
if (Test-Path $configFilePath) {
    $config = Get-Content -Path $configFilePath | ConvertFrom-Json
}

# Use parameters from the command line or fall back to config file values
if (-not $ConfigID) { $ConfigID = $config.ConfigID }
if (-not $AssignmentID) { $AssignmentID = $config.AssignmentID }
if (-not $Logging -and $config.Logging -ne $null) { $Logging = $config.Logging }
if (-not $NoShortcut -and $config.NoShortcut -ne $null) { $NoShortcut = $config.NoShortcut }
if (-not $DeviceAlias) { $DeviceAlias = $config.DeviceAlias }
if (-not $InstallerPath) { $InstallerPath = Join-Path -Path $PSScriptRoot -ChildPath "TeamViewer_Host.msi" }
if (-not $InstallSecurityKeyRedirection -and $config.InstallSecurityKeyRedirection -ne $null) { $InstallSecurityKeyRedirection = $config.InstallSecurityKeyRedirection }

# Default DeviceAlias to COMPUTERNAME if not specified
if (-not $DeviceAlias) { $DeviceAlias = $env:COMPUTERNAME }

# Expand environment variables in DeviceAlias
$DeviceAlias = [System.Environment]::ExpandEnvironmentVariables($DeviceAlias)

# Validate that all parameters are provided
if (-not $ConfigID) { Write-Error "ConfigID is required but not provided."; exit 1 }
if (-not $AssignmentID) { Write-Error "AssignmentID is required but not provided."; exit 1 }
if (-not (Test-Path $InstallerPath)) { Write-Error "InstallerPath is invalid or the file does not exist."; exit 1 }

# Determine log file path
$logFilePath = "$env:TEMP\installation_log_${ConfigID}.txt"

$settingsfile = Join-Path -Path $PSScriptRoot -ChildPath "TeamViewer_Settings.tvopt"

# Start transcript logging if enabled
if ($Logging) {
    Start-Transcript -Path $logFilePath
}

function Remove-TeamViewerShortcut {
    $desktopPaths = @(
        [System.IO.Path]::Combine([System.Environment]::GetFolderPath("Desktop")),
        [System.IO.Path]::Combine([System.Environment]::GetFolderPath("CommonDesktopDirectory"))
    )

    foreach ($path in $desktopPaths) {
        $shortcutPath = [System.IO.Path]::Combine($path, "TeamViewer.lnk")
        if (Test-Path $shortcutPath) {
            Remove-Item $shortcutPath -ErrorAction SilentlyContinue
            Write-Output "Removed shortcut: $shortcutPath"
        }
    }
}

try {
    # Build the MSI install argument list
    $msiArguments = "/i `"$InstallerPath`" /qn CUSTOMCONFIGID=$ConfigID SETTINGSFILE=`"$settingsfile`""
    if ($InstallSecurityKeyRedirection) {
        $msiArguments += " INSTALLSECURITYKEYREDIRECTION=1"
    }
    if ($NoShortcut) {
        $msiArguments += " DESKTOPSHORTCUTS=0"
    }

    # Start the installation of TeamViewer
    Write-Output "Starting installation of TeamViewer Host from $InstallerPath with CUSTOMCONFIGID=$ConfigID"
    if ($InstallSecurityKeyRedirection) {
        Write-Output "InstallSecurityKeyRedirection option is enabled; setting INSTALLSECURITYKEYREDIRECTION=1."
    }
    if ($NoShortcut) {
        Write-Output "NoShortcut option is enabled; setting DESKTOPSHORTCUTS=0."
    }
    $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $msiArguments -Wait -PassThru -ErrorAction Stop
    if ($process.ExitCode -ne 0) {
        Write-Output "Installation failed with exit code $($process.ExitCode)"
        exit $process.ExitCode
    } else {
        Write-Output "Installation succeeded"
    }

    # Wait for 30 seconds
    Write-Output "Waiting for 30 seconds"
    Start-Sleep -Seconds 30

    # Define the paths to check for TeamViewer.exe
    $teamViewerPaths = @(
        "C:\Program Files\TeamViewer\TeamViewer.exe",
        "C:\Program Files (x86)\TeamViewer\TeamViewer.exe"
    )

    # Check if TeamViewer.exe exists in the specified paths
    $teamViewerExists = $false
    foreach ($path in $teamViewerPaths) {
        if (Test-Path -Path $path) {
            Write-Output "Found TeamViewer at $path"
            $teamViewerExists = $true
            $teamViewerExePath = $path
            break
        }
    }

    if (-not $teamViewerExists) {
        Write-Output "TeamViewer.exe not found in the expected locations"
        exit 1
    }

    # Run the assignment command
    Write-Output "Running assignment command with ID $AssignmentID and DeviceAlias $DeviceAlias"
    $process = Start-Process -FilePath $teamViewerExePath -ArgumentList "assignment --id $AssignmentID --device-alias=$DeviceAlias" -Wait -PassThru -ErrorAction Stop
    if ($process.ExitCode -ne 0) {
        Write-Output "Assignment command failed with exit code $($process.ExitCode)"
        exit $process.ExitCode
    } else {
        Write-Output "Assignment command succeeded"
        exit 0
    }
} catch {
    Write-Output "Error: $_"
    exit 1
} finally {
    # Stop transcript logging if enabled
    if ($Logging) {
        Stop-Transcript
    }

    # Remove TeamViewer shortcut if NoShortcut is enabled
    if ($NoShortcut) {
        Remove-TeamViewerShortcut
    }
}
