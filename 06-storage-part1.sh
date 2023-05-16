# List installed Container Storage Interfaces (CSI)
# More information here:
# https://docs.microsoft.com/en-us/azure/aks/csi-storage-drivers
# https://github.com/kubernetes-sigs/azurefile-csi-driver/blob/master/docs/driver-parameters.md
kubectl get storageclasses

kubectl describe storageclass azurefile-csi
kubectl describe storageclass azurefile-csi-premium
kubectl describe storageclass azurefile-premium

# In simple diff view
diff <(kubectl describe storageclass azurefile-csi-premium) <(kubectl describe storageclass azurefile-premium)
diff <(kubectl describe storageclass azurefile-csi) <(kubectl describe storageclass azurefile-premium)

#######################
#  _   _ _____ ____  
# | \ | |  ___/ ___| 
# |  \| | |_  \___ \ 
# | |\  |  _|  ___) |
# |_| \_|_|   |____/ 
#
# Below implementation will create Premium NFS file share ahead of time (=static provisioning).
#
# More information here:
# https://docs.microsoft.com/en-us/azure/aks/azure-files-volume
#

# Create storage account
# Command: STORAGE-PART1-1
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
store_variable "storage_id"
echo $storage_id

# Get storage account access key
# Command: STORAGE-PART1-2
storage_key=$(az storage account keys list \
  --account-name $storage_name \
  --resource-group $resource_group_name \
  --query [0].value \
  -o tsv)
store_variable "storage_key"
echo $storage_key

# Create NFS file share
# Command: STORAGE-PART1-3
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
# Command: STORAGE-PART1-4
az network vnet subnet update \
  --ids $vnet_spoke2_pe_subnet_id \
  --disable-private-endpoint-network-policies \
  --output none

# Create private endpoint to "snet-pe"
# Command: STORAGE-PART1-5
storage_pe_id=$(az network private-endpoint create \
  --name storage-pe \
  --resource-group $resource_group_name \
  --vnet-name $vnet_spoke2_name --subnet $vnet_spoke2_pe_subnet_name \
  --private-connection-resource-id $storage_id \
  --group-id file \
  --connection-name storage-connection \
  --query id -o tsv)
store_variable "storage_pe_id"
echo $storage_pe_id

# Create Private DNS Zone
# Command: STORAGE-PART1-6
file_private_dns_zone_id=$(az network private-dns zone create \
  --resource-group $resource_group_name \
  --name "privatelink.file.core.windows.net" \
  --query id -o tsv)
store_variable "file_private_dns_zone_id"
echo $file_private_dns_zone_id

# Link Private DNS Zone to VNET
# Command: STORAGE-PART1-7
az network private-dns link vnet create \
  --resource-group $resource_group_name \
  --zone-name "privatelink.file.core.windows.net" \
  --name file-dnszone-link \
  --virtual-network $vnet_spoke2_name \
  --registration-enabled false

# Get private endpoint nic
# Command: STORAGE-PART1-8
storage_pe_nic_id=$(az network private-endpoint show \
  --ids $storage_pe_id \
  --query "networkInterfaces[0].id" -o tsv)
store_variable "storage_pe_nic_id"
echo $storage_pe_nic_id

# Get ip of private endpoint nic
# Command: STORAGE-PART1-9
storage_pe_ip=$(az network nic show \
  --ids $storage_pe_nic_id \
  --query "ipConfigurations[0].privateIPAddress" -o tsv)
store_variable "storage_pe_ip"
echo $storage_pe_ip

# Map private endpoint ip to A record in Private DNS Zone
# Command: STORAGE-PART1-10
az network private-dns record-set a create \
  --resource-group $resource_group_name \
  --zone-name "privatelink.file.core.windows.net" \
  --name $storage_name \
  --output none

# Command: STORAGE-PART1-11
az network private-dns record-set a add-record \
  --resource-group $resource_group_name \
  --zone-name "privatelink.file.core.windows.net" \
  --record-set-name $storage_name \
  --ipv4-address $storage_pe_ip \
  --output none

# Deploy storage secret
# Command: STORAGE-PART1-12
kubectl create secret generic azurefile-secret \
  --from-literal=azurestorageaccountname=$storage_name \
  --from-literal=azurestorageaccountkey=$storage_key \
  -n storage-app --type Opaque --dry-run=client -o yaml > azurefile-secret.yaml
cat azurefile-secret.yaml

# Deploy storage app
# Command: STORAGE-PART1-13
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

cat storage-app/01-persistent-volume-nfs.yaml

# Execute deployment
# Command: STORAGE-PART1-14
kubectl apply -f storage-app/01-persistent-volume-nfs.yaml
kubectl apply -f storage-app/02-persistent-volume-claim-nfs.yaml
kubectl apply -f storage-app/03-service.yaml
kubectl apply -f storage-app/04-statefulset.yaml

kubectl get pv -n storage-app
kubectl get pvc -n storage-app
kubectl get pod -n storage-app

kubectl describe pv nfs-pv -n storage-app
kubectl describe pvc nfs-pvc -n storage-app

storage_address=$(az storage account show --name $storage_name --resource-group $resource_group_name --query primaryEndpoints.file -o tsv)
store_variable "storage_address"
echo $storage_address
storage_address_hostname=$(echo $storage_address | cut -d'/' -f3 | cut -d':' -f1)
store_variable "storage_address_hostname"
echo $storage_address_hostname

# QUESTION:
# ---------
# If you do "nslookup" from jumpbox targeting newly created storage account, 
# then what ip do you get and why?
#
# Extra "Exercise 5" in "90-bonus-exercises.sh".
#

# From this machine:
nslookup $storage_address_hostname
# From AKS:
curl -X POST --data "NSLOOKUP \"$storage_address_hostname\"" "$network_app_external_svc_ip/api/commands"
curl -X POST --data "NSLOOKUP \"$storage_name.privatelink.file.core.windows.net\"" "$network_app_external_svc_ip/api/commands"

# QUESTION:
# ---------
# Explain how DNS process works in Private Endpoint scenarios such as above?
#

# QUESTION:
# ---------
# List persistent storage options and their use cases for AKS?
#

# QUESTION:
# ---------
# In above implementation, we've created NFS fileshare using static provisioning.
#
# If we would use dynamic provisioning instead (let AKS create resources as needed),
# then what are the things we should consider in this scenario?
#

#######################
#  _____         _   
# |_   _|__  ___| |_ 
#   | |/ _ \/ __| __|
#   | |  __/\__ \ |_ 
#   |_|\___||___/\__|
# Test that setup is correctly running
# Command: STORAGE-PART1-15
kubectl get service -n storage-app

storage_app_ip=$(kubectl get service -n storage-app -o jsonpath="{.items[0].status.loadBalancer.ingress[0].ip}")
store_variable "storage_app_ip"
echo $storage_app_ip

curl $storage_app_ip/swagger/index.html
# -> OK!

# Quick tests for our Azure Files NFSv4.1 share:
# Command: STORAGE-PART1-16
# - Generate files
curl -s -X POST --data '{"path": "/mnt/nfs","folders": 3,"subFolders": 5,"filesPerFolder": 10,"fileSize": 1024}' -H "Content-Type: application/json" "http://$storage_app_ip/api/generate" | jq .milliseconds
# - Enumerate files
curl -s -X POST --data '{"path": "/mnt/nfs","filter": "*.*","recursive": true}' -H "Content-Type: application/json" "http://$storage_app_ip/api/files" | jq .milliseconds

# Go to Azure Portal and study storage account.
