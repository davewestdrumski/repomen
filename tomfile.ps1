# Script start
# List of all HotFixes containing the patch
$hotfixes = @('KB4012598', 'KB4012212','KB4012215', 'KB4015549', 'KB4019264', 'KB4012213', 'KB4012216', 'KB4015550', 'KB4019215', 'KB4012214', 'KB4012217', 'KB4015551', 'KB4019216', 'KB4012606', 'KB4015221', 'KB4016637', 'KB4019474', 'KB4013198', 'KB4015219', 'KB4016636', 'KB4019473', 'KB4013429', 'KB4015217', 'KB4015438', 'KB4016635', 'KB4019472', 'KB4018466')
# Search for the HotFixes
$hotfix = Get-HotFix | Where-Object {$hotfixes -contains $_.HotfixID} | Select-Object -property "HotFixID"
# See if the HotFix was found
if (Get-HotFix | Where-Object {$hotfixes -contains $_.HotfixID}) {write-host "Found hotfix" $_.HotfixID
} else {
write-host "Didn't find hotfix"
}
# Script end