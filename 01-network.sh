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
  --delegations "Microsoft.ContainerInstance/containerGroups" \
  --query id -o tsv)
echo $vnet_hub_management_subnet_id

vnet_hub_bastion_subnet_id=$(az network vnet subnet create -g $resource_group_name --vnet-name $vnet_hub_name \
  --name $vnet_hub_bastion_subnet_name --address-prefixes $vnet_hub_bastion_subnet_address_prefix \
  --query id -o tsv)
echo $vnet_hub_bastion_subnet_id
