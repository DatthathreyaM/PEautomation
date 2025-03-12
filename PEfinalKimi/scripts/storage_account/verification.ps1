# scripts/storage_account/verification.ps1
param (
    [string]$subscriptionName,
    [string]$resourceGroupName,
    [string]$storageAccountName,
    [string]$location,
    [string]$accountKind,
    [string]$accountReplicationType,
    [string]$accessTier,
    [string]$ipRules
)

# Load subscription data
$subscriptions = Get-Content -Path "subscriptions.json" | ConvertFrom-Json
$selectedSubscription = $subscriptions.subscriptions | Where-Object { $_.name -eq $subscriptionName }

# Verify location
$locations = az account list-locations --query "[].name" -o tsv
if ($locations -notcontains $location) {
    Write-Host "Location verification failed. Location $location is not valid."
    return $false
}

# Verify account kind
$validAccountKinds = @('StorageV2', 'BlobStorage', 'FileStorage', 'BlockBlobStorage', 'Files')
if ($validAccountKinds -notcontains $accountKind) {
    Write-Host "Account kind verification failed. $accountKind is not a valid account kind."
    return $false
}

# Verify account replication type
$validReplicationTypes = @('LRS', 'GRS', 'ZRS', 'RA-GRS', 'RA-GZRS')
if ($validReplicationTypes -notcontains $accountReplicationType) {
    Write-Host "Account replication type verification failed. $accountReplicationType is not a valid replication type."
    return $false
}

# Verify access tier
if ($accessTier) {
    $validAccessTiers = @('Hot', 'Cool')
    if ($validAccessTiers -notcontains $accessTier) {
        Write-Host "Access tier verification failed. $accessTier is not a valid access tier."
        return $false
    }
}

# Verify IP rules format
if ($ipRules) {
    $ipRulesArray = $ipRules -split ','
    foreach ($ipRule in $ipRulesArray) {
        if (-not [System.Net.IPAddress]::TryParse($ipRule, [ref]$null)) {
            Write-Host "IP rule verification failed. $ipRule is not a valid IP address."
            return $false
        }
    }
}

# Verify storage account name
if ($storageAccountName.Length -lt 3 -or $storageAccountName.Length -gt 24) {
    Write-Host "Storage account name verification failed. Name must be between 3 and 24 characters."
    return $false
}

if ($storageAccountName -notmatch '^[a-z0-9]+$') {
    Write-Host "Storage account name verification failed. Name can only contain lowercase letters and numbers."
    return $false
}

Write-Host "All verification checks passed."
return $true