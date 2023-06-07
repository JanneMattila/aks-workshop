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
# -> <html><body>Hello
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

# QUESTION:
# ---------
# Is other apps service reachable from network-app?
#
curl -X POST --data "IPLOOKUP other-app-svc.other-app.svc.cluster.local" "$network_app_external_svc_ip/api/commands"
