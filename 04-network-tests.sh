###################
#          _ 
#  ___ ___| |__
# / __/ __| '_ \
# \__ \__ \ | | |
# |___/___/_| |_|
# to jumpbox 
###################

# Echo important variables
echo -e "Environment vars->" \
     \\nnetwork_app_internal_svc_ip=\"$network_app_internal_svc_ip\" \
     \\nnetwork_app_pod1_ip=\"$network_app_pod1_ip\" \
     \\naci_ip=\"$aci_ip\" \
     \\n"<-Environment vars"

echo $vm_password

# Command: NETWORK-TESTING-1
az network bastion ssh --name $bastion_name --resource-group $resource_group_name --target-resource-id $vm_id --auth-type "password" --username $vm_username

# Copy above "Environment vars" section and paste them to the console.

# Try to connect 
# Command: NETWORK-TESTING-2
curl $network_app_internal_svc_ip
# -> <html><body>Hello
curl $network_app_pod1_ip
# If using Azure CNI:
# -> <html><body>Hello
# If using Azure CNI Overlay (please explain why)
# -> Timeout
curl $aci_ip
# -> <html><body>Hello

# QUESTION:
# ---------
# What did above test proove?
#
# Open architecture diagram and see how traffic flows.
#

#
# Below is using following application for network testing:
# https://github.com/JanneMattila/webapp-network-tester
#

# Test outbound internet accesses
# Command: NETWORK-TESTING-3
curl -X POST --data "HTTP GET \"https://github.com\"" "$network_app_internal_svc_ip/api/commands" # OK
curl -X POST --data "HTTP GET \"https://github.com\"" "$aci_ip/api/commands" # OK
curl -X POST --data "HTTP GET \"https://myip.jannemattila.com\"" "$network_app_external_svc_ip/api/commands" # OK

# QUESTION:
# ---------
# What IP came as output from last command and why?
#

# Test spoke001 -> spoke002 connectivity
# Command: NETWORK-TESTING-4
curl -X POST --data  "HTTP GET \"http://$network_app_internal_svc_ip\"" "$aci_ip/api/commands" # Timeout
# Test spoke002 -> spoke001 connectivity
curl -X POST --data  "HTTP GET \"http://$aci_ip\"" "$network_app_internal_svc_ip/api/commands" # Timeout

# Exit jumpbox
exit

# QUESTION:
# ---------
# Why did above spoke-to-spoke tests timeout?
#

# QUESTION:
# ---------
# What are differences between User-Defined Routes (UDR) and 
# Network Security Groups (NSG)?
#
# Extra "Exercise 1" in "90-bonus-exercises.sh".
# Extra "Exercise 2" in "90-bonus-exercises.sh".
#

# QUESTION:
# ---------
# What are our options to enable spoke-to-spoke connectivity?
#
# Extra "Exercise 3" in "90-bonus-exercises.sh".
#

# QUESTION:
# ---------
# How does name resolution work in Kubernetes?
#
# How do you access services and pods from different namespaces?
#
# Explain how it works and test it.
#
# https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/
#
# Advanced follow-up question:
# If you do a lot of external DNS queries, 
# why it *may* negatively impact performance?
#
# https://github.com/JanneMattila/some-questions-and-some-answers/blob/master/q%26a/azure_kubernetes_service.md#dns
#

kubectl get services -A

curl -X POST --data "FILE READ /etc/hosts" "$network_app_external_svc_ip/api/commands"
curl -X POST --data "FILE READ /etc/nsswitch.conf" "$network_app_external_svc_ip/api/commands"
curl -X POST --data "FILE READ /etc/resolv.conf" "$network_app_external_svc_ip/api/commands"
# Why is "network-app.svc.cluster.local" first in the list?

curl -X POST --data "NSLOOKUP bing.com" "$network_app_external_svc_ip/api/commands"
curl -X POST --data "NSLOOKUP cluster.local" "$network_app_external_svc_ip/api/commands"
curl -X POST --data "NSLOOKUP kubernetes.default.svc.cluster.local" "$network_app_external_svc_ip/api/commands"

curl -X POST --data "IPLOOKUP kube-dns.kube-system.svc.cluster.local" "$network_app_external_svc_ip/api/commands"

