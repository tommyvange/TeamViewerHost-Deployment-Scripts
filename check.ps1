################################################################################
# Repository: tommyvange/TeamViewerHost-Deployment-Scripts
# File: check.ps1
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
    [switch]$Logging
)

# Manually fill these variables if using environments like Intune 
# (Intune does not support CLI arguments or configuration files for check scripts)
#
# $ManualLogging = $false  # Set to $true to enable logging

# Path to configuration file
$configFilePath = "$PSScriptRoot\config.json"

# Initialize configuration variable
$config = $null

# Check if configuration file exists and load it
if (Test-Path $configFilePath) {
    $config = Get-Content -Path $configFilePath | ConvertFrom-Json
}

# Prioritize manually set variables
if ($ManualLogging) { $Logging = $ManualLogging }

# Use parameters from the command line or fall back to config file values
if (-not $Logging -and $config.Logging -ne $null) { $Logging = $config.Logging }

# Determine log file path
$logFilePath = "$env:TEMP\check_TeamViewerHost_log.txt"

# Start transcript logging if enabled
if ($Logging) {
    Start-Transcript -Path $logFilePath
}

<#
.SYNOPSIS
    Checks if TeamViewer is installed on the system.

.DESCRIPTION
    This function checks for the presence of TeamViewer by verifying the existence
    of the TeamViewer executable in standard installation paths. If TeamViewer is 
    detected, it outputs "Detected" and exits with code 0. If TeamViewer is not 
    found, it outputs "NotDetected" and exits with code 1.

.PARAMETER None
    This function does not take any parameters.

.EXAMPLE
    Check-TeamViewer

    This command checks if TeamViewer is installed and outputs the result.

.NOTES
    The function checks the following paths for TeamViewer:
    - C:\Program Files\TeamViewer\TeamViewer.exe
    - C:\Program Files (x86)\TeamViewer\TeamViewer.exe
#>
function Check-TeamViewer {
    $teamViewerPaths = @(
        "C:\Program Files\TeamViewer\TeamViewer.exe",
        "C:\Program Files (x86)\TeamViewer\TeamViewer.exe"
    )

    foreach ($path in $teamViewerPaths) {
        if (Test-Path -Path $path) {
            Write-Output "Detected"
            exit 0
        }
    }

    Write-Output "NotDetected"
    exit 1
}

try {
    Check-TeamViewer
} catch {
    Write-Output "Error: $_"
    exit 1
} finally {
    # Stop transcript logging if enabled
    if ($Logging) {
        Stop-Transcript
    }
}
