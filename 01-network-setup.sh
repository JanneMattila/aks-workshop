#!/bin/bash

######################
#  _   _       _
# | | | |_   _| |__
# | |_| | | | | '_ \
# |  _  | |_| | |_) |
# |_| |_|\__,_|_.__/
######################

# Command: NETWORK-1
vnet_hub_id=$(az network vnet create -g $resource_group_name --name $vnet_hub_name \
  --address-prefix $vnet_hub_address_prefix \
  --query newVNet.id -o tsv)
echo $vnet_hub_id

# Command: NETWORK-2
vnet_hub_management_subnet_id=$(az network vnet subnet create -g $resource_group_name --vnet-name $vnet_hub_name \
  --name $vnet_hub_management_subnet_name --address-prefixes $vnet_hub_management_subnet_address_prefix \
  --query id -o tsv)
echo $vnet_hub_management_subnet_id

# Command: NETWORK-3
vnet_hub_bastion_subnet_id=$(az network vnet subnet create -g $resource_group_name --vnet-name $vnet_hub_name \
  --name $vnet_hub_bastion_subnet_name --address-prefixes $vnet_hub_bastion_subnet_address_prefix \
  --query id -o tsv)
echo $vnet_hub_bastion_subnet_id

# Study Hub virtual network in Portal

####################################
#  ____              _          _
# / ___| _ __   ___ | | _____  / |
# \___ \| '_ \ / _ \| |/ / _ \ | |
#  ___) | |_) | (_) |   <  __/ | |
# |____/| .__/ \___/|_|\_\___| |_|
#       |_|
####################################

# Command: NETWORK-4
vnet_spoke1_id=$(az network vnet create -g $resource_group_name --name $vnet_spoke1_name \
  --address-prefix $vnet_spoke1_address_prefix \
  --query newVNet.id -o tsv)
echo $vnet_spoke1_id

# Command: NETWORK-5
vnet_spoke1_front_subnet_id=$(az network vnet subnet create -g $resource_group_name --vnet-name $vnet_spoke1_name \
  --name $vnet_spoke1_front_subnet_name --address-prefixes $vnet_spoke1_front_subnet_address_prefix \
  --delegations "Microsoft.ContainerInstance/containerGroups" \
  --query id -o tsv)
echo $vnet_spoke1_front_subnet_id

#######################################
#  ____              _          ____
# / ___| _ __   ___ | | _____  |___ \
# \___ \| '_ \ / _ \| |/ / _ \   __) |
#  ___) | |_) | (_) |   <  __/  / __/
# |____/| .__/ \___/|_|\_\___| |_____|
#       |_|
#######################################

# Command: NETWORK-6
vnet_spoke2_id=$(az network vnet create -g $resource_group_name --name $vnet_spoke2_name \
  --address-prefix $vnet_spoke2_address_prefix \
  --query newVNet.id -o tsv)
echo $vnet_spoke2_id

# Command: NETWORK-7
vnet_spoke2_aks_subnet_id=$(az network vnet subnet create -g $resource_group_name --vnet-name $vnet_spoke2_name \
  --name $vnet_spoke2_aks_subnet_name --address-prefixes $vnet_spoke2_aks_subnet_address_prefix \
  --query id -o tsv)
echo $vnet_spoke2_aks_subnet_id

# Command: NETWORK-8
vnet_spoke2_pe_subnet_id=$(az network vnet subnet create -g $resource_group_name --vnet-name $vnet_spoke2_name \
  --name $vnet_spoke2_pe_subnet_name --address-prefixes $vnet_spoke2_pe_subnet_address_prefix \
  --query id -o tsv)
echo $vnet_spoke2_pe_subnet_id

# Command: NETWORK-9
vnet_spoke2_agic_subnet_id=$(az network vnet subnet create -g $resource_group_name --vnet-name $vnet_spoke2_name \
  --name $vnet_spoke2_agic_subnet_name --address-prefixes $vnet_spoke2_agic_subnet_address_prefix \
  --query id -o tsv)
echo $vnet_spoke2_agic_subnet_id

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
# Command: NETWORK-10
az network vnet peering create \
  --name "$vnet_hub_plain_name-to-$vnet_spoke1_plain_name" \
  --resource-group $resource_group_name \
  --vnet-name $vnet_hub_name \
  --remote-vnet $vnet_spoke1_id \
  --allow-vnet-access \
  --allow-gateway-transit

# Spoke 1 -> Hub
# Command: NETWORK-11
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
# Command: NETWORK-12
az network vnet peering create \
  --name "$vnet_hub_plain_name-to-$vnet_spoke2_plain_name" \
  --resource-group $resource_group_name \
  --vnet-name $vnet_hub_name \
  --remote-vnet $vnet_spoke2_id \
  --allow-vnet-access \
  --allow-gateway-transit

# Spoke 2 -> Hub
# Command: NETWORK-13
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

# Study virtual network setup in Portal
