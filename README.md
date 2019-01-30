# SophosEnterpriseUninstaller
This project facilitates a powershell script which is deployable via SCCM / PDQ etc to uninstall sophos enterprise on-premise.

This powershell script is deployable via SCCM and other management tools and will completely remove any packages relating to sophos via their package registration guids in the registry, those entries point to uninstall files that then get passed to msiexec and powershell then waits for the uninstall to complete before moving onto the next.

Sophos recommend that this is done in a certain order, so the uninstall process is weighted and sorted to favour certain installs that are found in a certain order. Sophos's documentation can be found here: https://community.sophos.com/kb/en-us/109668

I'd recommend that this script is deployed alongside sophos's cloud deployment package documentation if you're migrating to their cloud solution; that documentation can be found here: https://community.sophos.com/kb/en-us/120611

As sophos don't really provide an official script to actually uninstall their old enterprise package, I have created one! It's good practice to run this alongside their cloud installer MSI if you're migrating to their cloud solution

Please test this before deploying to your estate, this script should be run at your own risk!

You should definitely run this script as a local admin to the machine that you intend to run this on, as it does need to uninstall all of the sophos enterprise features, you'll also need to make sure tamper protection is turned off!

As of the latest update, we now support return codes,
  1 - Successful removal of all sophos components (this will be a rarity)
  10 - Partial removal of all sophos components (Returns left-over components on script output)

We now also have a new command line argument -ProvideLoggingFile $TRUE/$FALSE, this dumps a log file onto the root of C:\ (This is accessible via an administrative share if you're joined to a domain).

An example command argument of a verbose uninstall with logging is:
 .\Invoke-UninstallSophos.ps1 -ProvideLoggingFile $TRUE -Verbose
