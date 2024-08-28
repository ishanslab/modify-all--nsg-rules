<#
    .DESCRIPTION
        A runbook which gets all the Subnets, total IP addresses available and remaining IP addresses in each Subnet.

    .NOTES
        AUTHOR: Ishan Shukla
        LASTEDIT: Aug 28, 2024

    .PARAMETER Subid
    Subscription ID for which the Subnets will be queried. Optional, if not provided, default Subscription will be selected. 

#>

Param(
    [Parameter(Mandatory=$false)]
    [String]$Subid
)

"Please enable appropriate RBAC permissions to the system identity of this automation account. Otherwise, the runbook may fail..."

try
{
    "Logging in to Azure..."
    Connect-AzAccount -Identity
    start-sleep -seconds 30
    if($Subid -eq $null){
       $Subid =  (Get-AzContext).Subscription.id 
       Select-AzSubscription -SubscriptionId $Subid 
    }

    
}
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}




$nsgall = Get-AzNetworkSecurityGroup 
$updated = @()
$out1 = @()
foreach ($nsg1 in $nsgall) { 

    $rule2change = $nsg1.SecurityRules | Where-Object { ($_.Access -eq "Allow" -and $_.Direction -eq "Inbound") `
            -and ($_.SourceAddressPrefix -eq "Internet" -or $_.SourceAddressPrefix -eq "*" -or $_.SourceAddressPrefix -eq "0.0.0.0/0") `
            -and ($_.DestinationPortRange -eq "*" -or $_.DestinationPortRange -eq "22"  -or $_.DestinationPortRange -eq "3389") }

    foreach ($rule in $rule2change) {

$out1 += "Updated NSG: $($nsg1.name) - Rule name: $($rule.Name)" 

        Set-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg1 `
            -Name $rule.Name `
            -Access Deny `
            -Protocol $rule.Protocol `
            -Direction "Inbound" `
            -Priority $rule.Priority `
            -SourceAddressPrefix $rule.SourceAddressPrefix `
            -SourcePortRange $rule.SourcePortRange `
            -DestinationAddressPrefix $rule.DestinationAddressPrefix `
            -DestinationPortRange $rule.DestinationPortRange | out-null
    

            $updated += $nsg1 | Set-AzNetworkSecurityGroup  
            
    }
   
}

if(!($out1 )){
    Write-Output  "No NSG rules were updated"
}
Write-Output $out1 
