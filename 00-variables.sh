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
