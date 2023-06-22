ls -lF ~/.kube/
cat ~/.kube/config

# "Azure Kubernetes Service AAD Server"
# Search "6dae42f8-4368-4678-94ff-3960e28e3630" from Azure Active Directory
aks_api_server_token_json=$(az account get-access-token --resource 6dae42f8-4368-4678-94ff-3960e28e3630 -o json)
aks_api_server_accesstoken=$(echo $aks_api_server_token_json | jq -r .accessToken)

# Study this access token in https://jwt.ms
echo $aks_api_server_accesstoken
echo $aks_api_server

curl -H "Authorization: Bearer $aks_api_server_accesstoken" https://$aks_api_server/

curl -H "Authorization: Bearer $aks_api_server_accesstoken" https://$aks_api_server/version
curl -H "Authorization: Bearer $aks_api_server_accesstoken" https://$aks_api_server/livez
curl -H "Authorization: Bearer $aks_api_server_accesstoken" https://$aks_api_server/healthz

curl -H "Authorization: Bearer $aks_api_server_accesstoken" https://$aks_api_server/api/v1/nodes
curl -H "Authorization: Bearer $aks_api_server_accesstoken" https://$aks_api_server/api/v1/namespaces
kubectl get namespaces

curl -X POST -H "Authorization: Bearer $aks_api_server_accesstoken" -H "Content-Type: application/json; charset=utf-8" --data '{
    "metadata": {
        "name": "shiny"
    }
}' https://$aks_api_server/api/v1/namespaces

kubectl get namespaces

curl -X DELETE -H "Authorization: Bearer $aks_api_server_accesstoken" https://$aks_api_server/api/v1/namespaces/shiny

kubectl get namespaces

### Deprecation: Fetch deployment list
# https://github.com/JanneMattila/QuizMaker/blob/c2287a66406433712bebe6e45ebdfff35e390a8b/src/QuizUserSimulator/quizsim.yaml#L6-L7
# Previously was "extensions/v1beta1", "apps/v1beta1", "apps/v1beta2"
# Now is "apps/v1"
#
# Example API deprecation:
# https://kubernetes.io/blog/2019/07/18/api-deprecations-in-1-16/
# Release notes:
# https://kubernetes.io/docs/setup/release/notes/
curl -H "Authorization: Bearer $aks_api_server_accesstoken" https://$aks_api_server/apis/extensions/v1beta1/deployments
# Should be
curl -H "Authorization: Bearer $aks_api_server_accesstoken" https://$aks_api_server/apis/apps/v1/deployments
