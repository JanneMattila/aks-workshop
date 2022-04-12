#!/bin/bash

# Create Premium ZRS file share ahead of time => static provisioning
#
# NFS related notes from Azure portal if "Secure transfer required" is enabled:
#   "Secure transfer required" is a setting that is enabled for this storage account. 
#   The NFS protocol does not support encryption and relies on network-level security. 
#   This setting must be disabled for NFS to work.
#
# Create storage account
# Command: STORAGE-1
storage_id=$(az storage account create \
  --name $storage_name \
  --resource-group $resource_group_name \
  --location $location \
  --sku Premium_LRS \
  --kind FileStorage \
  --default-action Deny \
  --allow-blob-public-access false \
  --public-network-access Disabled \
  --https-only false \
  --query id -o tsv)
echo $storage_id

# Get storage account access key
# Command: STORAGE-2
storage_key=$(az storage account keys list \
  --account-name $storage_name \
  --resource-group $resource_group_name \
  --query [0].value \
  -o tsv)
echo $storage_key

# Create NFS file share
# Command: STORAGE-3
az storage share-rm create \
  --access-tier Premium \
  --enabled-protocols NFS \
  --quota 100 \
  --name $storage_share_name \
  --storage-account $storage_name

# Provisioned capacity: 100 GiB
# =>
# Performance
# Maximum IO/s     500
# Burst IO/s       4000
# Throughput rate  70.0 MiBytes / s

# Follow instructions from here:
# https://docs.microsoft.com/en-us/azure/storage/files/storage-files-networking-endpoints?tabs=azure-cli
# Disable private endpoint network policies
#
# Command: STORAGE-4
az network vnet subnet update \
  --ids $vnet_spoke2_pe_subnet_id \
  --disable-private-endpoint-network-policies \
  --output none

# Create private endpoint to "snet-pe"
# Command: STORAGE-5
storage_pe_id=$(az network private-endpoint create \
    --name storage-pe \
    --resource-group $resource_group_name \
    --vnet-name $vnet_spoke2_name --subnet $vnet_spoke2_pe_subnet_name \
    --private-connection-resource-id $storage_id \
    --group-id file \
    --connection-name storage-connection \
    --query id -o tsv)
echo $storage_pe_id

# Create Private DNS Zone
# Command: STORAGE-6
file_private_dns_zone_id=$(az network private-dns zone create \
    --resource-group $resource_group_name \
    --name "privatelink.file.core.windows.net" \
    --query id -o tsv)
echo $file_private_dns_zone_id

# Link Private DNS Zone to VNET
# Command: STORAGE-7
az network private-dns link vnet create \
  --resource-group $resource_group_name \
  --zone-name "privatelink.file.core.windows.net" \
  --name file-dnszone-link \
  --virtual-network $vnet_spoke2_name \
  --registration-enabled false

# Get private endpoint nic
# Command: STORAGE-8
storage_pe_nic_id=$(az network private-endpoint show \
  --ids $storage_pe_id \
  --query "networkInterfaces[0].id" -o tsv)
echo $storage_pe_nic_id

# Get ip of private endpoint NIC
storage_pe_ip=$(az network nic show \
  --ids $storage_pe_nic_id \
  --query "ipConfigurations[0].privateIpAddress" -o tsv)
echo $storage_pe_ip

# Map private endpoint ip to A record in Private DNS Zone
az network private-dns record-set a create \
  --resource-group $resource_group_name \
  --zone-name "privatelink.file.core.windows.net" \
  --name $storage_name \
  --output none

az network private-dns record-set a add-record \
  --resource-group $resource_group_name \
  --zone-name "privatelink.file.core.windows.net" \
  --record-set-name $storage_name \
  --ipv4-address $storage_pe_ip \
  --output none

# Deploy storage secret
kubectl create secret generic azurefile-secret \
  --from-literal=azurestorageaccountname=$storage_name \
  --from-literal=azurestorageaccountkey=$storage_key \
  -n storage-app --type Opaque --dry-run=client -o yaml > azurefile-secret.yaml
cat azurefile-secret.yaml

kubectl apply -f storage-app/00-namespace.yaml
kubectl apply -f azurefile-secret.yaml

# Update persistent volume to refer to correct storage account

cat <<EOF > storage-app/01-persistent-volume.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfs-pv
  namespace: storage-app
spec:
  capacity:
    storage: 100Gi
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  # From:
  # https://github.com/kubernetes-sigs/azurefile-csi-driver/blob/master/deploy/example/pv-azurefile-csi.yaml
  csi:
    driver: file.csi.azure.com
    readOnly: false
    # make sure this volumeid is unique in the cluster
    # `#` is not allowed in self defined volumeHandle
    volumeHandle: nfspv
    volumeAttributes:
      storageAccount: $storage_name
      shareName: nfs
      protocol: nfs
    nodeStageSecretRef:
      name: azurefile-secret
      namespace: storage-app
EOF

cat storage-app/01-persistent-volume.yaml

# Execute static provisioning
kubectl apply -f storage-app/01-persistent-volume.yaml

kubectl get pv -n demos
kubectl get pvc -n demos

kubectl describe pv nfs-pv -n demos
kubectl describe pvc nfs-pvc -n demos

# QUESTION:
# ---------
# If you do "nslookup" from jumpbox, then what ip do you get and why?
#
# Extra "Exercise 4" in "90-bonus-exercises.sh".
#

# QUESTION:
# ---------
# List persistent storage options and their use cases for AKS?
#
