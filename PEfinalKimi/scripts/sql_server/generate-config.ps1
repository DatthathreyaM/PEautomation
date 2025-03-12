# scripts/sql_server/generate-config.ps1
param (
    [string]$subscriptionName,
    [string]$resourceGroupName,
    [string]$sqlServerName,
    [string]$location,
    [string]$administratorLogin,
    [string]$administratorPassword,
    [string]$version,
    [string]$storageSize
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
    sql_server_name = $sqlServerName
    location = $location
    administrator_login = $administratorLogin
    administrator_password = $administratorPassword
    version = $version
    storage_size = $storageSize
} | ConvertTo-Json

# Create directory structure
$outputPath = Join-Path -Path $selectedSubscription.name -ChildPath $resourceGroupName
New-Item -ItemType Directory -Path $outputPath -Force | Out-Null

# Save to file
$outputJson | Out-File -FilePath (Join-Path -Path $outputPath -ChildPath "$sqlServerName.json")
Write-Host "JSON configuration file generated successfully at $outputPath\$sqlServerName.json"