# Redis
# https://artifacthub.io/packages/helm/bitnami/redis
#

helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

helm search repo bitnami/redis

helm show values bitnami/redis

helm show values bitnami/redis > redis-values.yaml
cat redis-values.yaml
code redis-values.yaml

# 1. Install using configuration file
helm install my-redis bitnami/redis -f redis-values.yaml 

# 2. Install using command line
helm install my-redis bitnami/redis \
  --set auth.password=password \
  --set master.persistence.enabled=false \
  --set replica.persistence.enabled=false \
  --set replica.replicaCount=3 \
  --create-namespace \
  --namespace redis

helm list
helm list -n redis
helm list -A

kubectl get all -n redis

redis_password=$(kubectl get secret --namespace redis my-redis -o jsonpath="{.data.redis-password}" | base64 -d)
echo $redis_password
redis_connection_string="my-redis-master.redis.svc.cluster.local:6379,password=$redis_password,ssl=False,abortConnect=False"
redis_connection_string_replicas="my-redis-replicas.redis.svc.cluster.local:6379,password=$redis_password,ssl=False,abortConnect=False"
echo $redis_connection_string
echo $redis_connection_string_replicas

# Store value to the cache
curl -X POST --data "REDIS SET value1 mycache $redis_connection_string" "$network_app_external_svc_ip/api/commands"

# Get value from the cache
curl -X POST --data "REDIS GET mycache $redis_connection_string" "$network_app_external_svc_ip/api/commands"
curl -X POST --data "REDIS GET mycache $redis_connection_string_replicas" "$network_app_external_svc_ip/api/commands"

helm delete my-redis -n redis
