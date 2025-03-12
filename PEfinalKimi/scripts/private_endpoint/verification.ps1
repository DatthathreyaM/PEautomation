param (
    [string]$subscriptionName,
    [string]$resourceGroupName,
    [string]$vnetName,
    [string]$subnetName,
    [string]$resourceType,
    [string]$subResourceName,
    [string]$resourceName
)

# Load subscription data
$subscriptions = Get-Content -Path "subscriptions.json" | ConvertFrom-Json
$selectedSubscription = $subscriptions.subscriptions | Where-Object { $_.name -eq $subscriptionName }

# Function to check subnet delegation
function Test-SubnetDelegation {
    param (
        [string]$resourceGroupName,
        [string]$vnetName,
        [string]$subnetName,
        [string]$requiredDelegation
    )

    $subnet = az network vnet subnet show --resource-group $resourceGroupName --vnet-name $vnetName --name $subnetName | ConvertFrom-Json
    $delegations = $subnet.delegations | ForEach-Object { $_.serviceName }
    
    if ($delegations -contains $requiredDelegation) {
        Write-Host "Subnet delegation check passed."
        return $true
    } else {
        Write-Host "Subnet delegation check failed. Required delegation: $requiredDelegation"
        return $false
    }
}

# Function to check available IPs in subnet
function Test-FreeIpsInSubnet {
    param (
        [string]$resourceGroupName,
        [string]$vnetName,
        [string]$subnetName,
        [int]$requiredIps = 1
    )

    $subnet = az network vnet subnet show --resource-group $resourceGroupName --vnet-name $vnetName --name $subnetName | ConvertFrom-Json
    $addressPrefix = $subnet.addressPrefix
    $usedIps = $subnet.ipConfigurations | ForEach-Object { $_.properties.privateIPAddress }

    $startIp = [System.Net.IPAddress]::Parse($addressPrefix.Split('/')[0])
    $endIp = Get-NextIp -startIp $startIp.GetAddressBytes() -count ($addressPrefix.Split('/')[1] - 2)
    
    $availableIps = @()
    for ($ip = $startIp; $ip.GetAddressBytes() -le $endIp; $ip = Get-NextIp -startIp $ip.GetAddressBytes()) {
        if (-not ($usedIps -contains $ip.ToString())) {
            $availableIps += $ip.ToString()
        }
    }

    if ($availableIps.Count -ge $requiredIps) {
        Write-Host "Free IPs check passed. Available IPs: $($availableIps.Count)"
        return $true
    } else {
        Write-Host "Free IPs check failed. Required: $requiredIps, Available: $($availableIps.Count)"
        return $false
    }
}

# Function to verify subresource exists
function Test-Subresource {
    param (
        [string]$resourceId,
        [string]$subResourceName
    )

    $resource = az resource show --id $resourceId --api-version 2021-04-01 | ConvertFrom-Json
    $subresources = $resource.properties | Get-Member -MemberType NoteProperty | ForEach-Object { $_.Name }
    
    if ($subresources -contains $subResourceName) {
        Write-Host "Subresource verification passed."
        return $true
    } else {
        Write-Host "Subresource verification failed. Subresource $subResourceName not found."
        return $false
    }
}

# Function to check private DNS zone allocation
function Test-PrivateDnsZone {
    param (
        [string]$dnsZoneName,
        [string]$resourceGroupName
    )

    $dnsZone = az network private-dns zone show --name $dnsZoneName --resource-group $resourceGroupName --query "[].name" -o tsv
    if ($dnsZone -eq $dnsZoneName) {
        Write-Host "Private DNS zone verification passed."
        return $true
    } else {
        Write-Host "Private DNS zone verification failed. Zone $dnsZoneName not found."
        return $false
    }
}

# Main verification function
function Invoke-Verification {
    param (
        [string]$subscriptionName,
        [string]$resourceGroupName,
        [string]$vnetName,
        [string]$subnetName,
        [string]$resourceType,
        [string]$subResourceName,
        [string]$resourceName
    )

    # Set required delegation based on resource type
    $requiredDelegation = switch ($resourceType) {
        "Storage Account" { "Microsoft.Storage/privateEndpoints" }
        "Cosmos DB" { "Microsoft.DocumentDB/privateEndpoints" }
        "Key Vault" { "Microsoft.KeyVault/privateEndpoints" }
        "SQL" { "Microsoft.Sql/privateEndpoints" }
        default { "Microsoft.Network/privateEndpoints" }
    }

    # Check subnet delegation
    if (-not (Test-SubnetDelegation -resourceGroupName $resourceGroupName -vnetName $vnetName -subnetName $subnetName -requiredDelegation $requiredDelegation)) {
        return $false
    }

    # Check available IPs
    $requiredIps = if ($resourceType -eq "Cosmos DB") { 2 } else { 1 }
    if (-not (Test-FreeIpsInSubnet -resourceGroupName $resourceGroupName -vnetName $vnetName -subnetName $subnetName -requiredIps $requiredIps)) {
        return $false
    }

    # Verify subresource
    $resourceId = "/subscriptions/$($selectedSubscription.id)/resourceGroups/$resourceGroupName/providers/Microsoft.$($resourceType)/$resourceName"
    if (-not (Test-Subresource -resourceId $resourceId -subResourceName $subResourceName)) {
        return $false
    }

    # Verify private DNS zone
    $dnsZoneMapping = @{
        "Storage Account" = @{
            "Blob" = "privatelink.blob.core.windows.net"
            "File" = "privatelink.file.core.windows.net"
            "Queue" = "privatelink.queue.core.windows.net"
            "Table" = "privatelink.table.core.windows.net"
            "Web" = "privatelink.web.core.windows.net"
            "Dfs" = "privatelink.dfs.core.windows.net"
        }
        "Cosmos DB" = @{
            "Sql" = "privatelink.documents.azure.com"
            "Mongodb" = "privatelink.mongo.cosmos.azure.com"
        }
        "Key Vault" = @{
            "Vault" = "privatelink.vaultcore.azure.net"
        }
        "SQL" = @{
            default = "privatelink.database.windows.net"
        }
        "Data Factory" = @{
            default = "privatelink.datafactory.azure.com"
        }
        "Search Service" = @{
            default = "privatelink.search.windows.net"
        }
    }

    $dnsZoneName = $dnsZoneMapping[$resourceType][$subResourceName]
    if (-not $dnsZoneName) {
        $dnsZoneName = $dnsZoneMapping[$resourceType]["default"]
    }

    $dnsZoneSubscription = $subscriptions.subscriptions | Where-Object { $_.name -eq "Azure-p-1" }
    $privateDnsZone = $dnsZoneSubscription.dnsZones | Where-Object { $_.name -eq $dnsZoneName }

    if (-not (Test-PrivateDnsZone -dnsZoneName $dnsZoneName -resourceGroupName $privateDnsZone.resource_group)) {
        return $false
    }

    Write-Host "All verification checks passed."
    return $true
}

# Execute verification
$result = Invoke-Verification -subscriptionName $subscriptionName -resourceGroupName $resourceGroupName -vnetName $vnetName -subnetName $subnetName -resourceType $resourceType -subResourceName $subResourceName -resourceName $resourceName

if (-not $result) {
    exit 1
}