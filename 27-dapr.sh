# https://docs.dapr.io/operations/hosting/kubernetes/kubernetes-deploy/#install-dapr-from-the-official-dapr-helm-chart-with-development-flag

helm repo add dapr https://dapr.github.io/helm-charts/

helm repo update
helm search repo dapr --devel --versions

helm upgrade --install dapr dapr/dapr \
 --version=1.15.11 \
 --namespace dapr-system \
 --create-namespace \
 --set global.ha.enabled=true \
 --wait
