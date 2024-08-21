# Enable secret rotation in AKS
# Command: KEYVAULT-1
az aks addon update \
  -g $resource_group_name \
  -n $aks_name \
  -a azure-keyvault-secrets-provider \
  --enable-secret-rotation

# Create identity to be used to access key vault
# Command: KEYVAULT-2
aks_keyvault_identity_json=$(az identity create --name $aks_keyvault_identity_name --resource-group $resource_group_name -o json)
aks_keyvault_client_id=$(echo $aks_keyvault_identity_json | jq -r .clientId)
aks_keyvault_principal_id=$(echo $aks_keyvault_identity_json | jq -r .principalId)
store_variable aks_keyvault_client_id
store_variable aks_keyvault_principal_id
echo $aks_keyvault_client_id
echo $aks_keyvault_principal_id

# Create key vault
# Command: KEYVAULT-3
keyvault_json=$(az keyvault show -g $resource_group_name -n $keyvault_name -o json)
keyvault_json=$(az keyvault create -g $resource_group_name -n $keyvault_name --enable-rbac-authorization -o json)
store_variable keyvault_json
keyvault_vault_uri=$(echo $keyvault_json | jq -r .properties.vaultUri)
store_variable keyvault_vault_uri
echo $keyvault_vault_uri
keyvault_id=$(echo $keyvault_json | jq -r .id)
store_variable keyvault_id
echo $keyvault_id

# Enable diagnostic logs for key vault
# Command: KEYVAULT-4
az monitor diagnostic-settings create -n diag1 \
  --resource $keyvault_id \
  --workspace $aks_log_analytics_workspace_id \
  --export-to-resource-specific \
  --logs "[{category:AuditEvent,enabled:true}]"

# Grant admin access to key vault
# Command: KEYVAULT-5
az role assignment create \
 --assignee-object-id $aks_entra_id_admin_group_object_id \
 --assignee-principal-type Group \
 --scope $keyvault_id \
 --role "Key Vault Administrator"

# Create secret to key vault
# Command: KEYVAULT-6
az keyvault secret set --vault-name $keyvault_name -n secret1 --value "SuperSecret1$(date +%s)"

# Grant key vault access to identity
# Command: KEYVAULT-7
az role assignment create \
 --assignee-object-id $aks_keyvault_principal_id \
 --assignee-principal-type ServicePrincipal \
 --scope $keyvault_id \
 --role "Key Vault Administrator"

aks_oidc_issuer=$(echo $aks_json | jq -r ".oidcIssuerProfile.issuerUrl")
tenant_id=$(az account show -s $subscription_name --query tenantId -o tsv)
store_variable tenant_id
keyvault_service_account_name="workload-identity-keyvault-sa"
store_variable keyvault_service_account_name

kubectl create ns secrets-app

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  annotations:
    azure.workload.identity/client-id: ${aks_keyvault_client_id}
  name: ${keyvault_service_account_name}
  namespace: secrets-app
EOF

az identity federated-credential create \
 --name "keyvault-identity" \
 --identity-name $aks_keyvault_identity_name \
 --resource-group $resource_group_name \
 --issuer $aks_oidc_issuer \
 --subject "system:serviceaccount:secrets-app:$keyvault_service_account_name"

cat <<EOF | kubectl apply -f -
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: azure-keyvault-wi
  namespace: secrets-app
spec:
  provider: azure
  parameters:
    usePodIdentity: "false"
    clientID: "${aks_keyvault_client_id}" # Setting this to use workload identity
    keyvaultName: ${keyvault_name}       # Set to the name of your key vault
    objects: |
      array:
        - |
          objectName: secret1             # Set to the name of your secret
          objectType: secret              # object types: secret, key, or cert
          objectVersion: ""               # [OPTIONAL] object versions, default to latest if empty
    tenantId: "${tenant_id}"              # The tenant ID of the key vault
  secretObjects:                          # [OPTIONAL] SecretObjects defines the desired state of synced Kubernetes secret objects
  - data:
    - key: mysecret1                      # data field to populate
      objectName: secret1                 # name of the mounted content to sync; this could be the object name or the object alias
    secretName: app-secret                # name of the Kubernetes secret object
    type: Opaque                          # type of Kubernetes secret object (for example, Opaque, kubernetes.io/tls)
EOF

kubectl get secretproviderclass -n secrets-app
kubectl describe secretproviderclass -n secrets-app

kubectl get serviceaccount -n secrets-app
kubectl describe serviceaccount -n secrets-app

kubectl get secret -n secrets-app

cat <<EOF | kubectl apply -f -
kind: Pod
apiVersion: v1
metadata:
  name: busybox-secrets-store-inline-wi
  namespace: secrets-app
  labels:
    azure.workload.identity/use: "true"
spec:
  serviceAccountName: "${keyvault_service_account_name}"
  containers:
    - name: busybox
      image: registry.k8s.io/e2e-test-images/busybox:1.29-4
      command:
        - "/bin/sleep"
        - "10000"
      volumeMounts:
      - name: secrets-store
        mountPath: "/mnt/secrets-store"
        readOnly: true
      - name: secret-volume
        mountPath: "/mnt/secrets-volume"
        readOnly: true
  volumes:
    - name: secrets-store
      csi:
        driver: secrets-store.csi.k8s.io
        readOnly: true
        volumeAttributes:
          secretProviderClass: "azure-keyvault-wi"
    - name: secret-volume
      secret:
        secretName: app-secret
EOF

kubectl get pod -n secrets-app
kubectl describe pod -n secrets-app

kubectl get secret -n secrets-app
kubectl describe secret -n secrets-app
kubectl get secret app-secret -n secrets-app -o jsonpath='{.data.mysecret1}' | base64 -d

kubectl exec -it busybox-secrets-store-inline-wi -n secrets-app -- sh

cd /mnt/
cd /mnt/secrets-store
cd /mnt/secrets-volume
ls
cat /mnt/secrets-store/secret1
cat /mnt/secrets-volume/mysecret1
watch -n 1 cat /mnt/secrets-store/secret1 /mnt/secrets-volume/mysecret1

exit

# QUESTIONs:
# ----------
# How fast did the secrets got updated to the application?
# Do above secrets get updated at the same time?
# What is the lifecycle of Kubernetes secret?
#
# How can you verify who and when connected to Key Vaultit?
#

kubectl delete pod busybox-secrets-store-inline-wi -n secrets-app

kubectl delete ns secrets-app
