#!/bin/bash

az aks enable-addons -g $resource_group_name -n $aks_name \
 --appgw-name $agic_name \
 --appgw-subnet-id $vnet_spoke2_agic_subnet_id

kubectl apply -f others/ingress.yaml

kubectl get service -n network-app
kubectl get ingress -n network-app

kubectl get ingress -n network-app -o json
ingress_ip=$(kubectl get ingress -n network-app -o jsonpath="{.items[0].status.loadBalancer.ingress[0].ip}")
echo $ingress_ip

curl $ingress_ip
# -> <html><body>Hello there!</body></html>

#
# Read more:
# https://github.com/Azure/application-gateway-kubernetes-ingress
# https://github.com/Azure/application-gateway-kubernetes-ingress/blob/master/docs/annotations.md
#