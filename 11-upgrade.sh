#
# Understand the Kubernetes release cycle & AKS Release Calendar
#
# More information here:
# https://github.com/JanneMattila/kubernetes-notes#super-important-topics-to-understand
#

# See use of deprecated APIs
kubectl get --raw /metrics | grep apiserver_requested_deprecated_apis

# See all available Kubernetes versions
# Command: UPGRADE-1
az aks get-versions -l $location -o table

# See upgrades available for our cluster
# Command: UPGRADE-2
az aks get-upgrades -g $resource_group_name -n $aks_name -o table

# See upgrades available for our nodepool
# Command: UPGRADE-3
az aks nodepool get-upgrades --nodepool-name $aks_nodepool1 -g $resource_group_name --cluster-name $aks_name -o table

# Update max surge for an existing node pool
# Note: For production node pools, we recommend a max_surge setting of 33%
# Command: UPGRADE-4
az aks nodepool update -n nodepool1 -g $resource_group_name --cluster-name $aks_name --max-surge 1 -o none

# Options:
# 1. Upgrade in steps: First control plane and then nodepools one-by-one
# 2. Let AKS manage the upgrade according to this:
#    https://learn.microsoft.com/en-us/azure/aks/upgrade-cluster

# Option 1: Upgrade in steps
# Upgrade only control plane
# Command: UPGRADE-5
az aks upgrade -g $resource_group_name -n $aks_name --kubernetes-version 1.25.6 --control-plane-only --yes

# Upgrade nodepool
# Command: UPGRADE-6
az aks nodepool upgrade --name $aks_nodepool1 -g $resource_group_name --cluster-name $aks_name --kubernetes-version 1.25.6 --yes

# Option 2: Let AKS manage the upgrade
# Command: UPGRADE-7
az aks upgrade -g $resource_group_name -n $aks_name --kubernetes-version 1.25.6 --yes

# See upgrades available for our cluster
# Command: UPGRADE-8
az aks get-upgrades -g $resource_group_name -n $aks_name

#
# More information in here:
# https://github.com/JanneMattila/playground-aks-maintenance
#

# For node update management more information here:
# https://learn.microsoft.com/en-us/azure/aks/node-updates-kured
