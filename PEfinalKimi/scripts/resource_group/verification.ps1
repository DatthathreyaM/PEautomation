# scripts/resource_group/verification.ps1
param (
    [string]$subscriptionName,
    [string]$resourceGroupName,
    [string]$location
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

# Verify resource group doesn't already exist
$rgExists = az group exists --name $resourceGroupName
if ($rgExists -eq "true") {
    Write-Host "Resource group $resourceGroupName already exists."
    return $false
}

Write-Host "All verification checks passed."
return $true