# Prompt based on https://bradwilson.io/blog/prompt/powershell
$profileDir = Split-Path $profile

Import-Module posh-alias
Import-Module "$profileDir/Modules/posh-git/src/posh-git.psd1"
Import-Module "$profileDir/Modules/posh-docker/posh-docker/posh-docker.psd1"
Import-Module "$profileDir/Modules/z/z.psm1"

$setPwd = $false
if (($env:PSLastLocation -ne $null) -and (Test-Path $env:PSLastLocation -PathType Container)) {
	$setPwd = $true
}

set-content Function:prompt {
	if ($setPwd -eq $true) {
		Set-Location $env:PSLastLocation
		$Script:setPwd = $false
	}

	# Start with a blank line, for breathing room :)
	Write-Host ""

	# Reset the foreground color to default
	$Host.UI.RawUI.ForegroundColor = $GitPromptSettings.DefaultColor.ForegroundColor

	# Write ERR for any PowerShell errors
	if ($Error.Count -ne 0) {
		Write-Host " " -NoNewLine
		Write-Host "  ERR " -NoNewLine -BackgroundColor DarkRed -ForegroundColor Yellow
		$Error.Clear()
	}

	# Write non-zero exit code from last launched process
	if ($LASTEXITCODE -ne "") {
		Write-Host " " -NoNewLine
		Write-Host "  $LASTEXITCODE " -NoNewLine -BackgroundColor DarkRed -ForegroundColor Yellow
		$LASTEXITCODE = ""
	}

	# Write any custom prompt environment (f.e., from vs2017.ps1)
	if (get-content variable:\PromptEnvironment -ErrorAction Ignore) {
		Write-Host " " -NoNewLine
		Write-Host $PromptEnvironment -NoNewLine -BackgroundColor DarkMagenta -ForegroundColor White
	}

	# Write the current kubectl context
	if ($env:PS_KUBECTL -NE $false -And (Get-Command "kubectl" -ErrorAction Ignore) -ne $null) {
		$currentContext = (& kubectl config current-context 2> $null)
		if ($Error.Count -eq 0) {
			Write-Host " " -NoNewLine
			Write-Host " " -NoNewLine -BackgroundColor DarkGray -ForegroundColor Green
			Write-Host " $currentContext " -NoNewLine -BackgroundColor DarkGray -ForegroundColor White
		}
		else {
			===
			$Error.Clear()
		}
	}

	# Write the current public cloud Azure CLI subscription
	# NOTE: You will need sed from somewhere (for example, from Git for Windows)
	# if (Test-Path ~/.azure/clouds.config) {
	# 	$currentSub = & sed -nr "/^\[AzureCloud\]/ { :l /^subscription[ ]*=/ { s/.*=[ ]*//; p; q;}; n; b l;}" ~/.azure/clouds.config
	# 	if ($null -ne $currentSub) {
	# 		$currentAccount = (Get-Content ~/.azure/azureProfile.json | ConvertFrom-Json).subscriptions | Where-Object { $_.id -eq $currentSub }
	# 		if ($null -ne $currentAccount) {
	# 			Write-Host " " -NoNewLine
	# 			Write-Host " " -NoNewLine -BackgroundColor DarkCyan -ForegroundColor Yellow
	# 			Write-Host " $($currentAccount.name) " -NoNewLine -BackgroundColor DarkCyan -ForegroundColor White
	# 		}
	# 	}
	# }

	# Write the current Git information
	if ((Get-Command "Get-GitDirectory" -ErrorAction Ignore) -ne $null) {
		if (Get-GitDirectory -ne $null) {
			Write-Host (Write-VcsStatus) -NoNewLine
		}
	}

	# Write the current directory, with home folder normalized to ~
	$currentPath = (get-location).Path.replace($home, "~")
	$idx = $currentPath.IndexOf("::")
	if ($idx -gt -1) { $currentPath = $currentPath.Substring($idx + 2) }

	Write-Host " " -NoNewLine
	Write-Host " " -NoNewLine -BackgroundColor DarkGreen -ForegroundColor Yellow
	Write-Host " $currentPath " -NoNewLine -BackgroundColor DarkGreen -ForegroundColor White

	# Reset LASTEXITCODE so we don't show it over and over again
	$global:LASTEXITCODE = 0

	# Write one + for each level of the pushd stack
	if ((get-location -stack).Count -gt 0) {
		Write-Host " " -NoNewLine
		Write-Host (("+" * ((get-location -stack).Count))) -NoNewLine -ForegroundColor Cyan
	}

	# Newline
	Write-Host ""

	# Determine if the user is admin, so we color the prompt green or red
	$isAdmin = $false
	$isDesktop = ($PSVersionTable.PSEdition -eq "Desktop")

	if ($isDesktop -or $IsWindows) {
		$windowsIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
		$windowsPrincipal = new-object 'System.Security.Principal.WindowsPrincipal' $windowsIdentity
		$isAdmin = $windowsPrincipal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator) -eq 1
	}
 else {
		$isAdmin = ((& id -u) -eq 0)
	}

	if ($isAdmin) { $color = "Red"; }
	else { $color = "Green"; }

	# Write PS> for desktop PowerShell, pwsh> for PowerShell Core
	if ($isDesktop) {
		Write-Host " PS>" -NoNewLine -ForegroundColor $color
	}
	else {
		Write-Host " pwsh>" -NoNewLine -ForegroundColor $color
	}

	# Update the env, so that ConEmu can restart the current console if needed
	$location = Get-Location
	$pwd = $location.Path
	if($location.Drive.Provider.Name -eq "FileSystem") {
		[system.environment]::currentdirectory = $pwd
	} elseif($pwd.Contains("::")) {
		$pwd = $pwd -replace ".*\:\:"
		[system.environment]::currentdirectory = $pwd
	}

	# Always have to return something or else we get the default prompt
	return " "
}

