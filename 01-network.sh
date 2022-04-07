#!/bin/bash

######################
#  _   _       _
# | | | |_   _| |__
# | |_| | | | | '_ \
# |  _  | |_| | |_) |
# |_| |_|\__,_|_.__/
######################

vnet_hub_id=$(az network vnet create -g $resource_group_name --name $vnet_hub_name \
  --address-prefix $vnet_hub_address_prefix \
  --query newVNet.id -o tsv)
echo $vnet_hub_id

vnet_hub_management_subnet_id=$(az network vnet subnet create -g $resource_group_name --vnet-name $vnet_hub_name \
  --name $vnet_hub_management_subnet_name --address-prefixes $vnet_hub_management_subnet_address_prefix \
  --query id -o tsv)
echo $vnet_hub_management_subnet_id

vnet_hub_bastion_subnet_id=$(az network vnet subnet create -g $resource_group_name --vnet-name $vnet_hub_name \
  --name $vnet_hub_bastion_subnet_name --address-prefixes $vnet_hub_bastion_subnet_address_prefix \
  --query id -o tsv)
echo $vnet_hub_bastion_subnet_id

####################################
#  ____              _          _
# / ___| _ __   ___ | | _____  / |
# \___ \| '_ \ / _ \| |/ / _ \ | |
#  ___) | |_) | (_) |   <  __/ | |
# |____/| .__/ \___/|_|\_\___| |_|
#       |_|
####################################

vnet_spoke1_id=$(az network vnet create -g $resource_group_name --name $vnet_spoke1_name \
  --address-prefix $vnet_spoke1_address_prefix \
  --query newVNet.id -o tsv)
echo $vnet_spoke1_id

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

vnet_spoke2_id=$(az network vnet create -g $resource_group_name --name $vnet_spoke2_name \
  --address-prefix $vnet_spoke2_address_prefix \
  --query newVNet.id -o tsv)
echo $vnet_spoke2_id

vnet_spoke2_aks_subnet_id=$(az network vnet subnet create -g $resource_group_name --vnet-name $vnet_spoke2_name \
  --name $vnet_spoke2_aks_subnet_name --address-prefixes $vnet_spoke2_aks_subnet_address_prefix \
  --query id -o tsv)
echo $vnet_spoke2_aks_subnet_id

#######################################
#  ____                _
# |  _ \ ___  ___ _ __(_)_ __   __ _
# | |_) / _ \/ _ \ '__| | '_ \ / _` |
# |  __/  __/  __/ |  | | | | | (_| |
# |_|   \___|\___|_|  |_|_| |_|\__, |
#                              |___/
#######################################

