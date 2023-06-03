# Apply log and prometheus data collection settings 
kubectl apply -f others/container-azm-ms-agentconfig.yaml

# Read more about different configuration options:
# https://github.com/microsoft/Docker-Provider/blob/ci_dev/kubernetes/container-azm-ms-agentconfig.yaml

kubectl apply -f monitoring-app/

kubectl get service -n monitoring-app

monitoring_app_ip=$(kubectl get service -n monitoring-app -o jsonpath="{.items[0].status.loadBalancer.ingress[0].ip}")
store_variable "monitoring_app_ip"
echo $monitoring_app_ip

curl $monitoring_app_ip

#
# Study Container Insights
#
# More information here:
# https://learn.microsoft.com/en-us/azure/azure-monitor/containers/container-insights-overview
# https://learn.microsoft.com/en-us/azure/azure-monitor/containers/container-insights-prometheus-integration
# https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/prometheus-metrics-scrape-configuration

#
# Study KQL queries
#
# More information here:
# https://docs.microsoft.com/en-us/azure/azure-monitor/containers/container-insights-log-query
