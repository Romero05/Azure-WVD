<#Author       : Dean Cefola
# Edited By    : Shehan Silva
# Creation Date: 09-15-2019
# Usage        : Windows Virtual Desktop Scripted Install

#********************************************************************************
# Date                         Version      Changes
#------------------------------------------------------------------------
# 09/15/2019                     1.0        Intial Version
# 09/16/2019                     2.0        Add FSLogix installer
# 09/16/2019                     2.1        Add FSLogix Reg Keys 
# 09/16/2019                     2.2        Add Input Parameters 
# 09/16/2019                     2.3        Add TLS 1.2 settings
# 09/17/2019                     3.0        Chang download locations to dynamic
# 09/17/2019                     3.1        Add code to disable IESEC for admins
# 09/20/2019                     3.2        Add code to discover OS (Server / Client)
# 09/20/2019                     4.0        Add code for servers to add RDS Host role
# 10/01/2019                     4.2        Add all FSLogix Profile Container Reg entries for easier management
# 10/07/2019                     4.3        Add FSLogix Office Container Reg entries for easier management
# 10/16/2019                     5.0        Add Windows 7 Support
# 07/20/2020                     6.0        Add WVD Optimize Code from The-Virtual-Desktop-Team
# 10/27/2020                     7.0        Optimize FSLogix settings - Remove Office Profile Settings
# 02/01/2021                     7.1        Add RegKey for Screen Protection
#
#*********************************************************************************
#
#>


##############################
#    WVD Script Parameters   #
##############################
Param (        
    [Parameter(Mandatory=$true)]
        [string]$RegistrationToken,
    [Parameter(Mandatory=$false)]
        [string]$Optimize = $true           
)


######################
#    WVD Variables   #
######################
$LocalWVDpath            = "c:\temp\wvd\"
$WVDBootURI              = 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrxrH'
$WVDAgentURI             = 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrmXv'
$WVDAgentInstaller       = 'WVD-Agent.msi'
$WVDBootInstaller        = 'WVD-Bootloader.msi'


####################################
#    Test/Create Temp Directory    #
####################################
if((Test-Path c:\temp) -eq $false) {
    Add-Content -LiteralPath C:\New-WVDSessionHost.log "Create C:\temp Directory"
    Write-Host `
        -ForegroundColor Cyan `
        -BackgroundColor Black `
        "creating temp directory"
    New-Item -Path c:\temp -ItemType Directory
}
else {
    Add-Content -LiteralPath C:\New-WVDSessionHost.log "C:\temp Already Exists"
    Write-Host `
        -ForegroundColor Yellow `
        -BackgroundColor Black `
        "temp directory already exists"
}
if((Test-Path $LocalWVDpath) -eq $false) {
    Add-Content -LiteralPath C:\New-WVDSessionHost.log "Create C:\temp\WVD Directory"
    Write-Host `
        -ForegroundColor Cyan `
        -BackgroundColor Black `
        "creating c:\temp\wvd directory"
    New-Item -Path $LocalWVDpath -ItemType Directory
}
else {
    Add-Content -LiteralPath C:\New-WVDSessionHost.log "C:\temp\WVD Already Exists"
    Write-Host `
        -ForegroundColor Yellow `
        -BackgroundColor Black `
        "c:\temp\wvd directory already exists"
}
Add-Content `
-LiteralPath C:\New-WVDSessionHost.log `
"
RegistrationToken = $RegistrationToken
Optimize          = $Optimize
"


#################################
#    Download WVD Componants    #
#################################
Add-Content -LiteralPath C:\New-WVDSessionHost.log "Downloading WVD Boot Loader"
    Invoke-WebRequest -Uri $WVDBootURI -OutFile "$LocalWVDpath$WVDBootInstaller"
Add-Content -LiteralPath C:\New-WVDSessionHost.log "Downloading WVD Agent"
    Invoke-WebRequest -Uri $WVDAgentURI -OutFile "$LocalWVDpath$WVDAgentInstaller"

################################
#    Install WVD Componants    #
################################
Add-Content -LiteralPath C:\New-WVDSessionHost.log "Installing WVD Bootloader"
$bootloader_deploy_status = Start-Process `
    -FilePath "msiexec.exe" `
    -ArgumentList "/i $LocalWVDpath\$WVDBootInstaller", `
        "/quiet", `
        "/qn", `
        "/norestart", `
        "/passive", `
        "/l* $LocalWVDpath\AgentBootLoaderInstall.txt" `
    -Wait `
    -Passthru
$sts = $bootloader_deploy_status.ExitCode
Add-Content -LiteralPath C:\New-WVDSessionHost.log "Installing WVD Bootloader Complete"
Write-Output "Installing RDAgentBootLoader on VM Complete. Exit code=$sts`n"
Wait-Event -Timeout 5
Add-Content -LiteralPath C:\New-WVDSessionHost.log "Installing WVD Agent"
Write-Output "Installing RD Infra Agent on VM $AgentInstaller`n"
$agent_deploy_status = Start-Process `
    -FilePath "msiexec.exe" `
    -ArgumentList "/i $LocalWVDpath\$WVDAgentInstaller", `
        "/quiet", `
        "/qn", `
        "/norestart", `
        "/passive", `
        "REGISTRATIONTOKEN=$RegistrationToken", "/l* $LocalWVDpath\AgentInstall.txt" `
    -Wait `
    -Passthru
Add-Content -LiteralPath C:\New-WVDSessionHost.log "WVD Agent Install Complete"
Wait-Event -Timeout 5


##############################################
#    WVD Optimizer (Virtual Desktop Team)    #
##############################################
If ($Optimize -eq $true) {  
    Write-Output "Optimizer selected"  
    ################################
    #    Download WVD Optimizer    #
    ################################
    Add-Content -LiteralPath C:\New-WVDSessionHost.log "Optimize Selected"
    Add-Content -LiteralPath C:\New-WVDSessionHost.log "Creating C:\Optimize folder"
    New-Item -Path C:\ -Name Optimize -ItemType Directory -ErrorAction SilentlyContinue
    $LocalOptimizePath = "C:\Optimize\"
    $WVDOptimizeURL = 'https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool/archive/master.zip'
    $WVDOptimizeInstaller = "Windows_10_VDI_Optimize-master.zip"
    Invoke-WebRequest `
        -Uri $WVDOptimizeURL `
        -OutFile "$LocalOptimizePath$WVDOptimizeInstaller"


    ###############################
    #    Prep for WVD Optimize    #
    ###############################
    Add-Content -LiteralPath C:\New-WVDSessionHost.log "Optimize downloaded and extracted"
    Expand-Archive `
        -LiteralPath "C:\Optimize\Windows_10_VDI_Optimize-master.zip" `
        -DestinationPath "$LocalOptimizePath" `
        -Force `
        -Verbose
    Set-Location -Path C:\Optimize\Virtual-Desktop-Optimization-Tool-master


    #################################
    #    Run WVD Optimize Script    #
    #################################
    Add-Content -LiteralPath C:\New-WVDSessionHost.log "Begining Optimize"
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force -Verbose
    .\Win10_VirtualDesktop_Optimize.ps1 -WindowsVersion 2004 -Verbose
    Add-Content -LiteralPath C:\New-WVDSessionHost.log "Optimization Complete"
}
else {
    Write-Output "Optimize not selected"
    Add-Content -LiteralPath C:\New-WVDSessionHost.log "Optimize NOT selected"    
}


##########################
#    Restart Computer    #
##########################
Add-Content -LiteralPath C:\New-WVDSessionHost.log "Process Complete - REBOOT"
Restart-Computer -Force 
