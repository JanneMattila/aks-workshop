# Apply log and prometheus data collection settings 
kubectl apply -f others/container-azm-ms-agentconfig.yaml

# Read more about different configuration options:
# https://github.com/microsoft/Docker-Provider/blob/ci_dev/kubernetes/container-azm-ms-agentconfig.yaml

kubectl apply -f monitoring-app/

#
# Study Container Insights
#
# More information here:
# https://docs.microsoft.com/en-us/azure/azure-monitor/containers/container-insights-overview
# https://docs.microsoft.com/en-us/azure/azure-monitor/containers/container-insights-prometheus-integration

#
# Study KQL queries
#
# More information here:
# https://docs.microsoft.com/en-us/azure/azure-monitor/containers/container-insights-log-query
