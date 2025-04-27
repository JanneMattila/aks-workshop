# Workload Identity with Azure SQL

# Create identity to be used to access Azure SQL
# Command: SQL-1
aks_sqlapp_identity_json=$(az identity create --name $aks_sqlapp_identity_name --resource-group $resource_group_name -o json)
aks_sqlapp_client_id=$(echo $aks_sqlapp_identity_json | jq -r .clientId)
aks_sqlapp_principal_id=$(echo $aks_sqlapp_identity_json | jq -r .principalId)
store_variable aks_sqlapp_client_id
store_variable aks_sqlapp_principal_id
echo $aks_sqlapp_client_id
echo $aks_sqlapp_principal_id

# Create Azure SQL Server
# Command: SQL-2
az sql server create \
  --name $sql_server_name \
  --resource-group $resource_group_name \
  --location $location \
  --enable-ad-only-auth \
  --external-admin-name $aks_entra_id_admin_group_contains \
  --external-admin-principal-type Group \
  --external-admin-sid $aks_entra_id_admin_group_object_id

# Create virtual network rule for AKS subnet
# Command: SQL-3
az sql server vnet-rule create \
  --name allow-aks-subnet \
  --server $sql_server_name \
  --resource-group $resource_group_name \
  --vnet-name $vnet_spoke2_name \
  --subnet $vnet_spoke2_aks_subnet_name

# Create IP firewall rule for my IP
# Command: SQL-4
az sql server firewall-rule create \
  --name allow-my-ip \
  --server $sql_server_name \
  --resource-group $resource_group_name \
  --start-ip-address $my_ip \
  --end-ip-address $my_ip
  
# Create Azure SQL Database
# Command: SQL-5
sql_db_json=$(az sql db create \
  --name $sql_db_name \
  --server $sql_server_name \
  --resource-group $resource_group_name \
  --sample-name AdventureWorksLT \
  --family Gen5 \
  --edition GeneralPurpose \
  --capacity 1 \
  --compute-model Serverless \
  --auto-pause-delay 15 \
  --min-capacity 0.5 \
  --max-size 1GB \
  --backup-storage-redundancy Local \
  --yes \
  -o json)
store_variable sql_db_json

# Managed identity connection string
# Command: SQL-6
sql_db_connection_string="Server=$sql_server_name.database.windows.net;Database=$sql_db_name;Authentication=ActiveDirectoryMsi;TrustServerCertificate=True;"
echo $sql_db_connection_string
store_variable sql_db_connection_string

# Use Azure Portal to create user in Azure SQL Database
# Command: SQL-7
cat <<EOF
CREATE USER [$aks_sqlapp_identity_name] FROM EXTERNAL PROVIDER;
USE [$sql_db_name];
EXEC sp_addrolemember 'db_owner', '$aks_sqlapp_identity_name';
EOF

# Command: SQL-8
aks_oidc_issuer=$(echo $aks_json | jq -r ".oidcIssuerProfile.issuerUrl")
tenant_id=$(az account show -s $subscription_name --query tenantId -o tsv)
store_variable tenant_id
sqlapp_service_account_name="workload-identity-sqlapp-sa"
store_variable sqlapp_service_account_name

# Create Service Account
# Command: SQL-9
kubectl create ns sql-app

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  annotations:
    azure.workload.identity/client-id: ${aks_sqlapp_client_id}
  name: ${sqlapp_service_account_name}
  namespace: sql-app
EOF

az identity federated-credential create \
 --name "sql-app" \
 --identity-name $aks_sqlapp_identity_name \
 --resource-group $resource_group_name \
 --issuer $aks_oidc_issuer \
 --subject "system:serviceaccount:sql-app:$sqlapp_service_account_name"

kubectl get serviceaccount -n sql-app
kubectl describe serviceaccount -n sql-app

# Create deployment and service
# Command: SQL-10
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: sql-app-external-svc
  namespace: sql-app
spec:
  type: LoadBalancer
  ports:
    - port: 80
      targetPort: 8080
  selector:
    app: sql-app
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sql-app-deployment
  namespace: sql-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: sql-app
  template:
    metadata:
      labels:
        app: sql-app
        azure.workload.identity/use: "true"
    spec:
      serviceAccountName: "${sqlapp_service_account_name}"
      containers:
        - image: jannemattila/webapp-network-tester:1.0.79
          name: sql-app
          ports:
            - containerPort: 8080
              name: http
              protocol: TCP
EOF

kubectl get pod -n sql-app
kubectl describe pod -n sql-app

sql_app_external_svc_ip=$(kubectl get service sql-app-external-svc -n sql-app -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
store_variable sql_sql_app_external_svc_ip
echo $sql_app_external_svc_ip

# Command: SQL-11
curl -X POST --data "IPLOOKUP $sql_server_name.database.windows.net" "$sql_app_external_svc_ip/api/commands"
curl -X POST --data "TCP $sql_server_name.database.windows.net 1433" "$sql_app_external_svc_ip/api/commands"

curl -X POST --data "INFO ENV AZURE_CLIENT_ID" "$sql_app_external_svc_ip/api/commands"
curl -X POST --data "INFO ENV AZURE_TENANT_ID" "$sql_app_external_svc_ip/api/commands"
curl -X POST --data "INFO ENV AZURE_FEDERATED_TOKEN_FILE" "$sql_app_external_svc_ip/api/commands"
curl -X POST --data "INFO ENV AZURE_AUTHORITY_HOST" "$sql_app_external_svc_ip/api/commands"
curl -X POST --data "FILE READ /var/run/secrets/azure/tokens/azure-identity-token" "$sql_app_external_svc_ip/api/commands"

curl -X POST --data "SQL QUERY \"SELECT TOP (5) CustomerID, CompanyName FROM [SalesLT].[Customer]\" \"$sql_db_connection_string\"" "$sql_app_external_svc_ip/api/commands"
