<#
Lawrenceville Market: import fictitious Store 01 employees from employees.csv.
Run in Windows PowerShell on LVM-DC01 as a domain administrator.
Preview first: .\Import-StoreEmployees.ps1 -Preview
Import:        .\Import-StoreEmployees.ps1
Temporary passwords are saved only on the server in the administrator's Documents.
Never upload generated password files to GitHub.
#>
param(
    [string]$CsvPath = (Join-Path $PSScriptRoot 'employees.csv'),
    [switch]$Preview
)

$ErrorActionPreference = 'Stop'
Import-Module ActiveDirectory

$domain = Get-ADDomain
if ($domain.DNSRoot -ne 'lawrencevillemarket.test') {
    throw "Wrong domain: $($domain.DNSRoot). Expected lawrencevillemarket.test."
}

$employeesDn = "OU=Employees,OU=Store-01-Lawrenceville,$($domain.DistinguishedName)"
$ouByDepartment = @{
    'Receiving'        = "OU=Receiving,$employeesDn"
    'Front-End'        = "OU=Front-End,$employeesDn"
    'Store-Management' = "OU=Store-Management,$employeesDn"
    'Grocery'          = "OU=Grocery,$employeesDn"
    'Produce'          = "OU=Produce,$employeesDn"
    'Dairy'            = "OU=Dairy,$employeesDn"
}
$departments = @('Front-End', 'Receiving', 'Store-Management', 'Grocery', 'Produce', 'Dairy')
$targets = @{
    'Front-End' = 18; 'Receiving' = 3; 'Store-Management' = 2
    'Grocery' = 8; 'Produce' = 5; 'Dairy' = 4
}
$expectedExisting = @{
    'Front-End' = @('evan.langston'); 'Receiving' = @('maya.brooks')
    'Store-Management' = @(); 'Grocery' = @(); 'Produce' = @(); 'Dairy' = @()
}

foreach ($department in $departments) {
    $ou = $ouByDepartment[$department]
    Get-ADOrganizationalUnit -Identity $ou | Out-Null
    $actual = @(Get-ADUser -Filter * -SearchBase $ou -SearchScope OneLevel |
        Select-Object -ExpandProperty SamAccountName | Sort-Object)
    $expected = @($expectedExisting[$department] | Sort-Object)
    if (($expected -join '|') -ne ($actual -join '|')) {
        throw "Unexpected accounts in $department ($($actual -join ', ')). Expected: $($expected -join ', '). Check the OU before importing."
    }
}

# An old four-person trial import must be removed before building the full roster.
foreach ($oldLogin in @('ryan.woods', 'allison.baker', 'troy.wilson', 'dominic.tillman')) {
    if (Get-ADUser -LDAPFilter "(sAMAccountName=$oldLogin)") {
        throw "Old trial account $oldLogin still exists. Remove it before importing this roster."
    }
}

$csvEmployees = @(Import-Csv -Path $CsvPath)
if ($csvEmployees.Count -ne 38) { throw "Expected 38 new employees in $CsvPath; found $($csvEmployees.Count)." }

$seen = @{}
$planned = @(
    foreach ($employee in $csvEmployees) {
        $first = [string]$employee.FirstName
        $last = [string]$employee.LastName
        $department = [string]$employee.Department
        $title = [string]$employee.Title

        if ($first -cnotmatch '^[A-Za-z]+$' -or $last -cnotmatch '^[A-Za-z]+$' -or
            [string]::IsNullOrWhiteSpace($title) -or -not $ouByDepartment.ContainsKey($department)) {
            throw "Invalid CSV row: $first $last / $department / $title"
        }

        $login = "$($first.ToLowerInvariant()).$($last.ToLowerInvariant())"
        if ($seen.ContainsKey($login) -or (Get-ADUser -LDAPFilter "(sAMAccountName=$login)")) {
            throw "Duplicate or existing account: $login. No users were imported."
        }
        $seen[$login] = $true

        [pscustomobject]@{
            Name       = "$first $last"
            FirstName  = $first
            LastName   = $last
            Logon      = $login
            Department = $department
            Title      = $title
            OU         = $ouByDepartment[$department]
        }
    }
)

