# In order to have spoke-to-spoke connectivity, you need:
# 1. Router / Virtual appliance / Firewall
#    - We'll use our jumpbox as router
# 2. Spoke1 UDR to point to hub
# 3. Spoke2 UDR to point to hub

#
# Enable jumpbox to be router
# https://github.com/dmauser/AzureVM-Router
#
# Route traffic between spoke1 and spoke2 using this router.
#
# More information here:
# https://learn.microsoft.com/en-us/azure/virtual-network/virtual-networks-udr-overview
# https://learn.microsoft.com/en-us/azure/virtual-network/tutorial-create-route-table-portal

# Enable IP Forwarding for nic of jumpbox vm
# Command: ADVANCED-NETWORKING-1
az network nic update --name jumpboxVMNic --resource-group $resource_group_name	--ip-forwarding true
vm_private_ip=$(az network nic show --name jumpboxVMNic --resource-group $resource_group_name --query ipConfigurations[0].privateIpAddress -o tsv)
store_variable "vm_private_ip"
echo $vm_private_ip

# Create user-defined route (UDR) to front subnet
# Command: ADVANCED-NETWORKING-2
az network route-table create -g $resource_group_name -n $vnet_spoke1_front_subnet_udr_name

# Assign user-defined route (UDR) to front subnet
# Command: ADVANCED-NETWORKING-3
az network vnet subnet update -g $resource_group_name --vnet-name $vnet_spoke1_name \
  --name $vnet_spoke1_front_subnet_name --route-table $vnet_spoke1_front_subnet_udr_name

# Create route to our jumpbox vm for addresses in spoke2 address range
# Command: ADVANCED-NETWORKING-4
az network route-table route create \
  -g $resource_group_name \
  --route-table-name $vnet_spoke1_front_subnet_udr_name \
  -n "to-spoke2" \
  --next-hop-type VirtualAppliance \
  --address-prefix $vnet_spoke2_address_prefix \
  --next-hop-ip-address $vm_private_ip

# Create user-defined route (UDR) to aks subnet
# Command: ADVANCED-NETWORKING-5
az network route-table create -g $resource_group_name -n $vnet_spoke2_aks_subnet_udr_name

# Assign user-defined route (UDR) to aks subnet
# Command: ADVANCED-NETWORKING-6
az network vnet subnet update -g $resource_group_name --vnet-name $vnet_spoke2_name \
  --name $vnet_spoke2_aks_subnet_name --route-table $vnet_spoke2_aks_subnet_udr_name

# Create route to our jumpbox vm for addresses in spoke2 address range
# Command: ADVANCED-NETWORKING-7
az network route-table route create \
  -g $resource_group_name \
  --route-table-name $vnet_spoke2_aks_subnet_udr_name \
  -n "to-spoke1" \
  --next-hop-type VirtualAppliance \
  --address-prefix $vnet_spoke1_address_prefix \
  --next-hop-ip-address $vm_private_ip

#
# Verify!
#
# Use Bastion to connect to jumpbox and these should now work:
# --->
# Test spoke001 -> spoke002 connectivity
# Command: NETWORK-TESTING-4
curl -X POST --data  "HTTP GET \"http://$network_app_internal_svc_ip\"" -H "Content-Type: text/plain" "$aci_ip/api/commands" # Timeout
# -> Start: HTTP GET "http://10.2.0.4"
# -> Hello there!
# <- End: HTTP GET "http://10.2.0.4" 5.51ms

# Test spoke002 -> spoke001 connectivity
curl -X POST --data  "HTTP GET \"http://$aci_ip\"" -H "Content-Type: text/plain" "$network_app_internal_svc_ip/api/commands" # Timeout
# -> Start: HTTP GET "http://10.1.0.4"
# -> Hello there!
# <- End: HTTP GET "http://10.1.0.4" 5.39ms
# <---

# In case of issues you can use NSG Flow logs to study the traffic
#
# More information here:
# https://learn.microsoft.com/en-us/azure/network-watcher/network-watcher-nsg-flow-logging-overview
#
