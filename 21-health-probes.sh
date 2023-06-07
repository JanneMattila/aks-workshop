# Deploy health probe demo application
# https://github.com/JanneMattila/KubernetesProbeDemo

# Command: HEALTH-PROBE-1
kubectl apply -f healthprobe-app/

# Validate
# Command: HEALTH-PROBE-2
kubectl get deployment -n healthprobe-app
kubectl get service -n healthprobe-app
kubectl get pod -n healthprobe-app -o custom-columns=NAME:'{.metadata.name}',NODE:'{.spec.nodeName}'
kubectl top pod -n healthprobe-app

healthprobe_app_svc_ip=$(kubectl get service healthprobe-app-svc -n healthprobe-app -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
store_variable healthprobe_app_svc_ip
echo $healthprobe_app_svc_ip

curl $healthprobe_app_svc_ip
curl -s $healthprobe_app_svc_ip/api/healthcheck | jq .

curl -s -X POST --data '{ "readiness": true, "liveness": true }' -H "Content-Type: application/json" "http://$healthprobe_app_svc_ip/api/healthcheck" | jq .

curl -s -X POST --data '{ "shutdown": true }' -H "Content-Type: application/json" "http://$healthprobe_app_svc_ip/api/healthcheck" | jq .

curl -s -X POST --data '{ "readiness": true, "liveness": true }' -H "Content-Type: application/json" "http://$healthprobe_app_svc_ip/api/healthcheck" | jq .
