#
# Requirements:
# - For private AKS clusters, follow these instructions
#   https://learn.microsoft.com/en-us/azure/chaos-studio/chaos-studio-private-networking
#

# Install
helm repo add chaos-mesh https://charts.chaos-mesh.org
helm repo update
kubectl create ns chaos-testing
helm install chaos-mesh chaos-mesh/chaos-mesh --namespace=chaos-testing --set chaosDaemon.runtime=containerd --set chaosDaemon.socketPath=/run/containerd/containerd.sock
kubectl get deployments -n chaos-testing
kubectl get service -n chaos-testing
kubectl get daemonsets -n chaos-testing
kubectl describe ds chaos-daemon -n chaos-testing

# To troubleshoot:
kubectl logs -n chaos-testing -l app.kubernetes.io/component=controller-manager

# Connect to Chaos Dashboard
kubectl apply -f others/chaos-studio.yaml
kubectl create token account-cluster-manager-cmicp
kubectl port-forward -n chaos-testing svc/chaos-dashboard 2333:2333

# DNS Chaos:
# https://chaos-mesh.org/docs/simulate-dns-chaos-on-kubernetes/#configuration-description
# {"action":"error","mode":"all","patterns":["bing.com","chaos-mesh.*","github.?om","login.microsoftonline.com","network-app-internal-svc.*","network-app-clusterip-svc.*","sql*"],"selector":{"namespaces":["network-app","network-app2","update-app","sql-app"]}}
# Network Chaos:
# https://chaos-mesh.org/docs/simulate-network-chaos-on-kubernetes/#
# {"action":"loss","target":{"mode":"all"},"selector":{"namespaces":["network-app","network-app2","update-app","sql-app"]},"mode":"all","direction":"to","loss":{"correlation":"100","loss":"100"},"externalTargets":["microsoft.com"]}
# {"action":"partition","target":{"mode":"all"},"selector":{"namespaces":["network-app","network-app2","update-app","sql-app"]},"mode":"all","direction":"to","externalTargets":["microsoft.com"]}

curl -X POST --data "IPLOOKUP github.com" "$network_app_external_svc_ip/api/commands"
curl -X POST --data "IPLOOKUP bing.com" "$network_app_external_svc_ip/api/commands"
curl -X POST --data "IPLOOKUP login.microsoftonline.com" "$network_app_external_svc_ip/api/commands"
curl -X POST --data "IPLOOKUP microsoft.com" "$network_app_external_svc_ip/api/commands"

curl -X POST --data "IPLOOKUP network-app-internal-svc" "$network_app_external_svc_ip/api/commands"
curl -X POST --data "IPLOOKUP network-app-internal-svc.network-app.svc.cluster.local" "$network_app_external_svc_ip/api/commands"

curl -X POST --data "IPLOOKUP network-app-clusterip-svc" "$network_app_external_svc_ip/api/commands"
curl -X POST --data "IPLOOKUP network-app-clusterip-svc.network-app.svc.cluster.local" "$network_app_external_svc_ip/api/commands"

curl -X POST --data "IPLOOKUP update-app-svc.update-app.svc.cluster.local" "$network_app_external_svc_ip/api/commands"

curl -X POST --data "HTTP GET https://login.microsoftonline.com" "$network_app_external_svc_ip/api/commands"
curl -X POST --data "HTTP GET http://network-app-internal-svc" "$network_app_external_svc_ip/api/commands"
curl -X POST --data "HTTP GET http://network-app-clusterip-svc" "$network_app_external_svc_ip/api/commands"
curl -X POST --data "HTTP GET https://microsoft.com" "$network_app_external_svc_ip/api/commands"
curl -X POST --data "HTTP GET https://github.com" "$network_app_external_svc_ip/api/commands"

# Pod Chaos:
# https://chaos-mesh.org/docs/simulate-pod-chaos-on-kubernetes/#field-description
# {"action":"pod-failure","mode":"fixed","value":"2","duration":"300s","selector":{"namespaces":["network-app"]}}
# {"action":"pod-failure","mode":"fixed-percent","value":"66","duration":"300s","selector":{"namespaces":["update-app"]}}

kubectl get pods -n network-app
list_pods network-app

kubectl get pods -n update-app
list_pods update-app

curl $network_app_external_svc_ip

curl -s $update_app_svc_ip/api/update | jq .

while true; do
    curl -s $update_app_svc_ip/api/update | jq .
done

# Availability zone chaos:
kubectl apply -f others/chaos-studio/storage-app-lrs.yaml
kubectl apply -f others/chaos-studio/storage-app-zrs.yaml
kubectl get storageclass default -o yaml # ZRS
kubectl get storageclass managed-csi-premium-lrs-sc -o yaml # LRS

kubectl get svc -n storage-app-lrs
kubectl get svc -n storage-app-zrs

kubectl get nodes
kubectl get nodes -o custom-columns=NAME:'{.metadata.name}',REGION:'{.metadata.labels.topology\.kubernetes\.io/region}',ZONE:'{metadata.labels.topology\.kubernetes\.io/zone}'

kubectl get pods -n storage-app-lrs
kubectl get pods -n storage-app-zrs

# Split view:
list_pods storage-app-lrs # Zone: x --> x
list_pods storage-app-zrs # Zone: x --> y

kubectl get pods -n storage-app-lrs -w
kubectl get pods -n storage-app-zrs -w

kubectl describe pods -n storage-app-lrs