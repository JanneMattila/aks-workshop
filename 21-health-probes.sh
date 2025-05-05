# Deploy health probe demo application
#
# https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#types-of-probe
# https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
#
# https://github.com/JanneMattila/KubernetesProbeDemo
# https://github.com/JanneMattila/Echo

# Command: HEALTH-PROBE-1
kubectl apply -f healthprobe-app/

# Validate
# Command: HEALTH-PROBE-2
kubectl get deployment -n healthprobe-app
kubectl get pod -n healthprobe-app
kubectl get hpa -n healthprobe-app
kubectl get service -n healthprobe-app

healthprobe_app_ip=$(kubectl get service healthprobe-app-svc -n healthprobe-app -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
store_variable healthprobe_app_ip
echo $healthprobe_app_ip

curl $healthprobe_app_ip
curl -s $healthprobe_app_ip/api/healthcheck | jq .
curl -s $healthprobe_app_ip/api/healthcheck/readiness --verbose
curl -s $healthprobe_app_ip/api/healthcheck/liveness --verbose

curl -s -X POST --data '{ "readiness": true, "liveness": true }' -H "Content-Type: application/json" "http://$healthprobe_app_ip/api/healthcheck" | jq .

healthprobe_app_server=$(curl -s $healthprobe_app_ip/api/healthcheck | jq -r .server)
echo $healthprobe_app_server

curl -s -X POST --data "{ \"shutdown\": true, \"condition\": \"$healthprobe_app_server\" }" -H "Content-Type: application/json" "http://$healthprobe_app_ip/api/healthcheck" --verbose

curl -s -X POST --data '{ "readiness": true, "liveness": true }' -H "Content-Type: application/json" "http://$healthprobe_app_ip/api/healthcheck" | jq .
curl -s -X POST --data '{ "readiness": true, "liveness": false, "livenessStatusCode": 429 }' -H "Content-Type: application/json" "http://$healthprobe_app_ip/api/healthcheck" | jq .

curl -s -X POST --data '{ "duration": 10 }' -H "Content-Type: application/json"  "http://$healthprobe_app_ip/api/resourceusage"
curl -s -X POST --data '{ "duration": 60 }' -H "Content-Type: application/json"  "http://$healthprobe_app_ip/api/resourceusage"
kubectl top pod -n healthprobe-app
kubectl get deployment -n healthprobe-app
kubectl get pod -n healthprobe-app

# PromQL queries
# sum(container_cpu_usage_seconds_total{namespace="healthprobe-app"}) by (pod) 
# sum(container_memory_working_set_bytes{namespace="healthprobe-app"}) by (pod)
# sum(container_memory_rss{namespace="healthprobe-app"}) by (pod)
# sum(container_memory_cache{namespace="healthprobe-app"}) by (pod)
az rest \
 --resource https://prometheus.monitor.azure.com \
 --method post \
 --headers "Content-Type=application/x-www-form-urlencoded" \
 --uri "$aks_monitor_prometheus_query_endpoint/api/v1/query" \
 --body 'query=sum(container_cpu_usage_seconds_total{namespace="healthprobe-app"}) by (pod)'