curl -X POST --data "IPLOOKUP network-app-internal-svc" "$network_app_external_svc_ip/api/commands"
curl -X POST --data "IPLOOKUP network-app-internal-svc.network-app" "$network_app_external_svc_ip/api/commands"
curl -X POST --data "IPLOOKUP network-app-internal-svc.network-app.svc.cluster.local" "$network_app_external_svc_ip/api/commands"

curl -X POST --data $'INFO ENV' "$network_app_external_svc_ip/api/commands"
curl -X POST --data $'INFO HOSTNAME\nHTTP POST \"http://network-app-internal-svc/api/commands\"\nINFO HOSTNAME' "$network_app_external_svc_ip/api/commands"

# QUESTION:
# ---------
# Are other apps service reachable from network-app?
#
curl -X POST --data "IPLOOKUP echo-app-svc.echo-app.svc.cluster.local" "$network_app_external_svc_ip/api/commands"
curl -X POST --data "HTTP GET \"http://echo-app-svc.echo-app.svc.cluster.local\"" "$network_app_external_svc_ip/api/commands"

# For accessing host files you can use following commands:
curl -X POST --data "FILE LIST /mnt/host/var/log/azure" "$network_app_external_svc_ip/api/commands"

curl -X POST --data "FILE READ /mnt/host/var/log/azure/containerd-status.log" "$network_app_external_svc_ip/api/commands"
curl -X POST --data "FILE READ /mnt/host/var/log/azure/cluster-provision.log" "$network_app_external_svc_ip/api/commands"
curl -X POST --data "FILE READ /mnt/host/var/log/azure/kubelet-status.log" "$network_app_external_svc_ip/api/commands"

curl -X POST --data "FILE LIST /mnt/host/var/log/azure/Microsoft.Azure.Extensions.CustomScript" "$network_app_external_svc_ip/api/commands"
curl -X POST --data "FILE READ /mnt/host/var/log/azure/Microsoft.Azure.Extensions.CustomScript/CommandExecution.log" "$network_app_external_svc_ip/api/commands"

curl -X POST --data "FILE LIST /mnt/host/var/log/azure/Microsoft.AKS.Compute.AKS.Linux.AKSNode" "$network_app_external_svc_ip/api/commands"
curl -X POST --data "FILE READ /mnt/host/var/log/azure/Microsoft.AKS.Compute.AKS.Linux.AKSNode/CommandExecution.log" "$network_app_external_svc_ip/api/commands"

curl -X POST --data "FILE LIST /mnt/host/var/log/azure/custom-script" "$network_app_external_svc_ip/api/commands"
curl -X POST --data "FILE READ /mnt/host/var/log/azure/custom-script/handler.log" "$network_app_external_svc_ip/api/commands"

curl -X POST --data "FILE LIST /mnt/host/var/log/azure/aks" "$network_app_external_svc_ip/api/commands"

curl -X POST --data "FILE LIST /mnt/host/etc" "$network_app_external_svc_ip/api/commands"

# https://kubernetes.io/docs/concepts/cluster-administration/logging/
curl -X POST --data "FILE LIST /mnt/host/var/log/pods" "$network_app_external_svc_ip/api/commands"
pod_log_root_path=$(curl -s -X POST --data "FILE LIST /mnt/host/var/log/pods" "$network_app_external_svc_ip/api/commands" | head -2 | tail -1)
echo $pod_log_root_path

curl -X POST --data "FILE LIST $pod_log_root_path" "$network_app_external_svc_ip/api/commands"
pod_log_folder=$(curl -s -X POST --data "FILE LIST $pod_log_root_path" "$network_app_external_svc_ip/api/commands" | head -2 | tail -1)
echo $pod_log_folder

curl -X POST --data "FILE LIST $pod_log_folder" "$network_app_external_svc_ip/api/commands"
pod_log_file=$(curl -s -X POST --data "FILE LIST $pod_log_folder" "$network_app_external_svc_ip/api/commands" | head -2 | tail -1)
echo $pod_log_file

curl -X POST --data "FILE READ $pod_log_file" "$network_app_external_svc_ip/api/commands"

# QUESTION:
# ---------
# How does connectivity to "ExternalName" Service works?
#
# <clip>
# apiVersion: v1
# kind: Service
# metadata:
#   name: externalname-svc
# spec:
#   type: ExternalName
# </clip>
#
# Test and explain what happens when you run following commands:
kubectl apply -f others/service-externalname.yaml
curl -X POST --data "HTTP GET \"http://externalname-svc.default.svc.cluster.local\"" "$network_app_external_svc_ip/api/commands"
