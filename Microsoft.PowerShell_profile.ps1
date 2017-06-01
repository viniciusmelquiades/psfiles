$profileDir = Split-Path $profile

Import-Module posh-alias
Import-Module "$profileDir/Modules/posh-git/src/posh-git.psd1"

if(($env:PSLastLocation -ne $null) -and (Test-Path $env:PSLastLocation -PathType Container)) {
	Set-Location $env:PSLastLocation
}

function Prompt {
	try {
		$gitBranch = (git branch | Where-Object { $_.startsWith('*') }).TrimStart('* ') 2> $null
	}
	catch {
		$gitBranch = $null;
	}

	if($gitBranch -ne $null -and $gitBranch -ne "") {
		$gitBranch = " ($gitBranch)"
	}

	$location = Get-Location
	$pwd = $location.Path

	$env:PSLastLocation = $pwd

	if($location.Drive.Provider.Name -eq "FileSystem") {
		[system.environment]::currentdirectory = $pwd
	} elseif($pwd.Contains("::")) {
		$pwd = $pwd -replace ".*\:\:"
		[system.environment]::currentdirectory = $pwd
	}

	$pwd = $pwd.Replace($env:userprofile, "~");

	Write-Host "`nPS " -foreground Blue -nonewline
	Write-Host $pwd -foreground Green -nonewline
	Write-Host $gitBranch -foreground Red -NoNewline
	Write-Host ">" -foreground Blue -nonewline
	" "
}

Add-Alias status 'git status'
Add-Alias pull 'git pull -pt --all'
Add-Alias push 'git push -u'
Add-Alias fetch 'git fetch -pt --all'
Add-Alias branch 'git branch'

Add-Alias http 'Invoke-WebRequest -UseBasicParsing'

function sync {
	pull
	if($lastexitcode -eq 0) {
		push
	}
}

function upstream([string]$branch) {
	git branch -f $branch origin/$branch
}

function mklink([string]$link, [string]$target) {
	$exists = Test-Path $target
	if($exists) {
		New-Item $link -ItemType SymbolicLink -Value $target | out-null
		return $link
	}
}

function hardlink([string]$link, [string]$target) {
	if(Test-Path $target -PathType Leaf) {
		New-Item $link -ItemType HardLink -Value $target | out-null
		return $link
	} elseif(Test-Path $target -PathType Container) {
		New-Item $link -ItemType Junction -Value $target | out-null
		return $link
	}
}

function Find-Command([Parameter(
	Position=0,
	Mandatory=$true,
	ValueFromPipeline=$true,
	ValueFromPipelineByPropertyName=$true)]
	[String]$command) {

	return Get-Command $command | Split-Path
}

function Open(
	[Parameter(
			Position=0,
		ValueFromPipeline=$true,
		ValueFromPipelineByPropertyName=$true)]
	[String]$path) {
	if([system.string]::IsNullOrWhiteSpace($path)){
		explorer .
		return;
	}
	if(Test-Path $path -PathType Leaf) {
		$path
	} elseif(Test-Path $path -PathType Container) {
		explorer $path
	}
}

function Time() {
	$sw = [Diagnostics.Stopwatch]::StartNew()
	Invoke-Expression $($args -join ' ') | Out-Default

	$sw.Stop()
	return $($sw.elapsed)
}

function Erase-History() {
	Clear-History | Out-Null
	#[system.reflection.assembly]::loadwithpartialname("System.Windows.Forms") | Out-Null
	#[System.Windows.Forms.SendKeys]::Sendwait('%{F7 2}') | Out-Null
	Remove-Item (Get-PSReadlineOption).HistorySavePath | Out-Null
	[Microsoft.PowerShell.PSConsoleReadLine]::ClearHistory() | Out-Null
	Clear-Host
}

# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
	Import-Module "$ChocolateyProfile"
}