# jbright/dotfiles

Configuration files for Jason Bright.  These are my personal dotfiles, and are not intended to be used by anyone else.  I'm sharing them here in case anyone finds them useful.

The scripts in this repository are designed to be run on Windows or Linux.  The scripts are idempotent.  They will install all the software I use, and configure it to my liking.  They will also install the dotfiles in this repository.

## Setup

You can install these dotfiles in a manual or automated fashion.  To install manually, clone this repository into the location where you want to store it (like `~/.dotfiles`) and run the `install` script.  To install automatically, use the `fetch | shell` pattern on Windows or Linux as shown below.

### X-plat install with git

```
git clone https://github.com/jgbright/dotfiles.git ~/.dotfiles && ~/.dotfiles/install.sh
```

### Linux

```
curl -s https://raw.githubusercontent.com/jgbright/dotfiles/main/install-remote.sh | bash
```

### Windows

This command will work with PowerShell 5.0 or later (maybe older).

```
(New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/jgbright/dotfiles/main/install-remote.ps1') | Invoke-Expression

Invoke-RestMethod https://raw.githubusercontent.com/jgbright/dotfiles/main/install-remote.ps1 | Invoke-Expression

```

## Testing

### Linux

You can test the scripts in this repository by running the `test` script.  This will stand up a docker container with a clean ubunutu install.  We can use that container to test installing the dotfiles.

### Windows

You can test this using the [Windows Sandbox](https://learn.microsoft.com/en-us/windows/security/threat-protection/windows-sandbox/windows-sandbox-overview) feature of Windows 10.  This feature allows you to quickly create a disposable vm with a clean install of Windows.  NOTE: When you close the container, all contents are lost (it behaves similarly to `docker run --rm`).

Here are the steps I follow to test in Windows.

1. Open the Windows Sandbox app
1. Open powershell (quickest way is either press win+x or rt-click on start menu button)
1. Copy the command below into the powershell terminal.

    ```pwsh
    (New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/jgbright/dotfiles/main/install-remote.ps1') | Invoke-Expression

<<<<<<< HEAD
    Invoke-RestMethod "https://raw.githubusercontent.com/jgbright/dotfiles/main/install-remote.ps1?random-junk=$(Get-Random)" | Invoke-Expression
=======
    Invoke-RestMethod https://raw.githubusercontent.com/jgbright/dotfiles/main/install.ps1 | Invoke-Expression
>>>>>>> 612f5670e113a023876d445c9bdeec103333ba2f
    ```

1. Wait for the script to finish
1. Validate the result.
