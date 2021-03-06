#!/bin/bash

# Helper functions
function store_variable()
{
    local var_name="$1"
    local var_value=$(echo "${!var_name}")
    echo "${var_name}=$var_value" >> saved_variables.sh
}

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

resource_group_name="rg-aks-workshop-$my_name"

# Azure region to use
location="westcentralus"

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
vnet_hub_management_subnet_udr_name="udr-$vnet_hub_plain_name-management"
vnet_hub_bastion_subnet_name="AzureBastionSubnet"
vnet_hub_bastion_subnet_address_prefix="10.0.4.0/24"

vnet_spoke1_plain_name="spoke1"
vnet_spoke1_name="vnet-$vnet_spoke1_plain_name"
vnet_spoke1_address_prefix="10.1.0.0/22"
vnet_spoke1_front_subnet_name="snet-front"
vnet_spoke1_front_subnet_nsg_name="nsg-$vnet_spoke1_plain_name-front"
vnet_spoke1_front_subnet_udr_name="udr-$vnet_spoke1_plain_name-front"
vnet_spoke1_front_subnet_address_prefix="10.1.0.0/24"

vnet_spoke2_plain_name="spoke2"
vnet_spoke2_name="vnet-$vnet_spoke2_plain_name"
vnet_spoke2_address_prefix="10.2.0.0/22"
vnet_spoke2_aks_subnet_name="snet-aks"
vnet_spoke2_aks_subnet_address_prefix="10.2.0.0/24"
vnet_spoke2_aks_subnet_udr_name="udr-$vnet_spoke2_plain_name-aks"
vnet_spoke2_agic_subnet_name="snet-agic"
vnet_spoke2_agic_subnet_address_prefix="10.2.1.0/24"
vnet_spoke2_pe_subnet_name="snet-pe"
vnet_spoke2_pe_subnet_address_prefix="10.2.2.0/24"

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

bastion_public_ip="pip-bastion"
bastion_name="bas-management"

#################################
#     _     ____  ___
#    / \   / ___||_ _|
#   / _ \ | |     | |
#  / ___ \| |___  | |
# /_/   \_\\____||___|
# Azure Container Instances vars
#################################

aci_name="ci-$vnet_spoke1_plain_name"

################################
#     _     _  __ ____
#    / \   | |/ // ___|
#   / _ \  | ' / \___ \
#  / ___ \ | . \  ___) |
# /_/   \_\|_|\_\|____/
# Azure Kubernetes Service vars
################################

# Azure AD Group name used for AKS admins
aks_azure_ad_admin_group_contains="janne''s"

# AKS specific
aks_name="aks-$my_name"
aks_workspace_name="log-$my_name"
aks_cluster_identity_name="id-$my_name-cluster"
aks_kubelet_identity_name="id-$my_name-kubelet"

aks_nodepool1="nodepool1"
aks_nodepool2="nodepool2"

# Additional resources used by AKS
unique_id=$(date +%s)
acr_name="cr${my_name}${unique_id}"
storage_name="st${my_name}${unique_id}"
storage_share_name="nfs"
agic_name="agw-aks"

###############################
#  ____
# / ___|   __ _ __   __ ___
# \___ \  / _` |\ \ / // _ \
#  ___) || (_| | \ V /|  __/
# |____/  \__,_|  \_/  \___|
# state to file
###############################

store_variable my_name
store_variable subscription_name
store_variable resource_group_name
store_variable location
store_variable vnet_hub_plain_name
store_variable vnet_hub_name
store_variable vnet_hub_address_prefix
store_variable vnet_hub_gateway_subnet_name
store_variable vnet_hub_gateway_subnet_address_prefix
store_variable vnet_hub_firewall_subnet_name
store_variable vnet_hub_firewall_subnet_address_prefix
store_variable vnet_hub_infra_subnet_name
store_variable vnet_hub_infra_subnet_address_prefix
store_variable vnet_hub_management_subnet_name
store_variable vnet_hub_management_subnet_address_prefix
store_variable vnet_hub_management_subnet_udr_name
store_variable vnet_hub_bastion_subnet_name
store_variable vnet_hub_bastion_subnet_address_prefix
store_variable vnet_spoke1_plain_name
store_variable vnet_spoke1_name
store_variable vnet_spoke1_address_prefix
store_variable vnet_spoke1_front_subnet_name
store_variable vnet_spoke1_front_subnet_nsg_name
store_variable vnet_spoke1_front_subnet_udr_name
store_variable vnet_spoke1_front_subnet_address_prefix
store_variable vnet_spoke2_plain_name
store_variable vnet_spoke2_name
store_variable vnet_spoke2_address_prefix
store_variable vnet_spoke2_aks_subnet_name
store_variable vnet_spoke2_aks_subnet_address_prefix
store_variable vnet_spoke2_aks_subnet_udr_name
store_variable vnet_spoke2_agic_subnet_name
store_variable vnet_spoke2_agic_subnet_address_prefix
store_variable vnet_spoke2_pe_subnet_name
store_variable vnet_spoke2_pe_subnet_address_prefix
store_variable vm_name
store_variable vm_username
store_variable vm_password
store_variable bastion_public_ip
store_variable bastion_name
store_variable aci_name
store_variable aks_azure_ad_admin_group_contains
store_variable aks_name
store_variable aks_workspace_name
store_variable aks_cluster_identity_name
store_variable aks_kubelet_identity_name
store_variable aks_nodepool1
store_variable aks_nodepool2
store_variable unique_id
store_variable acr_name
store_variable storage_name
store_variable storage_share_name
store_variable agic_name
