# Enable Application Gateway for Containers (AGC)
# https://learn.microsoft.com/en-us/azure/application-gateway/for-containers/overview
#
# Important note:
# ---------------
# If you are using Azure Policy, you might get the following error when trying to create the AGC resources:
# "Error creating: admission webhook "validation.gatekeeper.sh"
#  denied the request: [azurepolicy-k8sazurev3noprivilegeescalatio-621db1c4d893abfa0dcb]
#  Privilege escalation container is not allowed: cleanup"
#
# Command: AGC-1
az aks update -g $resource_group_name -n $aks_name --enable-oidc-issuer --enable-workload-identity

aks_node_resource_group_id=$(az group show --name $aks_node_resource_group_name --query id -otsv)

aks_agc_identity_json=$(az identity create --name $aks_agc_identity_name --resource-group $resource_group_name -o json)
echo $aks_agc_identity_json
aks_agc_identity_id=$(echo $aks_agc_identity_json | jq -r .id)
aks_agc_client_id=$(echo $aks_agc_identity_json | jq -r .clientId)
aks_agc_principal_id=$(echo $aks_agc_identity_json | jq -r .principalId)

store_variable aks_agc_identity_id
store_variable aks_agc_client_id
store_variable aks_agc_principal_id
echo $aks_agc_identity_id
echo $aks_agc_client_id
echo $aks_agc_principal_id

# Reader role
az role assignment create \
 --assignee-object-id $aks_agc_principal_id \
 --assignee-principal-type ServicePrincipal \
 --scope $aks_node_resource_group_id \
 --role "acdd72a7-3385-48ef-bd42-f606fba81ae7"

aks_oidc_issuer=$(az aks show -n $aks_name -g $resource_group_name --query "oidcIssuerProfile.issuerUrl" -o tsv)

echo $aks_oidc_issuer
curl $aks_oidc_issuer.well-known/openid-configuration

az identity federated-credential create \
 --name "azure-alb-identity" \
 --identity-name $aks_agc_identity_name \
 --resource-group $resource_group_name \
 --issuer $aks_oidc_issuer \
 --subject "system:serviceaccount:azure-alb-system:alb-controller-sa"

# Study https://mcr.microsoft.com

helm install alb-controller \
 oci://mcr.microsoft.com/application-lb/charts/alb-controller \
 --version 1.7.9 \
 --set albController.namespace=azure-alb-system \
 --set albController.podIdentity.clientID=$aks_agc_client_id

# Validate installation
kubectl get pods -n azure-alb-system
kubectl get gatewayclass azure-alb-external -o yaml

# AppGw for Containers Configuration Manager role
az role assignment create \
 --assignee-object-id $aks_agc_principal_id \
 --assignee-principal-type ServicePrincipal \
 --scope $aks_node_resource_group_id \
 --role "fbc52c3f-28ad-4303-a892-8a056630b8f1"

# Network Contributor role
az role assignment create \
 --assignee-object-id $aks_agc_principal_id \
 --assignee-principal-type ServicePrincipal \
 --scope $vnet_spoke2_agc_subnet_id \
 --role "4d97b98b-1d4f-4787-a291-c67834d212e7"

kubectl apply -f others/agc/00-namespace.yaml

cat others/agc/01-loadbalancer.yaml | envsubst | kubectl apply -f -
kubectl get all -n azure-alb-system

kubectl get applicationloadbalancer alb-demo -n alb-ns -o yaml
# "Application Gateway for Containers resource alb-4615e2b5 is undergoing an update."
# -> Wait for the ALB to be ready. It might take a few minutes.

# If you get the following error, it means that the region you are trying to deploy the ALB is not supported for AGC.:
# ERROR CODE: LocationNotAvailableForResourceType
# {
#  "error": {
#   "code": "LocationNotAvailableForResourceType",
#   "message": "The provided location '...' is not available for resource type 'Microsoft.ServiceNetworking/trafficControllers'.
#               List of available regions for the resource type is '...'."
#  }
# }

kubectl apply -f others/agc/02-gateway.yaml
kubectl get gateway -n alb-ns -o yaml

kubectl apply -f others/agc/03-service.yaml
kubectl apply -f others/agc/04-route.yaml

kubectl get gateway -n alb-ns
kubectl get svc network-app-svc -n network-app -o yaml
kubectl get httproute -n network-app -o yaml

aks_agc_gateway_address=$(kubectl get gateway -n alb-ns -o jsonpath="{.items[0].status.addresses[0].value}")
store_variable aks_agc_gateway_address
echo $aks_agc_gateway_address

curl $aks_agc_gateway_address
# Hello there!

# Deploy WAF Policy using Bicep
aks_agc_waf_policy_id=$(az deployment group create \
 --resource-group $resource_group_name \
 --template-file others/agc/waf-policy.bicep \
 --query "properties.outputs.wafPolicyId.value" \
 --output tsv)
store_variable aks_agc_waf_policy_id
echo $aks_agc_waf_policy_id

# Network Contributor role for our WAF Policy
az role assignment create \
 --assignee-object-id $aks_agc_principal_id \
 --assignee-principal-type ServicePrincipal \
 --scope $aks_agc_waf_policy_id \
 --role "4d97b98b-1d4f-4787-a291-c67834d212e7"

# Apply WAF Policy to the Application Gateway for Containers
cat others/agc/05-waf-policy.yaml | envsubst | kubectl apply -f -

kubectl get wafpolicy -n alb-ns -o yaml

# The client '...' with object id '...' has permission to perform action 
# 'Microsoft.ServiceNetworking/trafficControllers/securityPolicies/write' on scope 
# '/subscriptions/.../resourceGroups/mc_rg-..._uksouth/providers/Microsoft.ServiceNetworking/trafficControllers/alb-3ab05c65/securityPolicies/sp-0d47011c-ff3583b388972aa5779f1d8ee040db6857778446'; 
# however, it does not have permission to perform action(s) 
# 'microsoft.network/applicationgatewaywebapplicationfirewallpolicies/join/action' on the linked scope(s)
# '/subscriptions/.../resourcegroups/rg-aks-workshop-janne/providers/microsoft.network/applicationgatewaywebapplicationfirewallpolicies/waf-policy'
# (respectively) or the linked scope(s) are invalid.

# Test WAF Policy

curl $aks_agc_gateway_address
# Hello there!

curl -X POST --data 'INFO HOSTNAME' "$aks_agc_gateway_address/api/commands"
# -> Start: INFO HOSTNAME
# HOSTNAME: network-app-deployment-6956bdf4fc-8qnx2
# <- End: INFO HOSTNAME 4.777ms

curl -X POST --data '--; DROP TABLE Logs' "$aks_agc_gateway_address/api/commands" --verbose
# 403 Access Forbidden

curl -X POST --data 'alert(document.cookie);' "$aks_agc_gateway_address/api/commands" --verbose
# 403 Access Forbidden

# Check logs in Azure Portal

# Try various other AGC features
kubectl apply -f others/agc/05-routepolicy.yaml
kubectl get routepolicy -n network-app -o yaml
kubectl get routepolicy -n network-app
