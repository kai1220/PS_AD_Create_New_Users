Skip to content
Personal Open source Business Explore
Sign upSign inPricingBlogSupport
This repository
Search
 Watch 1  Star 0  Fork 0 DataDwarf/createUser
 Code  Issues 0  Pull requests 0  Pulse  Graphs
Branch: master Find file Copy pathcreateUser/createUser.ps1
7238aa9  on 10 Apr 2014
@DataDwarf DataDwarf Create createUser.ps1
1 contributor
RawBlameHistory     144 lines (116 sloc)  4.75 KB
#Choose the type of account to create
[int]$xMenuChoiceA = 0
while ( $xMenuChoiceA -lt 1 -or $xMenuChoiceA -gt 3 ){
    
    Write-Host ""
    Write-Host "Type of Account:"
    Write-host "1. Staff"
    Write-host "2. Contractor"
    Write-host "3. Generic"
    [Int]$xMenuChoiceA = read-host "Please enter an option 1 to 2..."
    
    Switch( $xMenuChoiceA ){
      1 {
        $type = "Staff"
        [int]$chnpwd = 1
        $Box = "OU=StaffOU,DC=mydomain,DC=com"
       }
      2 {
        $type = "Contractor"
        [int]$chnpwd = 1
        $Box = "OU=ContractorOU,DC=mydomain,DC=com"
       }
      1 {
        $type = "Generic"
        [int]$chnpwd = 1
        $Box = "OU=GenericOU,DC=mydomain,DC=com"
       } 
    }
}

#Load the user templates
$templates = Get-ADUser -Filter * -SearchBase "OU=UserTemplates,DC=mydomain,DC=com" -Properties * | sort

#cHoose the user Template to use
Write-Host ""
Write-Host "Choose a Department:"
[int]$count = 0
foreach($t in $templates) {
    $count++
    Write-Host $count')' $t.name
}

[int]$xMenuChoiceA = 0
while ( $xMenuChoiceA -lt 1 -or $xMenuChoiceA -gt $count ){
    
    Write-Host ""
    [Int]$xMenuChoiceA = read-host "Please enter an option 1 to $count..."
    
}

## Set the department to the chosen template
$department = $templates[$xMenuChoiceA-1]

## Get the User's First & Last Names
Write-Host ""
$firstName = read-host "Enter user's First Name: "
Write-Host ""
$lastName = read-host "Enter user's Last Name: "

## Find the next available username
$accountName = $firstName.ToUpper().Substring(0,1) + $lastName.ToUpper()
$userCheck = Get-ADUser -LDAPFilter "(sAMAccountName=$accountName)"
[int]$num = 0
while ($userCheck -ne $null) {
    $num++
    $accountName = $firstName.ToUpper().Substring(0,1) + $num + $lastName.ToUpper()
    $userCheck = Get-ADUser -LDAPFilter "(sAMAccountName=$accountName)"
    }

## Setup user properties
$displayName = $lastName + ", " + $firstName
$desc = $department.Description  + " - " + $type

## Create the user's password
$date = Get-Date
$userPass = $firstName.ToUpper().Substring(0,1) + $lastName.ToUpper().Substring(0,1) + "today" + $date.Day

## Create the users
$newUser = New-ADUser -Name $displayName -SamAccountName $accountName -UserPrincipalName "$accountName@mydomain.com" -Path $Box -GivenName $firstName -Surname $lastName -DisplayName $displayName -Description $desc -enable $True -ChangePasswordAtLogon $chnpwd -AccountPassword (convertto-securestring $userPass -asplaintext -force) -ScriptPath $department.ScriptPath -Department $department.Department -HomeDrive "Z:" -HomeDirectory "$HomePath\$accountName"

## Add group membership to the user
ForEach ($Group in ($department.MemberOf))
{ Add-ADGroupMember $Group $accountName
}

#sleeping for 30 secs to give the domain controllers a chance to replicate
Start-Sleep -s 30

## Set up the user's home folder
$NTDomain = "mydomain"
$HomePath = "\\myFileServer\HOME"

#create the folder
New-Item -Name $accountName -ItemType Directory -Path $HomePath | Out-Null
set-aduser $accountName -homedirectory $HomePath\$accountName -homedrive z:

#set the permissions on the home folder
$ACL = Get-Acl "$HomePath\$accountName"
$ACL.SetAccessRuleProtection($true, $false)

$ACL.Access | ForEach { [Void]$ACL.RemoveAccessRule($_) }
$ACL.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("$NTDomain\Domain Admins","FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")))
$ACL.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("$accountName","Modify", "ContainerInherit, ObjectInherit", "None", "Allow")))
Set-Acl "$HomePath\$accountName" $ACL

#Load exchange snapin
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.Admin

#Choose the mailbox database
$mbDatabases = Get-MailboxDatabase | select Name
Write-Host ""
Write-Host "Choose a Mailbox DataBase:"
[int]$count = 0
foreach($m in $mbDatabases) {
    $count++
    Write-Host $count')' $m.name
}

[int]$xMenuChoiceA = 0
while ( $xMenuChoiceA -lt 1 -or $xMenuChoiceA -gt $count ){
    
    Write-Host ""
    [Int]$xMenuChoiceA = read-host "Please enter an option 1 to $count..."
    
}

## Set the mailbox database
$db = $mbDatabases[$xMenuChoiceA-1].name

#Create user Mailbox
Enable-Mailbox -Identity "$accountName@mydomain.com" -Alias "$firstName.$lastName" -Database "EXVS\$db" | Out-Null
Set-Mailbox "$accountName@mydomain.com" -EmailAddresses (((Get-Mailbox "$accountName@mydomain.com").EmailAddresses)+="smtp:$accountName@mydomain.com")
$emailAddress = Get-Mailbox "$accountName@mydomain.com" | select PrimarySmtpAddress
$emailAddress = $emailAddress.PrimarySmtpAddress

#Output user info
Write-Host ""
Write-Host "User created"
Write-Host $displayName
Write-Host $desc
Write-host "Username: $accountName"
Write-Host "Password: $userPass"
Write-Host "Email Address: $emailAddress"
Contact GitHub API Training Shop Blog About
© 2016 GitHub, Inc. Terms Privacy Security Status Help