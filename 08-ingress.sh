#!/bin/bash

# Enable Application Gateway Ingress Controller (AGIC)
# Command: INGRESS-1
az aks enable-addons -g $resource_group_name -n $aks_name \
 --addons ingress-appgw \
 --appgw-name $agic_name \
 --appgw-subnet-id $vnet_spoke2_agic_subnet_id

# Validate deployment
kubectl apply -f others/ingress.yaml

kubectl get service -n network-app
kubectl get ingress -n network-app

kubectl describe ingress network-app-ingress -n network-app
ingress_ip=$(kubectl get ingress -n network-app -o jsonpath="{.items[0].status.loadBalancer.ingress[0].ip}")
echo $ingress_ip

curl $ingress_ip
# -> <html><body>Hello there!</body></html>

#
# Study Web Application Firewall (WAF) capabilities of Application Gateway.
#
# https://docs.microsoft.com/en-us/azure/web-application-firewall/ag/ag-overview
#

#
# More information here:
# https://github.com/Azure/application-gateway-kubernetes-ingress
# https://github.com/Azure/application-gateway-kubernetes-ingress/blob/master/docs/annotations.md
#
