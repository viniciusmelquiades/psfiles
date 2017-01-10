# Vinicius Melquiades' powershell files

These are my personal poshfiles.

Installation instructions:

```powershell
git clone git@github.com:viniciusmelquiades/psfiles.git $env:userprofile\Documents\WindowsPowerShell
git -C $env:userprofile\Documents\WindowsPowerShell submodule update --init --recursive
```

or

```powershell
Invoke-WebRequest https://raw.githubusercontent.com/viniciusmelquiades/psfiles/master/install.ps1 -UseBasicParsing | Invoke-Expression
```