$summary = @(
    foreach ($department in $departments) {
        $newCount = @($planned | Where-Object { $_.Department -eq $department }).Count
        $existingCount = @($expectedExisting[$department]).Count
        if ($existingCount + $newCount -ne $targets[$department]) {
            throw "Wrong total for $department`: existing $existingCount + new $newCount != target $($targets[$department]). No users were imported."
        }
        [pscustomobject]@{
            Department = $department
            Existing = $existingCount
            New = $newCount
            Final = $existingCount + $newCount
            Target = $targets[$department]
        }
    }
)

if ($Preview) {
    $summary | Format-Table -AutoSize
    Write-Host '40 total employees after import; 38 new accounts.'
    $planned | Select-Object Name, Logon, Department, Title | Format-Table -AutoSize
    Write-Host 'Preview only: no accounts were created.'
    return
}

# Create the private output location before changing AD. Do not publish this file.
$privateDir = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'LVM-Onboarding-Private'
$passwordFile = Join-Path $privateDir ("temp-passwords-store01-{0}.csv" -f (Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
if (Test-Path $passwordFile) { throw "Password file already exists: $passwordFile" }
New-Item -ItemType Directory -Path $privateDir -Force | Out-Null

$script:randomSource = [System.Security.Cryptography.RandomNumberGenerator]::Create()
function Get-LabIndex([int]$length) {
    $bytes = New-Object 'System.Byte[]' 4
    $script:randomSource.GetBytes($bytes)
    return [int]([BitConverter]::ToUInt32($bytes, 0) % $length)
}
function New-LabPassword {
    $upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ'
    $lower = 'abcdefghijkmnopqrstuvwxyz'
    $digits = '23456789'
    $symbols = '!@#%'
    $all = $upper + $lower + $digits + $symbols
    $chars = @(
        $upper[(Get-LabIndex $upper.Length)]
        $lower[(Get-LabIndex $lower.Length)]
        $digits[(Get-LabIndex $digits.Length)]
        $symbols[(Get-LabIndex $symbols.Length)]
    )
    while ($chars.Count -lt 18) { $chars += $all[(Get-LabIndex $all.Length)] }
    for ($i = $chars.Count - 1; $i -gt 0; $i--) {
        $j = Get-LabIndex ($i + 1)
        $temp = $chars[$i]
        $chars[$i] = $chars[$j]
        $chars[$j] = $temp
    }
    return -join $chars
}

$created = @()
try {
    if ($planned.Department -contains 'Receiving') {
        Get-ADGroup -Identity 'GG-Store01-Inventory-Access' | Out-Null
    }
    Write-Host "Saving generated temporary passwords to $passwordFile. Keep this file private."
    foreach ($employee in $planned) {
        $temporaryPassword = New-LabPassword
        New-ADUser -Name $employee.Name -DisplayName $employee.Name `
            -GivenName $employee.FirstName -Surname $employee.LastName `
            -SamAccountName $employee.Logon `
            -UserPrincipalName "$($employee.Logon)@$($domain.DNSRoot)" `
            -Department $employee.Department -Title $employee.Title `
            -Path $employee.OU `
            -AccountPassword (ConvertTo-SecureString $temporaryPassword -AsPlainText -Force) `
            -Enabled $true -ChangePasswordAtLogon $true

        # Save each password immediately so a later error cannot lose it.
        $created += [pscustomobject]@{
            Name              = $employee.Name
            Username          = $employee.Logon
            TemporaryPassword = $temporaryPassword
        }
        $created | Export-Csv -Path $passwordFile -NoTypeInformation -Force

        if ($employee.Department -eq 'Receiving') {
            Add-ADGroupMember -Identity 'GG-Store01-Inventory-Access' -Members $employee.Logon
        }
        Write-Host "Created $($employee.Logon) in $($employee.Department)"
    }
}
finally {
    $script:randomSource.Dispose()
}
Write-Host "Done. Temporary passwords: $passwordFile"
Write-Host 'These users must change their temporary password at first sign-in.'
