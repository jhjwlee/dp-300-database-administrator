param (
    # Location will be determined by the found resource group, this is just a fallback if logic fails (shouldn't happen)
    [string]$location = "westus2",
    [string]$sqlAdminPw = $null # Optional, if not provided, a secure one will be generated
)

$bicepFile = "SqlDatabase.bicep"
$requiredPrefix = "dp" # Define the required prefix for the resource group

# Function to generate a secure random password (12 characters, no spaces)
function Get-SecurePassword {
    $lowercase = Get-Random -InputObject "abcdefghijklmnopqrstuvwxyz".ToCharArray()
    $uppercase = Get-Random -InputObject "ABCDEFGHIJKLMNOPQRSTUVWXYZ".ToCharArray()
    $numbers = Get-Random -InputObject "0123456789".ToCharArray()
    $specialChars = Get-Random -InputObject "$!@#%^&*".ToCharArray()
    $randomChars = Get-Random -InputObject "abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789$!@#%^&*()-_=+{}[];:,.<>?".ToCharArray() -Count 8

    # Initialize an empty string
    $secureSuffix = ""

    # Loop through each selection and append only character position [0]
    foreach ($char in ($lowercase, $uppercase, $numbers,  $specialChars) + $randomChars) {
        if ($char -ne " ") {
            $secureSuffix += $char
        }
    }

    # Shuffle the characters to remove any patterns
    $secureSuffix = -join ($secureSuffix.ToCharArray() | Sort-Object {Get-Random})

    return $secureSuffix
}

# Function to validate the provided password (only if provided)
function Test-Password {
    param (
        [string]$testPw
    )

    #Write-Host "Evaluating password == $testPw" -ForegroundColor Yellow

    if ($testPw.Length -lt 12) {
        Write-Host "Error: Password must be at least 12 characters long" -ForegroundColor Red
        exit 1
    }
    if ($testPw -cnotmatch "[a-z]") {
        Write-Host "Error: Password must contain at least one lowercase letter." -ForegroundColor Red
        exit 1
    }
    if ($testPw -cnotmatch "[A-Z]") {
        Write-Host "Error: Password must contain at least one uppercase letter." -ForegroundColor Red
        exit 1
    }
    if ($testPw -notmatch "[0-9]") {
        Write-Host "Error: Password must contain at least one number." -ForegroundColor Red
        exit 1
    }
    if ($testPw -notmatch "[\$!@#%^&*()\-_=+{}\[\];:,.<>?]") {
        Write-Host "Error: Password must contain at least one special character ($!@#%^&*()-_=+{}[];:,.<>?)." -ForegroundColor Red
        exit 1
    }
}

# Function to get the public IP
function Get-PublicIP {
    try {
        # Using a different service as api.ipify.org can sometimes be blocked
        $ip = (Invoke-RestMethod -Uri "https://ifconfig.me/ip").Trim()
        if (-not $ip) { throw "Failed to retrieve IP from ifconfig.me" }
        return $ip
    } catch {
        try {
            Write-Host "Primary IP service failed. Trying backup..." -ForegroundColor Yellow
            $ip = (Invoke-RestMethod -Uri "https://api.ipify.org").Trim()
            if (-not $ip) { throw "Failed to retrieve IP from api.ipify.org" }
             return $ip
        } catch {
             Write-Host "Error: Failed to retrieve public IP from all sources." -ForegroundColor Red
             exit 1
        }
    }
}

# Secure Unique Suffix Generator (8 Characters) - Shortened for SQL Server name limits
function Get-SecureUniqueSuffix {
    $randomNumber = Get-Random -Minimum 10000000 -Maximum 99999999
    $uniqueSuffix = "$randomNumber"
    return $uniqueSuffix
}


# If a password was provided, validate it; otherwise, generate a new one
if ($sqlAdminPw) {
    Test-Password -testPw $sqlAdminPw
} else {
    $sqlAdminPw = Get-SecurePassword
    Write-Host "Generated Secure Password: $sqlAdminPw" -ForegroundColor Cyan
}

# Get current public IP
$publicIp = Get-PublicIP
Write-Host "Your current public IP is: $publicIp" -ForegroundColor Cyan

