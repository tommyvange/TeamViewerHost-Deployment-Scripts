################################################################################
# Repository: tommyvange/TeamViewerHost-Deployment-Scripts
# File: uninstall.ps1
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

# Path to configuration file
$configFilePath = "$PSScriptRoot\config.json"

# Initialize configuration variable
$config = $null

# Check if configuration file exists and load it
if (Test-Path $configFilePath) {
    $config = Get-Content -Path $configFilePath | ConvertFrom-Json
}

# Use parameters from the command line or fall back to config file values
if (-not $Logging -and $config.Logging -ne $null) { $Logging = $config.Logging }

# Determine log file path
$logFilePath = "$env:TEMP\uninstallation_log_TeamViewer.txt"

# Start transcript logging if enabled
if ($Logging) {
    Start-Transcript -Path $logFilePath
}

<#
.SYNOPSIS
    Retrieves the GUID of the installed TeamViewer product.

.DESCRIPTION
    This function queries the Win32_Product WMI class to retrieve the GUID of the 
    installed TeamViewer product based on the product name provided. The GUID is 
    required for uninstallation using msiexec.

.PARAMETER productName
    The name of the product for which to retrieve the GUID. For example, "TeamViewer Host".

.EXAMPLE
    $productGUID = Get-TeamViewerGUID -productName "TeamViewer Host"

    This command retrieves the GUID of the installed TeamViewer Host product and 
    stores it in the $productGUID variable.

.NOTES
    The function queries the Win32_Product WMI class, which may take some time to 
    execute, especially if there are many installed products.
#>
function Get-TeamViewerGUID {
    param (
        [string]$productName
    )
    
    $product = Get-WmiObject -Query "SELECT IdentifyingNumber FROM Win32_Product WHERE Name='$productName'" | Select-Object -First 1
    if ($product) {
        return $product.IdentifyingNumber
    }
    return $null
}

try {
    # Define the product name
    $productName = "TeamViewer Host"

    # Get the product GUID
    $productGUID = Get-TeamViewerGUID -productName $productName

    if (-not $productGUID) {
        Write-Output "Error: TeamViewer is not installed or GUID not found."
        exit 1
    }

    Write-Output "Uninstalling TeamViewer Host with GUID $productGUID"
    $msiExecArguments = "/x $productGUID /qn"

    Write-Output "Executing: msiexec.exe $msiExecArguments"
    $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $msiExecArguments -Wait -PassThru -ErrorAction Stop

    if ($process.ExitCode -ne 0) {
        Write-Output "Error: Uninstallation failed with exit code $($process.ExitCode)"
        if ($process.ExitCode -eq 1603) {
            Write-Output "Exit code 1603: Fatal error during installation."
        } elseif ($process.ExitCode -eq 1618) {
            Write-Output "Exit code 1618: Another installation is already in progress."
        } elseif ($process.ExitCode -eq 1619) {
            Write-Output "Exit code 1619: This installation package could not be opened. Verify that the package exists and that you can access it."
        }
        exit $process.ExitCode
    } else {
        Write-Output "TeamViewer uninstalled successfully."
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
}
