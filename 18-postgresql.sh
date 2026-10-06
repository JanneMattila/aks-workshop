# Azure Database for PostgreSQL Flexible Server

# Store PostgreSQL settings
# Command: POSTGRESQL-1
postgres_primary_zone="1"
postgres_standby_zone="2"
postgres_private_dns_zone_name="$postgres_server_name.private.postgres.database.azure.com"
store_variable postgres_server_name
store_variable postgres_db_name
store_variable postgres_version
store_variable postgres_admin_user
store_variable postgres_auth_mode
store_variable postgres_primary_zone
store_variable postgres_standby_zone
store_variable postgres_private_dns_zone_name

# Expand the existing AKS VNet from /22 to /21 to make room for PostgreSQL.
# Existing subnet ranges are unchanged. Ensure the added range does not overlap other networks.
# Command: POSTGRESQL-2
az network vnet update \
  --name "$vnet_spoke2_name" \
  --resource-group "$resource_group_name" \
  --address-prefixes "$vnet_spoke2_address_prefix"

# PostgreSQL requires an exclusive subnet delegated to Flexible Server.
# Command: POSTGRESQL-3
vnet_spoke2_postgres_subnet_id=$(az network vnet subnet create \
  --name "$vnet_spoke2_postgres_subnet_name" \
  --resource-group "$resource_group_name" \
  --vnet-name "$vnet_spoke2_name" \
  --address-prefixes "$vnet_spoke2_postgres_subnet_address_prefix" \
  --delegations Microsoft.DBforPostgreSQL/flexibleServers \
  --query id -o tsv)
store_variable vnet_spoke2_postgres_subnet_id

# Sync the existing hub peering with the expanded AKS VNet address space.
# Command: POSTGRESQL-4
az network vnet peering sync \
  --name "$vnet_hub_plain_name-to-$vnet_spoke2_plain_name" \
  --resource-group "$resource_group_name" \
  --vnet-name "$vnet_hub_name"

# Link private DNS to the AKS/server VNet and hub jumpbox VNet.
# Command: POSTGRESQL-5
postgres_private_dns_zone_id=$(az network private-dns zone create \
  --name "$postgres_private_dns_zone_name" \
  --resource-group "$resource_group_name" \
  --query id -o tsv)
store_variable postgres_private_dns_zone_id

for postgres_dns_vnet_id in "$vnet_spoke2_id" "$vnet_hub_id"; do
  az network private-dns link vnet create \
    --name "${postgres_dns_vnet_id##*/}" \
    --resource-group "$resource_group_name" \
    --zone-name "$postgres_private_dns_zone_name" \
    --virtual-network "$postgres_dns_vnet_id" \
    --registration-enabled false
done

# Create a primary in zone 1 and an HA standby in zone 2.
# GeneralPurpose supports zone-redundant HA; Burstable does not.
# The selected region must support zone-redundant HA and the selected SKU.
# Enter a strong administrator password when prompted; it is not persisted.
# Command: POSTGRESQL-6
az postgres flexible-server create \
--name "$postgres_server_name" \
--resource-group "$resource_group_name" \
--location "$location" \
--tier GeneralPurpose \
--sku-name Standard_D2ds_v5 \
--version "$postgres_version" \
--storage-size 32 \
--backup-retention 7 \
--zonal-resiliency Enabled \
--zone "$postgres_primary_zone" \
--standby-zone "$postgres_standby_zone" \
--microsoft-entra-auth Enabled \
--password-auth Enabled \
--admin-user "$postgres_admin_user" \
--admin-password "$postgres_admin_password" \
--subnet "$vnet_spoke2_postgres_subnet_id" \
--private-dns-zone "$postgres_private_dns_zone_id" \
--yes

# Read the resource separately so CLI creation output cannot persist credentials.
postgres_server_json=$(az postgres flexible-server show \
  --name "$postgres_server_name" \
  --resource-group "$resource_group_name" \
  -o json)
echo "$postgres_server_json" | jq .
store_variable postgres_server_json

# Grant administrator access to the workshop Entra ID group
# Command: POSTGRESQL-7
az postgres flexible-server microsoft-entra-admin create \
  --server-name "$postgres_server_name" \
  --resource-group "$resource_group_name" \
  --display-name "$aks_entra_id_admin_group_contains" \
  --object-id "$aks_entra_id_admin_group_object_id" \
  --type Group

# Enable PgBouncer connection pooler for the PostgreSQL flexible server.
az postgres flexible-server parameter set \
  --server-name "$postgres_server_name" \
  --resource-group "$resource_group_name" \
  --name pgbouncer.enabled \
  --value True

