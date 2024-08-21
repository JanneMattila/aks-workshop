# Import images
# Command: REGISTRY-1
az acr import -n $acr_name -t "apps/jannemattila/webapp-fs-tester:1.1.13" --source "docker.io/jannemattila/webapp-fs-tester:1.1.13" 

# Enable "Defender for Containers" in the Portal

############################
# Import vulnerable images
# --
# More images:
# https://hub.docker.com/u/vulnerables
############################
# Command: REGISTRY-2
az acr import -n $acr_name -t "bad/dotnet/core/sdk:2.2.401" --source "mcr.microsoft.com/dotnet/core/sdk:2.2.401" 
az acr import -n $acr_name -t "bad/vulnerables/web-dvwa" --source "docker.io/vulnerables/web-dvwa" 
az acr import -n $acr_name -t "bad/vulnerables/metasploit-vulnerability-emulator" --source "docker.io/vulnerables/metasploit-vulnerability-emulator" 
az acr import -n $acr_name -t "bad/vulnerables/cve-2017-7494" --source "docker.io/vulnerables/cve-2017-7494" 
az acr import -n $acr_name -t "bad/vulnerables/mail-haraka-2.8.9-rce" --source "docker.io/vulnerables/mail-haraka-2.8.9-rce" 
############################
# /Import vulnerable images
############################

# Build
# Command: REGISTRY-3
az acr build --registry $acr_name --image "apps/simple-app:v2" ./simple-app/src

acr_loginserver=$(az acr show -g $resource_group_name -n $acr_name --query loginServer -o tsv)
store_variable acr_loginserver
echo $acr_loginserver

kubectl create ns simple-app
kubectl create deployment simple-app-deployment --image "$acr_loginserver/apps/simple-app:v2" --replicas 1 -n simple-app

kubectl get pods -n simple-app

simple_app_pod1=$(kubectl get pod -n simple-app -o name | head -n 1)
store_variable simple_app_pod1
echo $simple_app_pod1

kubectl logs $simple_app_pod1 -n simple-app

########################################################
# Create cache for DockerHub
# Note:
# These command require that you create key vault first.
# Follow the instructions in "16-keyvault.sh".
# Require commands:
# - Command: KEYVAULT-3 - Create key vault
# - Command: KEYVAULT-5 - Grant admin access to key vault
########################################################
# Create Docker Hub required secrets
# Command: REGISTRY-4
read -s -p "Docker Hub username:" dockerhub_user
read -s -p "Docker Hub password:" dockerhub_password

az keyvault secret set --vault-name $keyvault_name -n dockerhub-user --value $dockerhub_user
az keyvault secret set --vault-name $keyvault_name -n dockerhub-password --value $dockerhub_password

# Create a credential set for Docker Hub
# Command: REGISTRY-5
acr_credential_set_principal_id=$(az acr credential-set create -r $acr_name -n DockerHub -l docker.io -u "${keyvault_vault_uri}secrets/dockerhub-user" -p "${keyvault_vault_uri}secrets/dockerhub-password" --query identity.principalId -o tsv)
store_variable acr_credential_set_principal_id
echo $acr_credential_set_principal_id

# Grant access to key vault for our credential set managed identity
# Command: REGISTRY-6
az role assignment create \
 --assignee-object-id $acr_credential_set_principal_id \
 --assignee-principal-type ServicePrincipal \
 --scope $keyvault_id \
 --role "Key Vault Secrets User"

# Create a rule referencing the credential set
# Command: REGISTRY-7
az acr cache create -r $acr_name -n DockerHubRule -s docker.io/* -t docker/* -c DockerHub

# Command: REGISTRY-8
cat others/network-app3.yaml | envsubst | kubectl apply -f -
kubectl get deploy -n network-app3
kubectl get pods -n network-app3
kubectl describe pods -n network-app3

# Study ACR in Portal

# QUESTION:
# ---------
# Is our container registry only accessible from our AKS virtual network?
#
# Extra "Exercise 4" in "90-bonus-exercises.sh".
#

# QUESTION:
# ---------
# What are the different authentication methods for ACR?
#
# See some examples:
# https://github.com/JanneMattila/playground-aks-acr/blob/main/setup.sh
#

# QUESTION:
# ---------
# Are there images in "docker/" repository?
# What are these images?
#
# More information:
# https://learn.microsoft.com/en-us/azure/container-registry/container-registry-artifact-cache
# https://learn.microsoft.com/en-us/azure/container-registry/troubleshoot-artifact-cache#cached-images-dont-appear-in-a-live-repository
#