Add-Alias status 'git status'
Add-Alias pull 'git pull -pt --all'
Add-Alias push 'git push -u'
Add-Alias fetch 'git fetch -pt --all'
Add-Alias branch 'git branch'
Add-Alias gk 'gitk --all'
Add-Alias d docker
Add-Alias dc docker-compose
Add-Alias k kubectl

Add-Alias http 'Invoke-WebRequest -UseBasicParsing'

function sync {
	pull
	if ($lastexitcode -eq 0) {
		push
	}
}

function upstream([string]$branch) {
	git branch -f $branch origin/$branch
}

function mklink([string]$link, [string]$target) {
	$exists = Test-Path $target
	if ($exists) {
		New-Item $link -ItemType SymbolicLink -Value $target | out-null
		return $link
	}
}

function hardlink([string]$link, [string]$target) {
	if (Test-Path $target -PathType Leaf) {
		New-Item $link -ItemType HardLink -Value $target | out-null
		return $link
	}
 elseif (Test-Path $target -PathType Container) {
		New-Item $link -ItemType Junction -Value $target | out-null
		return $link
	}
}

function Find-Command([Parameter(
		Position = 0,
		Mandatory = $true,
		ValueFromPipeline = $true,
		ValueFromPipelineByPropertyName = $true)]
	[String]$command) {

	return Get-Command $command | Split-Path
}

function Open(
	[Parameter(
		Position = 0,
		ValueFromPipeline = $true,
		ValueFromPipelineByPropertyName = $true)]
	[String]$path) {
	if ([system.string]::IsNullOrWhiteSpace($path)) {
		explorer .
		return;
	}
	if (Test-Path $path -PathType Leaf) {
		$path
	}
 elseif (Test-Path $path -PathType Container) {
		explorer $path
	}
}

function Time() {
	$sw = [Diagnostics.Stopwatch]::StartNew()
	Invoke-Expression $($args -join ' ')

	$sw.Stop()
	return $($sw.Elapsed)
}


function run-bash() {
	bash -c $($args -join ' ')
}

function Erase-History() {
	Clear-History | Out-Null
	Remove-Item (Get-PSReadlineOption).HistorySavePath | Out-Null
	[Microsoft.PowerShell.PSConsoleReadLine]::ClearHistory() | Out-Null
	Clear-Host
}

# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
	Import-Module "$ChocolateyProfile"
}

# Background colors

