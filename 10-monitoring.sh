#!/bin/bash

# Apply log and prometheus data collection settings 
kubectl apply -f others/container-azm-ms-agentconfig.yaml

# Read more about different configuration options:
# https://github.com/microsoft/Docker-Provider/blob/ci_dev/kubernetes/container-azm-ms-agentconfig.yaml

kubectl apply -f monitoring-app/

# Use Container Insights.

# Use Log Analytics workspace and learn KQL queries.

# More information: 
# https://github.com/JanneMattila/playground-aks-monitoring
