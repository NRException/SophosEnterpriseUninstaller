# SophosEnterpriseUninstaller

This project facilitates a powershell script which is deployable via SCCM / PDQ etc to uninstall both sophos enterprise on-premise and Sophos Cloud. Sophos recommend that this is done in a certain order, so the uninstall process is weighted and sorted to favour certain installs that are found in a certain order. Sophos's documentation can be found here: https://community.sophos.com/kb/en-us/109668

## Getting Started

Create a project in your deployment platform of choice (SCCM, PDQ Deploy) etc, and deploy it to your target client machines.

### Prerequisites

```
Powershell V2 on target machine
Deployment platform of your choice
```

### Deploying

This script supports a few command line parameters, of which are listed below:

Launch without any logging at all
```
.\Invoke-UninstallSophos.ps1
```

Provide Logging file on root of client C:\ drive
```
.\Invoke-UninstallSophos.ps1 -ProvideLoggingFile $TRUE
```

Provide Logging file on root of client C:\ drive, and output verbose logging to verbose pipeline
```
.\Invoke-UninstallSophos.ps1 -ProvideLoggingFile $TRUE -Verbose
```

If given the verbose switch, this script will annotate most of it's steps for extra debugging, the output of this looks similiar to below:

```
Uninstall chain... Execution may be halted until chain is complete.
Invoking Uninstall Sophos Anti-Virus ({CA3CE456-B2D9-4812-8C69-17D6980432EF}) With Priority of 1
Invoking Uninstall Sophos Anti-Virus ({CA3CE456-B2D9-4812-8C69-17D6980432EF}) With Priority of 2
Invoking Uninstall Sophos Network Threat Protection ({66967E5F-43E8-4402-87A4-04685EE5C2CB}) With Priority of 3
Invoking Uninstall Sophos Anti-Virus ({CA3CE456-B2D9-4812-8C69-17D6980432EF}) With Priority of 3
Invoking Uninstall Sophos System Protection ({1093B57D-A613-47F3-90CF-0FD5C5DCFFE6}) With Priority of 4
etc etc etc
```

The script will also output to the Output pipeline, handing you the final status and left over sophos components (if there are any) along with a return code, an example of this is as below:

```
LeftoverPrograms                                                      Completed
----------------                                                      ---------
Sophos Anti-Virus                                                         False
10
```

This script will also hand-over return codes to the pipeline, these can be used to diagnose installation status' in SCCM and PDQ, these following codes correspond to these statuses:

```
1 - Successful complete uninstall of all components
10 - Partial uninstall of all components, left-over components handed back to output pipleline
```

## Deployment

Create your package in your deployment system of choice and hand it the command line parameters above to suit your needs!

If you're deploying via one of these deployment platforms, you will need to set the execution policy on the target machine, so remember to run these commands before and after execution respectively:

Set execution policy to bypass
```
Set-ExecutionPolicy Bypass
```

Set execution policy to Restricted (Default)
```
Set-ExecutionPolicy Restricted
```

If running this from a package, which will run via cmd/run by default, you'll need to add "powershell.exe" to the start of those commands, eg:
```
powershell.exe Set-ExecutionPolicy Bypass
```

## Built With

* [Microsoft Powershell](https://docs.microsoft.com/en-us/powershell/) - The main IDE and RTE used.

## Contributing

Just submit your pulls!

## Authors

* **Cameron Huggett** - *Complete work* - [NRException](https://github.com/NRException)

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details