$GitPromptSettings.AfterStash.BackgroundColor = [ConsoleColor]::DarkBlue
$GitPromptSettings.AfterStatus.BackgroundColor = [ConsoleColor]::DarkBlue
$GitPromptSettings.BeforeIndex.BackgroundColor = [ConsoleColor]::DarkBlue
$GitPromptSettings.BeforeStash.BackgroundColor = [ConsoleColor]::DarkBlue
$GitPromptSettings.BeforeStatus.BackgroundColor = [ConsoleColor]::DarkBlue
$GitPromptSettings.BranchAheadStatusSymbol.BackgroundColor = [ConsoleColor]::DarkBlue
$GitPromptSettings.BranchBehindAndAheadStatusSymbol.BackgroundColor = [ConsoleColor]::DarkBlue
$GitPromptSettings.BranchBehindStatusSymbol.BackgroundColor = [ConsoleColor]::DarkBlue
$GitPromptSettings.BranchColor.BackgroundColor = [ConsoleColor]::DarkBlue
$GitPromptSettings.BranchGoneStatusSymbol.BackgroundColor = [ConsoleColor]::DarkBlue
$GitPromptSettings.BranchIdenticalStatusSymbol.BackgroundColor = [ConsoleColor]::DarkBlue
$GitPromptSettings.DefaultColor.BackgroundColor = [ConsoleColor]::DarkBlue
$GitPromptSettings.DelimStatus.BackgroundColor = [ConsoleColor]::DarkBlue
$GitPromptSettings.ErrorColor.BackgroundColor = [ConsoleColor]::DarkBlue
$GitPromptSettings.IndexColor.BackgroundColor = [ConsoleColor]::DarkBlue
$GitPromptSettings.LocalDefaultStatusSymbol.BackgroundColor = [ConsoleColor]::DarkBlue
$GitPromptSettings.LocalStagedStatusSymbol.BackgroundColor = [ConsoleColor]::DarkBlue
$GitPromptSettings.LocalWorkingStatusSymbol.BackgroundColor = [ConsoleColor]::DarkBlue
$GitPromptSettings.StashColor.BackgroundColor = [ConsoleColor]::DarkBlue
$GitPromptSettings.WorkingColor.BackgroundColor = [ConsoleColor]::DarkBlue

# Foreground colors

$GitPromptSettings.AfterStatus.ForegroundColor = [ConsoleColor]::Blue
$GitPromptSettings.BeforeStatus.ForegroundColor = [ConsoleColor]::Blue
$GitPromptSettings.BranchColor.ForegroundColor = [ConsoleColor]::White
$GitPromptSettings.BranchGoneStatusSymbol.ForegroundColor = [ConsoleColor]::Blue
$GitPromptSettings.BranchIdenticalStatusSymbol.ForegroundColor = [ConsoleColor]::Blue
$GitPromptSettings.DefaultColor.ForegroundColor = [ConsoleColor]::Gray
$GitPromptSettings.DelimStatus.ForegroundColor = [ConsoleColor]::Blue
$GitPromptSettings.IndexColor.ForegroundColor = [ConsoleColor]::Cyan
$GitPromptSettings.WorkingColor.ForegroundColor = [ConsoleColor]::Yellow

# Prompt shape

$GitPromptSettings.AfterStatus.Text = " "
$GitPromptSettings.BeforeStatus.Text = "  "
$GitPromptSettings.BranchAheadStatusSymbol.Text = ""
$GitPromptSettings.BranchBehindStatusSymbol.Text = ""
$GitPromptSettings.BranchGoneStatusSymbol.Text = ""
$GitPromptSettings.BranchBehindAndAheadStatusSymbol.Text = ""
$GitPromptSettings.BranchIdenticalStatusSymbol.Text = ""
$GitPromptSettings.BranchUntrackedText = "※ "
$GitPromptSettings.DelimStatus.Text = " ॥"
$GitPromptSettings.LocalStagedStatusSymbol.Text = ""
$GitPromptSettings.LocalWorkingStatusSymbol.Text = ""

$GitPromptSettings.EnableStashStatus = $false
$GitPromptSettings.ShowStatusWhenZero = $false
