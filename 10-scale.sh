# QUESTION:
# ---------
# What are our scaling options with Kubernetes/AKS?
#
# Extra "Exercise 3" in "90-bonus-exercises.sh".
#

kubectl get nodes

# You can scale existing nodepool manually
# Command: SCALE-1
az aks nodepool update -g $resource_group_name --cluster-name $aks_name \
  --name $aks_nodepool1 \
  --disable-cluster-autoscaler \
  -o none

# Command: SCALE-2
az aks nodepool scale -g $resource_group_name --cluster-name $aks_name \
  --name $aks_nodepool1 \
  --node-count 1 \
  -o none

# You can create new nodepools
# Command: SCALE-3
az aks nodepool add -g $resource_group_name --cluster-name $aks_name \
  --name $aks_nodepool2 \
  --node-count 2 \
  --node-osdisk-type Ephemeral \
  --node-vm-size Standard_D8ds_v4 \
  --node-taints "usage=tempworkloads:NoSchedule" \
  --labels usage=tempworkloads \
  --max-pods 50

# Schedule workloads to newly created nodepool
# Command: SCALE-4
kubectl apply -f nodepool-app/

kubectl get nodes --show-labels=true
kubectl get nodes -L agentpool,usage

kubectl get pod -n nodepool-app -o custom-columns=NAME:'{.metadata.name}',NODE:'{.spec.nodeName}'

kubectl get service -n nodepool-app

nodepool_app_ip=$(kubectl get service -n nodepool-app -o jsonpath="{.items[0].status.loadBalancer.ingress[0].ip}")
echo $nodepool_app_ip
# Open this address in your browser 🤓

# Study nodepools in the portal.

# Remove workloads
# Command: SCALE-5
kubectl delete -f nodepool-app/

# You can remove nodepools
# Command: SCALE-6
az aks nodepool delete -g $resource_group_name --cluster-name $aks_name --name $aks_nodepool2

# Enable cluster autoscaler
# Command: SCALE-7
az aks nodepool update -g $resource_group_name --cluster-name $aks_name \
  --name $aks_nodepool1 \
  --enable-cluster-autoscaler --min-count 1 --max-count 3 \
  -o none

#
# "Re-create vs. start+stop vs. scale to zero"
# 
# To optimize your compute costs, you might be looking for different options to achieve that.
#
# More information and options here:
# https://github.com/JanneMattila/playground-aks-scaling#re-create-vs-startstop-vs-scale-to-zero
#

# QUESTION:
# ---------
# What happens if you have autoscaler enabled and
# you scale deployment up to e.g., 100 replicas?
#
# Extra "Exercise 6" in "90-bonus-exercises.sh".
#

# QUESTION:
# ---------
# How to make sure that your workloads are isolated from critical system pods?
#
# More information here:
# https://learn.microsoft.com/en-us/azure/aks/use-system-pools#system-and-user-node-pools
#

kubectl get nodes -o json | jq .
az aks nodepool show -g $resource_group_name --cluster-name $aks_name --name nodepool1 -o json | jq .

az aks nodepool update -g $resource_group_name --cluster-name $aks_name \
  --name nodepool1 \
  --node-taints CriticalAddonsOnly=true:NoSchedule
