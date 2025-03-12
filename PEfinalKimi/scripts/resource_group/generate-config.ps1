# scripts/resource_group/generate-config.ps1
param (
    [string]$subscriptionName,
    [string]$resourceGroupName,
    [string]$location
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
    location = $location
} | ConvertTo-Json

# Create directory structure
$outputPath = Join-Path -Path $selectedSubscription.name -ChildPath $resourceGroupName
New-Item -ItemType Directory -Path $outputPath -Force | Out-Null

# Save to file
$outputJson | Out-File -FilePath (Join-Path -Path $outputPath -ChildPath "$resourceGroupName.json")
Write-Host "JSON configuration file generated successfully at $outputPath\$resourceGroupName.json"