#!/bin/bash

###############################################
# __     __         _       _     _
# \ \   / /_ _ _ __(_) __ _| |__ | | ___  ___
#  \ \ / / _` | '__| |/ _` | '_ \| |/ _ \/ __|
#   \ V / (_| | |  | | (_| | |_) | |  __/\__ \
#    \_/ \__,_|_|  |_|\__,_|_.__/|_|\___||___/
#     for the deployment
###############################################
my_name="janne" # Lower caps!

# Your subscription name
subscription_name="AzureDev"

# Azure AD Group name used for AKS admins
azure_ad_admin_group_contains="janne''s"

aks_name="aks$my_name"
resource_group_name="rg-aks-workshop-$my_name"

# Azure region to use
location="swedencentral"

#########################
#                   _
# __   ___ __   ___| |_
# \ \ / / '_ \ / _ \ __|
#  \ V /| | | |  __/ |_
#   \_/ |_| |_|\___|\__|
# Virtual Networks vars
#########################

vnet_hub_name="hub-vnet"
vnet_hub_address_prefix="10.0.0.0/21"
vnet_hub_management_subnet_name="snet-management"
vnet_hub_management_subnet_address_prefix="10.0.3.0/24"
vnet_hub_bastion_subnet_name="AzureBastionSubnet"
vnet_hub_bastion_subnet_address_prefix="10.0.4.0/24"

vnet_spoke1_name="vnet-spoke1"
vnet_spoke1_address_prefix="10.1.0.0/22"
vnet_spoke1_front_subnet_name="snet-front"
vnet_spoke1_front_subnet_address_prefix="10.1.0.0/24"

vnet_spoke2_name="vnet-spoke2"
vnet_spoke2_address_prefix="10.2.0.0/22"
vnet_spoke2_front_subnet_name="snet-aks"
vnet_spoke2_front_subnet_address_prefix="10.2.0.0/24"

# Login and set correct context
# Note: You can skip if using cloud shell
# Command: VAR-1
az login -o table 
az account set --subscription $subscription_name -o table

# Create resource group
# Command: VAR-2
az group create -l $location -n $resource_group_name -o table

# Prepare extensions and providers
# Command: VAR-3
az extension add --upgrade --yes --name aks-preview
