# Import the Active Directory module
Set-ExecutionPolicy RemoteSigned
Import-Module ActiveDirectory

# Function to generate a random password
function Generate-RandomPassword {
    $characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()'
    $password = ""
    for ($i = 1; $i -le 20; $i++) {
        $index = Get-Random -Minimum 0 -Maximum $characters.Length
        $password += $characters[$index]
    }
    return $password
}

# Set the username of the user to be disabled
$username = Read-Host "Enter the username"
$targetUser = Get-ADUser -Identity $username

# Disable the user account
$disableResult = Disable-ADAccount -Identity $targetUser -PassThru

# Check if disabling the account was successful
if ($disableResult.Enabled -eq $false) {
    Write-Host -ForegroundColor Green "User '$username' has been successfully disabled."
} else {
    Write-Host -ForegroundColor Red "Failed to disable the user '$username'."
    exit
}

# Generate a random password
$newPassword = Generate-RandomPassword

# Set the user's password to the generated random password
Set-ADAccountPassword -Identity $targetUser -Reset -NewPassword (ConvertTo-SecureString -AsPlainText $newPassword -Force)

# Get all group memberships of the user
$groupMemberships = Get-ADUser -Identity $targetUser -Properties MemberOf | Select-Object -ExpandProperty MemberOf

# Remove the user from all group memberships
$removedGroups = @()
$failedGroups = @()

foreach ($group in $groupMemberships) {
    try {
        Remove-ADGroupMember -Identity $group -Members $targetUser -Confirm:$false -ErrorAction Stop
        $removedGroups += $group
    } catch {
        $failedGroups += $group
    }
}

# Check if removal was successful
if ($removedGroups.Count -gt 0) {
    Write-Host -ForegroundColor Green "User '$targetUser' has been successfully removed from the following groups:"
    $removedGroups | ForEach-Object {
        Write-Host "- $_"
    }
} else {
    Write-Host -ForegroundColor Yellow "User '$targetUser' is not a member of any groups."
}

# Check if any groups failed to remove
if ($failedGroups.Count -gt 0) {
    Write-Host -ForegroundColor Red "Failed to remove the user '$targetUser' from the following groups:"
    $failedGroups | ForEach-Object {
        Write-Host -ForegroundColor Yellow "- $_"
    }
}
# Move the user to a different OU
$targetOU = "[Your OU Here]"
Move-ADObject -Identity $targetUser -TargetPath $targetOU

