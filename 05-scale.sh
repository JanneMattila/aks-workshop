#!/bin/bash

# QUESTION:
# ---------
# What are our scaling options with Kubernetes/AKS?
#
# Extra "Exercise 3" in "90-bonus-exercises.sh".
#

# You can scale existing nodepool manually
# Command: SCALE-1
az aks nodepool scale -g $resource_group_name --cluster-name $aks_name \
  --name $aks_nodepool1 \
  --node-count 2

# You can create new nodepools
# Command: SCALE-2
az aks nodepool add -g $resource_group_name --cluster-name $aks_name \
  --name $aks_nodepool2 \
  --node-count 2 \
  --node-osdisk-type Ephemeral \
  --node-vm-size Standard_D8ds_v4 \
  --node-taints "usage=tempworkloads:NoSchedule" \
  --labels usage=tempworkloads \
  --max-pods 150

# You can remove nodepools
# Command: SCALE-3
az aks nodepool delete -g $resource_group_name --cluster-name $aks_name --name $aks_nodepool2
