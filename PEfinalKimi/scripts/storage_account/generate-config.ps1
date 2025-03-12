# scripts/storage_account/generate-config.ps1
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

# Find selected subscription
$selectedSubscription = $subscriptions.subscriptions | Where-Object { $_.name -eq $subscriptionName }
if (-not $selectedSubscription) {
    Write-Error "Subscription not found"
    exit 1
}

# Construct output JSON
$outputJson = @{
    subscription = $selectedSubscription.name
    subscription_id = $selectedSubscription.id
    resource_group = $resourceGroupName
    storage_account_name = $storageAccountName
    location = $location
    account_kind = $accountKind
    account_replication_type = $accountReplicationType
    access_tier = $accessTier
    ip_rules = $ipRules
} | ConvertTo-Json

# Create directory structure
$outputPath = Join-Path -Path $selectedSubscription.name -ChildPath $resourceGroupName
New-Item -ItemType Directory -Path $outputPath -Force | Out-Null

# Save to file
$outputJson | Out-File -FilePath (Join-Path -Path $outputPath -ChildPath "$storageAccountName.json")
Write-Host "JSON configuration file generated successfully at $outputPath\$storageAccountName.json"