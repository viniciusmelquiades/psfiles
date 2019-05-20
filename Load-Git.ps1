Import-Module "$PSScriptRoot/Modules/posh-git/src/posh-git.psd1"

Add-Alias status 'git status'
Add-Alias pull 'git pull -pt --all'
Add-Alias push 'git push -u'
Add-Alias fetch 'git fetch -pt --all'
Add-Alias branch 'git branch'
Add-Alias gk 'gitk --all'

	
function global:sync {
	pull
	if ($lastexitcode -eq 0) {
		push
	}
}
	
function global:upstream([string]$branch) {
	git branch -f $branch origin/$branch
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
$GitPromptSettings.DefaultColor.ForegroundColor = $ForegroundColor
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