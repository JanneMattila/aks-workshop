#!/bin/bash

vnetid=$(az network vnet create -g $resourceGroupName --name $vnetName \
  --address-prefix 10.0.0.0/8 \
  --query newVNet.id -o tsv)
echo $vnetid

subnetaksid=$(az network vnet subnet create -g $resourceGroupName --vnet-name $vnetName \
  --name $subnetAks --address-prefixes 10.2.0.0/24 \
  --query id -o tsv)
echo $subnetaksid

subnetstorageid=$(az network vnet subnet create -g $resourceGroupName --vnet-name $vnetName \
  --name $subnetStorage --address-prefixes 10.3.0.0/24 \
  --query id -o tsv)
echo $subnetstorageid

# Delegate a subnet to Azure NetApp Files
# https://docs.microsoft.com/en-us/azure/azure-netapp-files/azure-netapp-files-delegate-subnet
subnetnetappid=$(az network vnet subnet create -g $resourceGroupName --vnet-name $vnetName \
  --name $subnetNetApp --address-prefixes 10.4.0.0/28 \
  --delegations "Microsoft.NetApp/volumes" \
  --query id -o tsv)
echo $subnetnetappid
