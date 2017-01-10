$profileDir = "$env:userprofile\Documents\WindowsPowerShell"
git clone git@github.com:viniciusmelquiades/psfiles.git $profileDir
git -C $profileDir submodule update --init --recursive