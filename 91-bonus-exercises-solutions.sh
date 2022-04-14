#!/bin/bash

#################################
#  ____
# | __ )  ___  _ __  _   _ ___
# |  _ \ / _ \| '_ \| | | / __|
# | |_) | (_) | | | | |_| \__ \
# |____/ \___/|_| |_|\__,_|___/
#            _       _   _
#  ___  ___ | |_   _| |_(_) ___  _ __  ___
# / __|/ _ \| | | | | __| |/ _ \| '_ \/ __|
# \__ \ (_) | | |_| | |_| | (_) | | | \__ \
# |___/\___/|_|\__,_|\__|_|\___/|_| |_|___/
# 
# below but try not to cheat!
#################################























































































































































































# Exercise 1:
# -----------
# Block traffic for port 80 to spoke1. 
# Test and verify.
# (Remove block after testing)
#

az network nsg rule create \
  -g $resource_group_name \
  --nsg-name $vnet_spoke1_front_subnet_nsg_name \
  -n "rule1" --priority 1000 \
  --source-address-prefixes '*' \
  --destination-address-prefixes $vnet_spoke1_front_subnet_address_prefix \
  --destination-port-ranges '80' \
  --access Deny \
  --description "Deny access to port 80"






















































































# Exercise 2:
# -----------
# Add route table to "hub" and prevent routing to internet. 
# Test and verify.
#

az network route-table route create \
  -g $resource_group_name \
  --route-table-name $vnet_hub_management_subnet_udr_name \
  -n "default" \
  --next-hop-type None \
  --address-prefix 0.0.0.0/0





























































































# Exercise 3:
# -----------
# Peer spoke1 and spoke2. 
# Test and verify.
# (Remove peering after testing)
#

# Spoke 1 -> Spoke 2
# Command: BONUS3-1
az network vnet peering create \
  --name "$vnet_spoke1_plain_name-to-$vnet_spoke2_plain_name" \
  --resource-group $resource_group_name \
  --vnet-name $vnet_spoke1_name \
  --remote-vnet $vnet_spoke2_id \
  --allow-vnet-access

# Spoke 2 -> Spoke 1
# Command: BONUS3-2
az network vnet peering create \
  --name "$vnet_spoke2_plain_name-to-$vnet_spoke1_plain_name" \
  --resource-group $resource_group_name \
  --vnet-name $vnet_spoke2_name \
  --remote-vnet $vnet_spoke1_id \
  --allow-vnet-access

# Test connectivity between spokes "03-networking-tests.sh".

# Remove peerings
# Command: BONUS3-3
az network vnet peering delete \
  --name "$vnet_spoke1_plain_name-to-$vnet_spoke2_plain_name" \
  --resource-group $resource_group_name \
  --vnet-name $vnet_spoke1_name

az network vnet peering delete \
  --name "$vnet_spoke2_plain_name-to-$vnet_spoke1_plain_name" \
  --resource-group $resource_group_name \
  --vnet-name $vnet_spoke2_name

# End of Exercise 3.
