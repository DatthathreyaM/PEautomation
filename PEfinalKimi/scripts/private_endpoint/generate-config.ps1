# scripts/private_endpoint/generate-config.ps1
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

# Find selected subscription
$selectedSubscription = $subscriptions.subscriptions | Where-Object { $_.name -eq $subscriptionName }
if (-not $selectedSubscription) {
    Write-Error "Subscription not found"
    exit 1
}

# Find VNet
$vnet = $selectedSubscription.vnets | Where-Object { $_.name -eq $vnetName }
if (-not $vnet) {
    Write-Error "VNet not found"
    exit 1
}

# Mapping of resource types and subresources to DNS zones
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
        default = "privatelink.database.net.windows"
    }
    "Data Factory" = @{
        default = "privatelink.datafactory.azure.com"
    }
    "Search Service" = @{
        default = "privatelink.search.windows.net"
    }
}

# Determine private DNS zone name
$dnsZoneName = $dnsZoneMapping[$resourceType][$subResourceName]
if (-not $dnsZoneName) {
    $dnsZoneName = $dnsZoneMapping[$resourceType]["default"]
    if (-not $dnsZoneName) {
        throw "No DNS zone found for resource type $resourceType and subresource $subResourceName"
    }
}

# Find private DNS zone
$dnsZoneSubscription = $subscriptions.subscriptions | Where-Object { $_.name -eq "Azure-p-1" }
$privateDnsZone = $dnsZoneSubscription.dnsZones | Where-Object { $_.name -eq $dnsZoneName }
if (-not $privateDnsZone) {
    Write-Error "Private DNS Zone not found"
    exit 1
}

# Get subnet details from Azure
$subnetId = "/subscriptions/$($selectedSubscription.id)/resourceGroups/$($vnet.resource_group)/providers/Microsoft.Network/virtualNetworks/$($vnet.name)/subnets/$subnetName"
$subnet = Get-AzVirtualNetworkSubnetConfig -ResourceId $subnetId

# Function to find free IPs in subnet
function Get-FreeIps {
    param (
        [Microsoft.Azure.Commands.Network.Models.PSVirtualNetworkSubnet]$subnet,
        [int]$count = 1
    )

    $ipList = @()
    $addressPrefix = $subnet.AddressPrefix
    $startIp = [System.Net.IPAddress]::Parse($addressPrefix.Split('/')[0]).GetAddressBytes()
    $prefixLength = [int]$addressPrefix.Split('/')[1]
    $endIp = [System.Net.IPAddress]::Parse((Get-NextIp -startIp $startIp -count ($subnet.AddressPrefix.Split('/')[1] - 2))).GetAddressBytes()
    $usedIps = $subnet.IpConfigurations | ForEach-Object { [System.Net.IPAddress]::Parse($_.PrivateIpAddress).GetAddressBytes() }

    for ($i = 0; $i -lt $count; $i++) {
        $currentIp = $null
        for ($ip = [System.Net.IPAddress]::Parse($subnet.AddressPrefix.Split('/')[0]); $ip.GetAddressBytes() -le $endIp; $ip = Get-NextIp -startIp $ip.GetAddressBytes()) {
            if (-not ($usedIps -contains $ip.GetAddressBytes())) {
                $currentIp = $ip.ToString()
                break
            }
        }
        if (-not $currentIp) {
            throw "No free IP addresses available in subnet"
        }
        $ipList += $currentIp
        $usedIps += [System.Net.IPAddress]::Parse($currentIp).GetAddressBytes()
    }

    return $ipList
}

# Function to get next IP address
function Get-NextIp {
    param (
        [byte[]]$startIp
    )

    $ip = [System.Net.IPAddress]::new([int[]]($startIp[3], $startIp[2], $startIp[1], $startIp[0])).GetAddressBytes()
    $ip[3]++
    if ($ip[3] -gt 255) {
        $ip[3] = 0
        $ip[2]++
        if ($ip[2] -gt 255) {
            $ip[2] = 0
            $ip[1]++
            if ($ip[1] -gt 255) {
                $ip[1] = 0
                $ip[0]++
            }
        }
    }
    return [System.Net.IPAddress]::new([int[]]($ip[3], $ip[2], $ip[1], $ip[0])).ToString()
}

# Determine static IPs
if ($resourceType -eq "Cosmos DB") {
    $staticIps = Get-FreeIps -subnet $subnet -count 2
} else {
    $staticIps = Get-FreeIps -subnet $subnet -count 1
}

# Get resource location
$resourceId = "/subscriptions/$($selectedSubscription.id)/resourceGroups/$resourceGroupName/providers/Microsoft.$($resourceType)/$resourceName"
$resource = Get-AzResource -ResourceId $resourceId
$location = $resource.Location

# Construct output JSON
$outputJson = @{
    subscription = $selectedSubscription.name
    subscription_id = $selectedSubscription.id
    resource_group = $resourceGroupName
    resource_group_id = "/subscriptions/$($selectedSubscription.id)/resourceGroups/$resourceGroupName"
    vnet_name = $vnet.name
    subnet_name = $subnetName
    subnet_id = $subnetId
    resource_type = $resourceType
    subresource_name = $subResourceName
    resource_name = $resourceName
    resource_id = $resourceId
    private_dns_zone_id = "/subscriptions/$($dnsZoneSubscription.id)/resourceGroups/$($privateDnsZone.resource_group)/providers/Microsoft.Network/privateDnsZones/$($privateDnsZone.name)"
    static_ips = $staticIps
    location = $location
} | ConvertTo-Json

# Create directory structure
$outputPath = Join-Path -Path $selectedSubscription.name -ChildPath $resourceGroupName
New-Item -ItemType Directory -Path $outputPath -Force | Out-Null

# Save to file
$outputJson | Out-File -FilePath (Join-Path -Path $outputPath -ChildPath "$resourceName.json")
Write-Host "JSON configuration file generated successfully at $outputPath\$resourceName.json"