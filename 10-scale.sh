#!/bin/bash

# QUESTION:
# ---------
# What are our scaling options with Kubernetes/AKS?
#
# Extra "Exercise 3" in "90-bonus-exercises.sh".
#

# You can scale existing nodepool manually
# Command: SCALE-1
kubectl get nodes

az aks nodepool update -g $resource_group_name --cluster-name $aks_name \
  --name $aks_nodepool1 \
  --disable-cluster-autoscaler

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

# Schedule workloads to newly created nodepool
# Command: SCALE-3
kubectl apply -f nodepool-app/

kubectl get nodes --show-labels=true
kubectl get nodes -L agentpool,usage

kubectl get pod -n nodepool-app -o custom-columns=NAME:'{.metadata.name}',NODE:'{.spec.nodeName}'

kubectl get service -n demos

nodepool_app_ip=$(kubectl get service -n nodepool-app -o jsonpath="{.items[0].status.loadBalancer.ingress[0].ip}")
echo $nodepool_app_ip

az aks nodepool update -g $resource_group_name --cluster-name $aks_name \
  --name $aks_nodepool1 \
  --enable-cluster-autoscaler

# Remove workloads
# Command: SCALE-4
kubectl delete -f nodepool-app/

# You can remove nodepools
# Command: SCALE-5
az aks nodepool delete -g $resource_group_name --cluster-name $aks_name --name $aks_nodepool2

#
# "Re-create vs. start+stop vs. scale to zero"
# 
# To optimize your compute costs, you might be looking for different options to achieve that.
#
# More information and options here:
# https://github.com/JanneMattila/playground-aks-scaling#re-create-vs-startstop-vs-scale-to-zero
#
