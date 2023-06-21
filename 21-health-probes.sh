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
kubectl get service -n healthprobe-app

healthprobe_app_ip=$(kubectl get service healthprobe-app-svc -n healthprobe-app -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
store_variable healthprobe_app_ip
echo $healthprobe_app_ip

curl $healthprobe_app_ip
curl -s $healthprobe_app_ip/api/healthcheck | jq .
curl -s $healthprobe_app_ip/api/healthcheck/readiness --verbose

curl -s -X POST --data '{ "readiness": true, "liveness": true }' "http://$healthprobe_app_ip/api/healthcheck" | jq .

healthprobe_app_server=$(curl -s $healthprobe_app_ip/api/healthcheck | jq -r .server)
echo $healthprobe_app_server

curl -s -X POST --data "{ \"shutdown\": true, \"condition\": \"$healthprobe_app_server\" }" -H "Content-Type: application/json"  "http://$healthprobe_app_ip/api/healthcheck" --verbose

curl -s -X POST --data '{ "readiness": true, "liveness": true }' -H "Content-Type: application/json"  "http://$healthprobe_app_ip/api/healthcheck" | jq .
