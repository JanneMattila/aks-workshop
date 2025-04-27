######################
#  _   _       _
# | | | |_   _| |__
# | |_| | | | | '_ \
# |  _  | |_| | |_) |
# |_| |_|\__,_|_.__/
######################

# Create hub virtual network
# Command: NETWORK-1
vnet_hub_id=$(az network vnet create -g $resource_group_name --name $vnet_hub_name \
  --address-prefix $vnet_hub_address_prefix \
  --query newVNet.id -o tsv)
store_variable "vnet_hub_id"
echo $vnet_hub_id

# Create gateway subnet
# Command: NETWORK-2
vnet_hub_gateway_subnet_id=$(az network vnet subnet create -g $resource_group_name --vnet-name $vnet_hub_name \
  --name $vnet_hub_gateway_subnet_name --address-prefixes $vnet_hub_gateway_subnet_address_prefix \
  --query id -o tsv)
echo $vnet_hub_gateway_subnet_id

# Create firewall subnet
# Command: NETWORK-3
vnet_hub_firewall_subnet_id=$(az network vnet subnet create -g $resource_group_name --vnet-name $vnet_hub_name \
  --name $vnet_hub_firewall_subnet_name --address-prefixes $vnet_hub_firewall_subnet_address_prefix \
  --query id -o tsv)
echo $vnet_hub_firewall_subnet_id

# Create infra subnet
# Command: NETWORK-4
vnet_hub_infra_subnet_id=$(az network vnet subnet create -g $resource_group_name --vnet-name $vnet_hub_name \
  --name $vnet_hub_infra_subnet_name --address-prefixes $vnet_hub_infra_subnet_address_prefix \
  --query id -o tsv)
echo $vnet_hub_infra_subnet_id

# Create management subnet
# Command: NETWORK-5
vnet_hub_management_subnet_id=$(az network vnet subnet create -g $resource_group_name --vnet-name $vnet_hub_name \
  --name $vnet_hub_management_subnet_name --address-prefixes $vnet_hub_management_subnet_address_prefix \
  --query id -o tsv)
store_variable "vnet_hub_management_subnet_id"
echo $vnet_hub_management_subnet_id

# Create bastion subnet
# Command: NETWORK-6
vnet_hub_bastion_subnet_id=$(az network vnet subnet create -g $resource_group_name --vnet-name $vnet_hub_name \
  --name $vnet_hub_bastion_subnet_name --address-prefixes $vnet_hub_bastion_subnet_address_prefix \
  --query id -o tsv)
store_variable "vnet_hub_bastion_subnet_id"
echo $vnet_hub_bastion_subnet_id

# Create user-defined route (UDR) to management subnet
# Command: NETWORK-7
az network route-table create -g $resource_group_name -n $vnet_hub_management_subnet_udr_name

# Assign user-defined route (UDR) to management subnet
# Command: NETWORK-8
az network vnet subnet update -g $resource_group_name --vnet-name $vnet_hub_name \
  --name $vnet_hub_management_subnet_name --route-table $vnet_hub_management_subnet_udr_name

# Study hub virtual network in the portal

####################################
#  ____              _          _
# / ___| _ __   ___ | | _____  / |
# \___ \| '_ \ / _ \| |/ / _ \ | |
#  ___) | |_) | (_) |   <  __/ | |
# |____/| .__/ \___/|_|\_\___| |_|
#       |_|
####################################

# Create spoke1 virtual network
# Command: NETWORK-9
vnet_spoke1_id=$(az network vnet create -g $resource_group_name --name $vnet_spoke1_name \
  --address-prefix $vnet_spoke1_address_prefix \
  --query newVNet.id -o tsv)
store_variable "vnet_spoke1_id"
echo $vnet_spoke1_id

# Create front subnet
# Command: NETWORK-10
vnet_spoke1_front_subnet_id=$(az network vnet subnet create -g $resource_group_name --vnet-name $vnet_spoke1_name \
  --name $vnet_spoke1_front_subnet_name --address-prefixes $vnet_spoke1_front_subnet_address_prefix \
  --delegations "Microsoft.ContainerInstance/containerGroups" \
  --query id -o tsv)
store_variable "vnet_spoke1_front_subnet_id"
echo $vnet_spoke1_front_subnet_id

# What is subnet delegation?
# https://learn.microsoft.com/en-us/azure/virtual-network/subnet-delegation-overview

# Create network security group (NSG) to front subnet
# Command: NETWORK-11
az network nsg create -n $vnet_spoke1_front_subnet_nsg_name -g $resource_group_name

# Assign network security group (NSG) to front subnet
# Command: NETWORK-12
az network vnet subnet update -g $resource_group_name --vnet-name $vnet_spoke1_name \
  --name $vnet_spoke1_front_subnet_name --network-security-group $vnet_spoke1_front_subnet_nsg_name

#######################################
#  ____              _          ____
# / ___| _ __   ___ | | _____  |___ \
# \___ \| '_ \ / _ \| |/ / _ \   __) |
#  ___) | |_) | (_) |   <  __/  / __/
# |____/| .__/ \___/|_|\_\___| |_____|
#       |_|
#######################################

