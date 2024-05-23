# Install
helm repo add chaos-mesh https://charts.chaos-mesh.org
helm repo update
kubectl create ns chaos-testing
helm install chaos-mesh chaos-mesh/chaos-mesh --namespace=chaos-testing --set chaosDaemon.runtime=containerd --set chaosDaemon.socketPath=/run/containerd/containerd.sock

kubectl get pods -n chaos-testing

# DNS Chaos:
# https://chaos-mesh.org/docs/simulate-dns-chaos-on-kubernetes/#configuration-description
# {"action":"error","mode":"all","patterns":["bing.com","chaos-mesh.*","github.?om","login.microsoftonline.com","network-app-internal-svc.*"],"selector":{"namespaces":["network-app","network-app2","update-app"]}}

curl -X POST --data "IPLOOKUP github.com" "$network_app_external_svc_ip/api/commands"
curl -X POST --data "IPLOOKUP bing.com" "$network_app_external_svc_ip/api/commands"
curl -X POST --data "IPLOOKUP login.microsoftonline.com" "$network_app_external_svc_ip/api/commands"
curl -X POST --data "IPLOOKUP microsoft.com" "$network_app_external_svc_ip/api/commands"

curl -X POST --data "IPLOOKUP network-app-internal-svc" "$network_app_external_svc_ip/api/commands"
curl -X POST --data "IPLOOKUP network-app-internal-svc.network-app.svc.cluster.local" "$network_app_external_svc_ip/api/commands"

curl -X POST --data "IPLOOKUP update-app-svc.update-app.svc.cluster.local" "$network_app_external_svc_ip/api/commands"

# Pod Chaos:
# https://chaos-mesh.org/docs/simulate-pod-chaos-on-kubernetes/#field-description
# {"action":"pod-failure","mode":"fixed","value":"2","duration":"300s","selector":{"namespaces":["network-app"]}}
# {"action":"pod-failure","mode":"fixed-percent","value":"66","duration":"300s","selector":{"namespaces":["update-app"]}}

kubectl get pods -n network-app
kubectl get pods -n update-app

curl $network_app_external_svc_ip

curl -s $update_app_svc_ip/api/update | jq .

while true; do
    curl -s $update_app_svc_ip/api/update | jq .
done

# Availability zone chaos:
kubectl get nodes
kubectl get pods -n update-app
list_pods update-app
