# Enable Application Gateway for Containers (AGC)
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
curl $aks_oidc_issuer/.well-known/openid-configuration

az identity federated-credential create \
 --name "azure-alb-identity" \
 --identity-name $aks_agc_identity_name \
 --resource-group $resource_group_name \
 --issuer $aks_oidc_issuer \
 --subject "system:serviceaccount:azure-alb-system:alb-controller-sa"

# Study https://mcr.microsoft.com

helm install alb-controller \
 oci://mcr.microsoft.com/application-lb/charts/alb-controller \
 --version 0.6.3 \
 --set albController.namespace=azure-alb-system \
 --set albController.podIdentity.clientID=$aks_agc_client_id

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

kubectl apply -f others/agc/02-gateway.yaml
kubectl get gateway -n alb-ns -o yaml

kubectl apply -f others/agc/03-route.yaml
kubectl delete -f others/agc/03-route.yaml

kubectl get gateway -n alb-ns
kubectl get httproute -n network-app -o yaml

aks_agc_gateway_address=$(kubectl get gateway -n alb-ns -o jsonpath="{.items[0].status.addresses[0].value}")
store_variable aks_agc_gateway_address
echo $aks_agc_gateway_address

curl $aks_agc_gateway_address
