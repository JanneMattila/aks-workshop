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
# Add route table to "spoke1" and prevent routing to "hub". 
# Test and verify.
#

































































































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
