#!/bin/bash

# Create Premium ZRS file share ahead of time => static provisioning
# NFS related notes from Azure portal if "Secure transfer required" is enabled:
#   "Secure transfer required" is a setting that is enabled for this storage account. 
#   The NFS protocol does not support encryption and relies on network-level security. 
#   This setting must be disabled for NFS to work.
storageid=$(az storage account create \
  --name $premiumStorageName \
  --resource-group $resourceGroupName \
  --location $location \
  --sku Premium_ZRS \
  --kind FileStorage \
  --default-action Deny \
  --allow-blob-public-access false \
  --public-network-access Disabled \
  --https-only false \
  --query id -o tsv)
echo $storageid

premiumStorageKey=$(az storage account keys list \
  --account-name $premiumStorageName \
  --resource-group $resourceGroupName \
  --query [0].value \
  -o tsv)
echo $premiumStorageKey

az storage share-rm create --access-tier Premium --enabled-protocols SMB --quota 100 --name $premiumStorageShareNameSMB --storage-account $premiumStorageName
az storage share-rm create --access-tier Premium --enabled-protocols NFS --quota 100 --name $premiumStorageShareNameNFS --storage-account $premiumStorageName

# Provisioned capacity: 100 GiB
# =>
# Performance
# Maximum IO/s     500
# Burst IO/s       4000
# Throughput rate  70.0 MiBytes / s

# Follow instructions from here:
# https://docs.microsoft.com/en-us/azure/storage/files/storage-files-networking-endpoints?tabs=azure-cli
# Disable private endpoint network policies
az network vnet subnet update \
  --ids $subnetstorageid \
  --disable-private-endpoint-network-policies \
  --output none

# Create private endpoint to "StorageSubnet"
storagepeid=$(az network private-endpoint create \
    --name storage-pe \
    --resource-group $resourceGroupName \
    --vnet-name $vnetName --subnet $subnetStorage \
    --private-connection-resource-id $storageid \
    --group-id file \
    --connection-name storage-connection \
    --query id -o tsv)
echo $storagepeid

# Create Private DNS Zone
fileprivatednszoneid=$(az network private-dns zone create \
    --resource-group $resourceGroupName \
    --name "privatelink.file.core.windows.net" \
    --query id -o tsv)
echo $fileprivatednszoneid

# Link Private DNS Zone to VNET
az network private-dns link vnet create \
  --resource-group $resourceGroupName \
  --zone-name "privatelink.file.core.windows.net" \
  --name file-dnszone-link \
  --virtual-network $vnetName \
  --registration-enabled false

# Get private endpoint NIC
penicid=$(az network private-endpoint show \
  --ids $storagepeid \
  --query "networkInterfaces[0].id" -o tsv)
echo $penicid

# Get ip of private endpoint NIC
peip=$(az network nic show \
  --ids $penicid \
  --query "ipConfigurations[0].privateIpAddress" -o tsv)
echo $peip

# Map private endpoint ip to A record in Private DNS Zone
az network private-dns record-set a create \
  --resource-group $resourceGroupName \
  --zone-name "privatelink.file.core.windows.net" \
  --name $premiumStorageName \
  --output none

az network private-dns record-set a add-record \
  --resource-group $resourceGroupName \
  --zone-name "privatelink.file.core.windows.net" \
  --record-set-name $premiumStorageName \
  --ipv4-address $peip \
  --output none

# Deploy storage secret
kubectl create secret generic azurefile-secret \
  --from-literal=azurestorageaccountname=$premiumStorageName \
  --from-literal=azurestorageaccountkey=$premiumStorageKey \
  -n demos --type Opaque --dry-run=client -o yaml > azurefile-secret.yaml
cat azurefile-secret.yaml
kubectl apply -f azurefile-secret.yaml

# Enable static provisioning
kubectl apply -f static/azurefile-csi-nfs
kubectl apply -f static/azurefile-csi-premium

kubectl get pv -n demos
kubectl get pvc -n demos

kubectl describe pv nfs-pv -n demos
kubectl describe pvc nfs-pvc -n demos

kubectl describe pv smb-pv -n demos
kubectl describe pvc smb-pvc -n demos
