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
  --set global.redis.password=password \
  --set master.persistence.enabled=false \
  --set replica.persistence.enabled=false \
  --set replica.replicaCount=3 \
  --create-namespace \
  --namespace redis-app

helm list
helm list -n redis-app
helm list -A

kubectl get all -n redis-app

redis_password=$(kubectl get secret --namespace redis-app my-redis -o jsonpath="{.data.redis-password}" | base64 -d)
store_variable redis_password
echo $redis_password

redis_connection_string="my-redis-master.redis-app.svc.cluster.local:6379,password=$redis_password,ssl=False,abortConnect=False"
redis_connection_string_replicas="my-redis-replicas.redis-app.svc.cluster.local:6379,password=$redis_password,ssl=False,abortConnect=False"
store_variable redis_connection_string
store_variable redis_connection_string_replicas
echo $redis_connection_string
echo $redis_connection_string_replicas

# Run Redis client
kubectl run -n redis-app redis-client --env REDIS_PASSWORD=$redis_password --image docker.io/bitnami/redis:7.0.11-debian-11-r12 --command -- sleep infinity
kubectl exec --tty -i redis-client --namespace redis-app -- bash
# Run commands inside the container
redis-cli -h my-redis-master.redis-app.svc.cluster.local -p 6379 -a $REDIS_PASSWORD
# Run commands using redis-cli
SET myvalue1 "Hello World"
GET myvalue1
QUIT # Exit from redis-cli
exit # Exit from container
# Delete the pod
kubectl delete pod redis-client -n redis-app

# Connect locally to the Redis using port forwarding
kubectl port-forward --namespace redis-app svc/my-redis-master 6379:6379 

# Store value to the cache
echo "REDIS SET value1 mycache \"$redis_connection_string\""
curl -X POST --data "REDIS SET value1 mycache \"$redis_connection_string\"" "$network_app_external_svc_ip/api/commands"
curl -X POST --data "REDIS SET value1 mycache \"$redis_connection_string\"" "$network_app_external_svc_ip/api/commands"

# Get value from the cache
curl -X POST --data "REDIS GET mycache \"$redis_connection_string\"" "$network_app_external_svc_ip/api/commands"
curl -X POST --data "REDIS SET value1 mycache my-redis-master.redis-app.svc.cluster.local:6379,password=password,ssl=False,abortConnect=False" "$network_app_external_svc_ip/api/commands"

helm delete my-redis -n redis-app
