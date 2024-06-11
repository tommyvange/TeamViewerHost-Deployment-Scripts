
# TeamViewer Host Deployment Scripts

These scripts are designed to install, uninstall, and check the presence of TeamViewer Host on Windows machines. They can read parameters from the command line, a configuration file (`config.json`), or use default values. If any required parameter is missing and cannot be resolved, the scripts will fail with an appropriate error message.

This repository is licensed under the **[GNU General Public License v3.0 (GPLv3)](LICENSE)**.

Developed by **[Tommy Vange Rød](https://github.com/tommyvange)**.

## Configuration

The scripts use a configuration file (`config.json`) to store default values for the TeamViewer Host settings. Here is an example of the configuration file:
``` json
{
    "ConfigID": "ABC123",
    "AssignmentID": "AAAAABBBBBCCCCDDDDEEEE11112222333344445555=",
    "Logging": false,
    "NoShortcut": true,
    "DeviceAlias": "%COMPUTERNAME%"
    "InstallerPath": "./TeamViewer_Host.msi"
}
```
### Parameters

-   `ConfigID`: The custom configuration ID for TeamViewer installation.
-   `AssignmentID`: The assignment ID for TeamViewer.
-   `Logging`: Enables transcript logging if set to `true`.
-   `NoShortcut`: If set to `true`, disables the creation of desktop shortcuts during installation.
-   `DeviceAlias`: Specifies the device alias. If not provided, defaults to `%COMPUTERNAME%`.
- `InstallerPath`: The path to the `TeamViewer_Host.msi` installer. Defaults to `./TeamViewer_Host.msi`.

### Obtaining TeamViewer_Host.msi

You must download the `TeamViewer_Host.msi` installer from the TeamViewer Management Console. Once downloaded, place the installer in the same directory as the script or specify the path using the `InstallerPath` parameter.

### Path Considerations

#### `config.json`
The scripts assume relative paths for the `config.json`. It uses a relative path to `config.json` in the same directory as the script. This ensures that the scripts can locate the necessary files correctly when deployed in different environments, such as through Intune.

#### `TeamViewer_Host.msi`
The `InstallerPath` parameter supports both relative and absolute paths. By default, it uses a relative path to `TeamViewer_Host.msi` in the same directory as the script. You can specify an absolute path if the installer is located elsewhere on the system.

## Install Script

### Description

The install script adds TeamViewer using the specified parameters.

### Usage

To run the install script, use the following command:

``` powershell
.\install.ps1 -ConfigID "<ConfigID>" -AssignmentID "<AssignmentID>" [-Logging] [-NoShortcut] [-DeviceAlias "<DeviceAlias>"] [-InstallerPath "<InstallerPath>"]
```

### Parameters

-   `ConfigID`: The configuration ID for TeamViewer installation.
-   `AssignmentID`: The assignment ID for TeamViewer.
-   [Optional] `Logging`: Enables transcript logging if set.
-   [Optional] `NoShortcut`: Disables the creation of desktop shortcuts if set.
-   [Optional] `DeviceAlias`: Specifies the device alias. Defaults to `%COMPUTERNAME%`.
-   [Optional] `InstallerPath`: Specifies the path to the `TeamViewer_Host.msi` installer. Defaults to `./TeamViewer_Host.msi`.

### Fallback to Configuration File

If a parameter is not provided via the command line, the script will attempt to read it from the `config.json` file. If the parameter is still not available, the script will fail and provide an error message.

### Example

To specify values directly via the command:

``` powershell
.\install.ps1 -ConfigID "ABC123" -AssignmentID "AAAAABBBBBCCCCDDDDEEEE11112222333344445555=" -Logging -NoShortcut -DeviceAlias "ACCOUNTING_%COMPUTERNAME%" -InstallerPath "./TeamViewer_Host.msi"
``` 

To use the default values from the configuration file:

``` powershell
.\install.ps1 -Logging
```

### Script Workflow

1.  Start the installation of TeamViewer using `msiexec.exe`.
2.  Wait for 30 seconds for the installation to complete.
3.  Verify the existence of `TeamViewer.exe`.
4.  Run the assignment command with the provided `AssignmentID` and `DeviceAlias`.

## Uninstall Script

### Description

The uninstall script removes TeamViewer Host using the specified parameters.

### Usage

To run the uninstall script, use the following command:

``` powershell
.\uninstall.ps1 [-Logging]
```

### Parameters

-   [Optional] `Logging`: Enables transcript logging if set.

### Fallback to Configuration File

If a parameter is not provided via the command line, the script will attempt to read it from the `config.json` file. If the parameter is still not available, the script will fail and provide an error message.

### Example

To specify values directly via the command:

``` powershell
.\uninstall.ps1 -Logging
``` 

To use the default values from the configuration file:

``` powershell
.\uninstall.ps1
```

### Script Workflow

1.  Retrieve the product GUID for TeamViewer.
2.  Uninstall TeamViewer using `msiexec.exe`.

## Check Script

### Description

The check TeamViewer Host script verifies if TeamViewer Host is installed and outputs "Detected" or "NotDetected". It uses exit codes compatible with Intune: `0` for success (detected) and `1` for failure (not detected).

### Usage

To run the check script, use the following command:

``` powershell
.\check.ps1 [-Logging]
```

#### Usage without `config.json` or Command Arguments

If you are running this as a check script in environments such as Intune, it is best to populate the variables directly in the code. Intune does not allow passing CLI arguments or using `config.json` for check scripts, so the only way is to set the variables within the script itself.

The script includes a section designed for this purpose:

``` powershell
# Manually fill these variables if using environments like Intune 
# (Intune does not support CLI arguments or configuration files for check scripts)
#
# $ManualLogging = $false  # Set to $true to enable logging
```

To use this feature, simply uncomment these lines and populate the variables with your desired values. The script will prioritize these manual settings over CLI arguments and config.json, ensuring that the specified data is used during execution. This approach allows seamless integration with Intune and similar deployment tools.

### Parameters

-   [Optional] `Logging`: Enables transcript logging if set.

### Fallback to Configuration File

If a parameter is not provided via the command line, the script will attempt to read it from the `config.json` file. If the parameter is still not available, the script will fail and provide an error message.

### Example

To specify values directly via the command:

``` powershell
.\check.ps1 -Logging
``` 

To use the default values from the configuration file:

``` powershell
.\check.ps1
```

### Script Workflow

1.  Check if the `Logging` parameter is provided.
2.  Start transcript logging if enabled.
3.  Check if `TeamViewer.exe` exists in the expected locations.
4.  Output "Detected" if TeamViewer is found, otherwise output "NotDetected".

## Logging

### Description

All scripts support transcript logging to capture detailed information about the script execution. Logging can be enabled via the `-Logging` parameter or the configuration file.

### How It Works

When logging is enabled, the scripts will start a PowerShell transcript at the beginning of the execution and stop it at the end. This transcript will include all commands executed and their output, providing a detailed log of the script's actions.

### Enabling Logging

Logging can be enabled by setting the `-Logging` parameter when running the script, or by setting the `Logging` property to `true` in the `config.json` file.

### Log File Location

The log files are stored in the temporary directory of the user running the script. The log file names follow the pattern:

-   For the install script: `installation_log_TeamViewerHost_${ConfigID}.txt`
-   For the uninstall script: `uninstallation_log_TeamViewer.txt`
-   For the check script: `check_TeamViewerHost_log.txt`

Example log file paths:

-   `C:\Users\<Username>\AppData\Local\Temp\installation_log_TeamViewerHost_ABC123.txt`
-   `C:\Users\<Username>\AppData\Local\Temp\uninstallation_log_TeamViewer.txt`
-   `C:\Users\<Username>\AppData\Local\Temp\check_TeamViewerHost_log.txt`

**System Account Exception**: When scripts are run as the System account, such as during automated deployments or via certain administrative tools, the log files will be stored in the `C:\Windows\Temp` directory instead of the user's local temporary directory.

### Example

To enable logging via the command line:

``` powershell
.\install.ps1 -ConfigID "ABC123" -AssignmentID "AAAAABBBBBCCCCDDDDEEEE11112222333344445555=" 
```

Or by setting the `Logging` property in the configuration file:

``` json
{
    "ConfigID": "ABC123",
    "AssignmentID": "AAAAABBBBBCCCCDDDDEEEE11112222333344445555=",
    "Logging": true,
    "NoShortcut": true,
    "DeviceAlias": "%COMPUTERNAME%"
}
```
## Error Handling

All scripts include error handling to provide clear messages when parameters are missing or actions fail. If any required parameter is missing and cannot be resolved, the scripts will fail with an appropriate error message.

## Notes

-   Ensure that you have the necessary permissions to install and uninstall TeamViewer Host on the machine where these scripts are executed.
-   The scripts assume that the necessary files are available at the specified paths.

## Troubleshooting

If you encounter any issues, ensure that all parameters are correctly specified and that the necessary files are available at the provided paths. Check the error messages provided by the scripts for further details on what might have gone wrong.

# GNU General Public License v3.0 (GPLv3)

The **GNU General Public License v3.0 (GPLv3)** is a free, copyleft license for software and other creative works. It ensures your freedom to share, modify, and distribute all versions of a program, keeping it free software for everyone.

Full license can be read [here](LICENSE) or at [gnu.org](https://www.gnu.org/licenses/gpl-3.0.en.html#license-text).

## Key Points:

1.  **Freedom to Share and Change:**
    
    -   You can distribute copies of GPLv3-licensed software.
    -   Access the source code.
    -   Modify the software.
    -   Create new free programs using parts of it.
2.  **Responsibilities:**
    
    -   If you distribute GPLv3 software, pass on the same freedoms to recipients.
    -   Provide the source code.
    -   Make recipients aware of their rights.
3.  **No Warranty:**
    
    -   No warranty for this free software.
    -   Developers protect your rights through copyright and this license.
4.  **Marking Modifications:**
    
    -   Clearly mark modified versions to avoid attributing problems to previous authors.

This README provides comprehensive information about the TeamViewer Deployment Scripts project, covering configuration, installation, uninstallation, checking, logging, error handling, and troubleshooting.