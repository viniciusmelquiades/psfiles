Import-Module posh-git
Import-Module posh-alias

function Prompt {
	$gitBranch = git rev-parse --abbrev-ref HEAD 2> $null
	if($gitBranch -ne $null -and $gitBranch -ne "") {
		$gitBranch = " ($gitBranch)"
	}
	$pwd = $(Get-Location).ToString();
	[system.environment]::currentdirectory = $pwd
	$pwd = $pwd.Replace($env:userprofile, "~");
	Write-Host "`nPS " -foreground Blue -nonewline
	Write-Host $pwd -foreground Green -nonewline
	Write-Host $gitBranch -foreground Red -nonewline
	Write-Host ">" -foreground Blue -nonewline

	return " "
}

Add-Alias status 'git status'
Add-Alias pull 'git pull -pt --all'
Add-Alias push 'git push -u'
Add-Alias fetch 'git fetch -pt --all'

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

function Open([Parameter(
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
	Invoke-Expression $($args -join ' ')
	$sw.Stop()
	$sw.elapsed
}

# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
	Import-Module "$ChocolateyProfile"
}