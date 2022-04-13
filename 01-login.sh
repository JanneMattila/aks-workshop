#!/bin/bash

###################################
#  _                   _
# | |     ___    __ _ (_) _ __
# | |    / _ \  / _` || || '_ \
# | |___| (_) || (_| || || | | |
# |_____|\___/  \__, ||_||_| |_|
#               |___/
# and set correct context
###################################

# ----------------------------------
# NOTE: 
# You can skip if using cloud shell
# ----------------------------------
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

