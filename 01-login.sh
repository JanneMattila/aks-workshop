###################################
#  _                   _
# | |     ___    __ _ (_) _ __
# | |    / _ \  / _` || || '_ \
# | |___| (_) || (_| || || | | |
# |_____|\___/  \__, ||_||_| |_|
#               |___/
# and set correct context
###################################

# List Azure regions
az account list-locations -o table

#
# Couple of things about regions:
# - Not all services are in all regions:
#   https://azure.microsoft.com/en-us/global-infrastructure/services/
# - Not all regions support availability zones
#   https://learn.microsoft.com/en-us/azure/reliability/availability-zones-service-support#azure-regions-with-availability-zones
#

# ----------------------------------------
# NOTE: 
# You can skip login if using cloud shell
# ----------------------------------------
# Command: VAR-1
az login -o table --only-show-errors
az account set --subscription $subscription_name -o table

# Show current context
# Command: VAR-2
az account show -o table

# Create resource group
# Command: VAR-3
az group create -l $location -n $resource_group_name -o table

# Prepare extensions and providers
# Command: VAR-4
az extension add --upgrade --yes --name aks-preview --allow-preview true
az extension add --upgrade --yes --name bastion
az extension add --upgrade --yes --name ssh
az extension add --upgrade --yes --name alb

# Register required resource providers on Azure.
az provider register --namespace Microsoft.ContainerService
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.NetworkFunction
az provider register --namespace Microsoft.ServiceNetworking