# Create a sample database (there is no built-in --sample-name option)
# Command: POSTGRESQL-8
az postgres flexible-server db create \
  --name "$postgres_db_name" \
  --server-name "$postgres_server_name" \
  --resource-group "$resource_group_name"

# Inspect the version, private network, primary zone, standby zone and HA state
# Command: POSTGRESQL-9
az postgres flexible-server show \
  --name "$postgres_server_name" \
  --resource-group "$resource_group_name" \
  --query "{server:fullyQualifiedDomainName,version:version,network:network,primaryZone:availabilityZone,ha:highAvailability}" \
  -o json | jq .

# Store credentials only in a Kubernetes Secret, not in workshop variables or files.
# Npgsql can also read PGUSER and PGPASSWORD from the Secret.
# Command: POSTGRESQL-10
kubectl apply -f postgresql-app/01-namespace.yaml

kubectl create secret generic postgresql-app-db \
  --namespace postgresql-app \
  --from-literal=username="$postgres_admin_user" \
  --from-literal=password="$postgres_admin_password"

# Deploy three app replicas; minDomains prevents silently using fewer than three zones.
# Repeat this step after refreshing the Secret so pods pick up the new credential.
# Command: POSTGRESQL-11
kubectl apply -f postgresql-app/02-service.yaml
kubectl apply -f postgresql-app/03-deployment.yaml
envsubst < postgresql-app/04-deployment-client.yaml | kubectl apply -f -

# Verify the running app pods actually span three availability zones.
# Command: POSTGRESQL-12
kubectl get pods -n postgresql-app
list_pods postgresql-app

# Populate and query the sample database through the app, not through local psql.
# Command: POSTGRESQL-13
postgres_app_url=$(kubectl get service postgresql-app-svc -n postgresql-app -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
store_variable postgres_app_url
echo $postgres_app_url

curl --data "IPLOOKUP $postgres_server_name.postgres.database.azure.com" "$postgres_app_url/api/commands"
curl --data "TCP $postgres_server_name.postgres.database.azure.com 5432" "$postgres_app_url/api/commands"
curl --data "TCP $postgres_server_name.postgres.database.azure.com 6432" "$postgres_app_url/api/commands"

# The network app logs and echoes command payloads, including these credentials.
postgres_app_connection_string="Server=$postgres_server_name.postgres.database.azure.com;Port=6432;Database=$postgres_db_name;Ssl Mode=Require;Timeout=30;User ID=$postgres_admin_user;Password=$postgres_admin_password"
echo $postgres_app_connection_string

# Simple database tests:
curl -H "Content-Type: text/plain" --data "POSTGRESQL QUERY \"SELECT\" \"$postgres_app_connection_string\"" "$postgres_app_url/api/commands"
curl -H "Content-Type: text/plain" --data "POSTGRESQL QUERY \"SELECT schemaname, tablename FROM pg_catalog.pg_tables\" \"$postgres_app_connection_string\"" "$postgres_app_url/api/commands"

while true; do
  output=$(curl -s -H "Content-Type: text/plain" --data "POSTGRESQL QUERY \"SELECT\" \"$postgres_app_connection_string\"" "$postgres_app_url/api/commands")
  echo $output

  if [[ "$output" =~ ([0-9]+([.][0-9]+)?)ms[[:space:]]*$ ]]; then
    elapsed_ms="${BASH_REMATCH[1]}"
    echo "$elapsed_ms" >> elapsed_times.log
  fi
  sleep 1
done

postgresql_client_pod=$(kubectl get pods -n postgresql-app -l app=postgresql-client -o json |
  jq -er '[.items[] | select(.metadata.deletionTimestamp == null) |
    select(any(.status.conditions[]?; .type == "Ready" and .status == "True"))][0].metadata.name //
    error("No Ready postgresql-client pod found.")')
echo $postgresql_client_pod

# Open a remote shell; run psql inside it to connect using the environment above.
# Command: POSTGRESQL-14

list_pods postgresql-app

kubectl exec -it -n postgresql-app $postgresql_client_pod -- bash

# Alternatively, open psql directly (use \q to exit).
kubectl exec -it -n postgresql-app $postgresql_client_pod -- psql
kubectl exec -it -n postgresql-app postgresql-client-deployment-6f69896975-pq9wx -- psql

# Connect directly to PostgreSQL instead of PgBouncer.
kubectl exec -it -n postgresql-app $postgresql_client_pod -- env PGPORT=5432 psql