# Create spoke2 virtual network
# Command: NETWORK-13
vnet_spoke2_id=$(az network vnet create -g $resource_group_name --name $vnet_spoke2_name \
  --address-prefix $vnet_spoke2_address_prefix \
  --query newVNet.id -o tsv)
store_variable "vnet_spoke2_id"
echo $vnet_spoke2_id

# Create aks subnet
# Command: NETWORK-14
# https://learn.microsoft.com/en-us/azure/virtual-network/virtual-network-service-endpoints-overview#key-benefits
# "Service endpoint routes override any BGP or UDR routes for the address prefix match of an Azure service"
vnet_spoke2_aks_subnet_id=$(az network vnet subnet create -g $resource_group_name --vnet-name $vnet_spoke2_name \
  --name $vnet_spoke2_aks_subnet_name --address-prefixes $vnet_spoke2_aks_subnet_address_prefix \
  --service-endpoints Microsoft.Storage Microsoft.Sql \
  --query id -o tsv)
store_variable "vnet_spoke2_aks_subnet_id"
echo $vnet_spoke2_aks_subnet_id

# Create pe subnet for private endpoints
# Command: NETWORK-15
vnet_spoke2_pe_subnet_id=$(az network vnet subnet create -g $resource_group_name --vnet-name $vnet_spoke2_name \
  --name $vnet_spoke2_pe_subnet_name --address-prefixes $vnet_spoke2_pe_subnet_address_prefix \
  --query id -o tsv)
store_variable "vnet_spoke2_pe_subnet_id"
echo $vnet_spoke2_pe_subnet_id

# Create Application Gateway Ingress Controller (AGIC) subnet
# Command: NETWORK-16
vnet_spoke2_agic_subnet_id=$(az network vnet subnet create -g $resource_group_name --vnet-name $vnet_spoke2_name \
  --name $vnet_spoke2_agic_subnet_name --address-prefixes $vnet_spoke2_agic_subnet_address_prefix \
  --query id -o tsv)
store_variable "vnet_spoke2_agic_subnet_id"
echo $vnet_spoke2_agic_subnet_id

# Create Application Gateway for Containers (AGC) subnet
# Command: NETWORK-17
vnet_spoke2_agc_subnet_id=$(az network vnet subnet create -g $resource_group_name --vnet-name $vnet_spoke2_name \
  --name $vnet_spoke2_agc_subnet_name --address-prefixes $vnet_spoke2_agc_subnet_address_prefix \
  --delegations "Microsoft.ServiceNetworking/trafficControllers" \
  --query id -o tsv)
store_variable "vnet_spoke2_agc_subnet_id"
echo $vnet_spoke2_agc_subnet_id

# Study virtual networks in the portal

# QUESTION:
# ---------
# Is there connectivity between created virtual networks?
#

#######################################
#  ____                _
# |  _ \ ___  ___ _ __(_)_ __   __ _
# | |_) / _ \/ _ \ '__| | '_ \ / _` |
# |  __/  __/  __/ |  | | | | | (_| |
# |_|   \___|\___|_|  |_|_| |_|\__, |
#                              |___/
#######################################

# Understand the configuration!
az network vnet peering create --help

# QUESTION:
# ---------
# What are these parameters?
#  --allow-vnet-access 
#  --allow-gateway-transit
#  --use-remote-gateways
#

# Hub -> Spoke 1
# Command: NETWORK-18
az network vnet peering create \
  --name "$vnet_hub_plain_name-to-$vnet_spoke1_plain_name" \
  --resource-group $resource_group_name \
  --vnet-name $vnet_hub_name \
  --remote-vnet $vnet_spoke1_id \
  --allow-vnet-access \
  --allow-gateway-transit

# Spoke 1 -> Hub
# Command: NETWORK-19
az network vnet peering create \
  --name "$vnet_spoke1_plain_name-to-$vnet_hub_plain_name" \
  --resource-group $resource_group_name \
  --vnet-name $vnet_spoke1_name \
  --remote-vnet $vnet_hub_id \
  --allow-vnet-access \
  --allow-forwarded-traffic
  # --use-remote-gateways

# ---

# Hub -> Spoke 2
# Command: NETWORK-20
az network vnet peering create \
  --name "$vnet_hub_plain_name-to-$vnet_spoke2_plain_name" \
  --resource-group $resource_group_name \
  --vnet-name $vnet_hub_name \
  --remote-vnet $vnet_spoke2_id \
  --allow-vnet-access \
  --allow-gateway-transit

# Spoke 2 -> Hub
# Command: NETWORK-21
az network vnet peering create \
  --name "$vnet_spoke2_plain_name-to-$vnet_hub_plain_name" \
  --resource-group $resource_group_name \
  --vnet-name $vnet_spoke2_name \
  --remote-vnet $vnet_hub_id \
  --allow-vnet-access \
  --allow-forwarded-traffic
  # --use-remote-gateways

# QUESTION:
# ---------
# Can "spoke1" and "spoke2" communicate with each other?
#
# See "50-advanced-networking.sh" more more details.
#

# Study peering setup in the portal
