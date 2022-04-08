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

vnet_hub_plain_name="hub"
vnet_hub_name="vnet-$vnet_hub_plain_name"
vnet_hub_address_prefix="10.0.0.0/21"
vnet_hub_gateway_subnet_name="GatewaySubnet"
vnet_hub_gateway_subnet_address_prefix="10.0.0.0/24"
vnet_hub_firewall_subnet_name="AzureFirewallSubnet" # Azure Firewall (Optional)
vnet_hub_firewall_subnet_address_prefix="10.0.1.0/24"
vnet_hub_infra_subnet_name="snet-infra" # For intrastructure resources e.g., DCs
vnet_hub_infra_subnet_address_prefix="10.0.2.0/24"
vnet_hub_management_subnet_name="snet-management"
vnet_hub_management_subnet_address_prefix="10.0.3.0/24"
vnet_hub_bastion_subnet_name="AzureBastionSubnet"
vnet_hub_bastion_subnet_address_prefix="10.0.4.0/24"

vnet_spoke1_plain_name="spoke1"
vnet_spoke1_name="vnet-$vnet_spoke1_plain_name"
vnet_spoke1_address_prefix="10.1.0.0/22"
vnet_spoke1_front_subnet_name="snet-front"
vnet_spoke1_front_subnet_address_prefix="10.1.0.0/24"

vnet_spoke2_plain_name="spoke2"
vnet_spoke2_name="vnet-$vnet_spoke2_plain_name"
vnet_spoke2_address_prefix="10.2.0.0/22"
vnet_spoke2_aks_subnet_name="snet-aks"
vnet_spoke2_aks_subnet_address_prefix="10.2.0.0/24"

#######################
# __   ___ __ ___
# \ \ / / '_ ` _ \
#  \ V /| | | | | |
#   \_/ |_| |_| |_|
# Virtual Machine vars
#######################

vm_name="jumpbox"

vm_username="azureuser"
vm_password=$(openssl rand -base64 32)
echo $vm_password

bastion_public_ip="pip-bastion"
bastion_name="bas-management"

# Login and set correct context
# NOTE: You can skip if using cloud shell
# Command: VAR-1
az login -o table --only-show-errors
az account set --subscription $subscription_name -o table

# Create resource group
# Command: VAR-2
az group create -l $location -n $resource_group_name -o table

# Prepare extensions and providers
# Command: VAR-3
az extension add --upgrade --yes --name aks-preview
az extension add --upgrade --yes --name ssh
