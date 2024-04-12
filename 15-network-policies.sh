#
# Network policies
##
# https://kubernetes.io/docs/concepts/services-networking/network-policies/
#

# QUESTION:
# ---------
# What is the default network policy in AKS?
#
# https://learn.microsoft.com/en-us/azure/aks/concepts-network#network-policies
# https://learn.microsoft.com/en-us/azure/aks/use-network-policies
#

# QUESTION:
# ---------
# Can you later update your existing AKS and enable network policy?
#
# E.g., az aks update -g $resource_group_name -n $aks_name --network-policy azure
#
# https://learn.microsoft.com/en-us/azure/aks/use-network-policies#create-an-aks-cluster-and-enable-network-policy
#

# QUESTION:
# ---------
# What are differences between Network policies and 
# Network Security Groups (NSG)?
#

kubectl apply -f others/network-policy/network-app2.yaml

network_app2_pod1=$(kubectl get pod -n network-app2 -o name | head -n 1)
echo $network_app2_pod1

network_app2_pod1_ip=$(kubectl get pod -n network-app2 -o jsonpath="{.items[0].status.podIPs[0].ip}")
echo $network_app2_pod1_ip

network_app2_external_svc_ip=$(kubectl get service network-app2-external-svc -n network-app2 -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
echo $network_app2_external_svc_ip

network_app2_internal_svc_ip=$(kubectl get service network-app2-internal-svc -n network-app2 -o jsonpath="{.spec.clusterIP}")
echo $network_app2_internal_svc_ip

curl $network_app2_external_svc_ip

# Full access between namespaces
curl -X POST --data "HTTP GET \"http://network-app-internal2-svc.network-app2.svc.cluster.local\"" "$network_app_external_svc_ip/api/commands"
curl -X POST --data "HTTP GET \"http://echo-app-svc.echo-app.svc.cluster.local/api/echo\"" "$network_app_external_svc_ip/api/commands"

curl -X POST --data "HTTP GET \"http://network-app-internal-svc.network-app.svc.cluster.local\"" "$network_app2_external_svc_ip/api/commands"
curl -X POST --data "HTTP GET \"http://echo-app-svc.echo-app.svc.cluster.local/api/echo\"" "$network_app2_external_svc_ip/api/commands"

curl -X POST --data "HTTP GET \"http://$network_app2_pod1_ip:8080\"" "$network_app_external_svc_ip/api/commands"
curl -X POST --data "HTTP GET \"http://$network_app_pod1_ip:8080\"" "$network_app2_external_svc_ip/api/commands"

# Test TCP connection to specific IP
curl -X POST --data "NSLOOKUP bing.com" "$network_app2_external_svc_ip/api/commands"
curl -X POST --data "TCP 13.107.21.200 80" "$network_app2_external_svc_ip/api/commands"
curl -X POST --data "TCP 13.107.21.200 443" "$network_app2_external_svc_ip/api/commands"

# Apply network policy
kubectl apply -f others/network-policy/network-policy.yaml

# Few points to understand:
# - If you have service with port 80 and targetPort 8080, then you must allow 8080 in the rules.
# - 
# Tools:
# https://artturik.github.io/network-policy-viewer/
# https://orca.tufin.io/netpol/
# https://editor.networkpolicy.io - Cillium
#