# --- MODIFIED RESOURCE GROUP LOGIC ---
Write-Host "Searching for existing resource groups starting with '$requiredPrefix'..." -ForegroundColor Yellow
$matchingGroupsJson = az group list --query "[?starts_with(name, '$requiredPrefix')].{Name:name, Location:location}" --output json
if (!$matchingGroupsJson) {
    Write-Host "Error: Failed to query resource groups. Ensure Azure CLI is logged in and permissions are sufficient." -ForegroundColor Red
    exit 1
}
$matchingGroups = $matchingGroupsJson | ConvertFrom-Json

# Handle potential single object vs array output from ConvertFrom-Json
if ($null -ne $matchingGroups -and $matchingGroups -is [System.Management.Automation.PSCustomObject] -and $matchingGroups.PSObject.Properties.Count -gt 0) {
    # If it's a single object, wrap it in an array for consistent handling
    $matchingGroups = @($matchingGroups)
}

if ($null -eq $matchingGroups -or $matchingGroups.Count -eq 0) {
    Write-Host "Error: No existing resource group found starting with '$requiredPrefix'. Please ensure a suitable resource group exists." -ForegroundColor Red
    exit 1
} elseif ($matchingGroups.Count -gt 1) {
    Write-Host "Error: Multiple resource groups found starting with '$requiredPrefix':" -ForegroundColor Red
    $matchingGroups | ForEach-Object { Write-Host "- $($_.Name) ($($_.Location))" }
    Write-Host "Please ensure only one resource group starts with '$requiredPrefix' or modify the script to target a specific name." -ForegroundColor Red
    exit 1
} else {
    # Exactly one match found
    $selectedGroup = $matchingGroups[0] # Get the single item from the array
    $rgName = $selectedGroup.Name
    $location = $selectedGroup.Location # Use the location from the found resource group
    Write-Host "Using existing resource group '$rgName' in location '$location'." -ForegroundColor Green
}
# --- END OF MODIFIED RESOURCE GROUP LOGIC ---

# Generate a unique string for resource names
$uniqueSuffix = Get-SecureUniqueSuffix
Write-Host "Generated unique suffix: $uniqueSuffix" -ForegroundColor Cyan

# Deploy the Bicep file and capture output values
Write-Host "Starting Bicep deployment to resource group '$rgName' in location '$location'..." -ForegroundColor Yellow
$deploymentOutputJson = az deployment group create `
    --resource-group $rgName `
    --template-file "./$bicepFile" `
    --parameters sqlAdminPw="$sqlAdminPw" `
                 adminIpAddress="$publicIp" `
                 uniqueSuffix="$uniqueSuffix" `
    --query "properties.outputs" --output json

if (!$deploymentOutputJson) {
     Write-Host "Error: Bicep deployment failed or produced no output. Check Azure portal for deployment details in resource group '$rgName'." -ForegroundColor Red
     exit 1
}

$deploymentOutput = $deploymentOutputJson | ConvertFrom-Json

# Check if conversion worked and outputs exist
if ($null -eq $deploymentOutput -or $null -eq $deploymentOutput.sqlServerName -or $null -eq $deploymentOutput.sqlDatabaseName -or $null -eq $deploymentOutput.sqlAdminUsername) {
     Write-Host "Error: Failed to parse deployment outputs. Check Azure portal for deployment details in resource group '$rgName'." -ForegroundColor Red
     Write-Host "Raw Output JSON: $deploymentOutputJson"
     exit 1
}


Write-Host "Deployment completed successfully!" -ForegroundColor Green

# Return SQL Server details
Write-Host "`n==================== Deployment Results ====================" -ForegroundColor White
Write-Host "Resource Group Name: $rgName"
Write-Host "SQL Server FQDN:    $($deploymentOutput.sqlServerName.value).database.windows.net" # Added FQDN
Write-Host "SQL Database Name:  $($deploymentOutput.sqlDatabaseName.value)"
Write-Host "SQL Admin Username: $($deploymentOutput.sqlAdminUsername.value)"
Write-Host "SQL Admin Password: $sqlAdminPw"
Write-Host "============================================================" -ForegroundColor White
