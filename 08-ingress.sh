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
store_variable "ingress_ip"
echo $ingress_ip

curl $ingress_ip
# -> <html><body>Hello there!</body></html>

#
# Study Web Application Firewall (WAF) capabilities of Application Gateway.
#
# More information here:
# https://docs.microsoft.com/en-us/azure/web-application-firewall/ag/ag-overview
# https://docs.microsoft.com/en-us/azure/application-gateway/tutorial-ingress-controller-add-on-new#deploy-an-aks-cluster-with-the-add-on-enabled

#
# Study Application Gateway Ingress Controller (AGIC) configuration options.
#
# More information here:
# https://github.com/Azure/application-gateway-kubernetes-ingress
# https://github.com/Azure/application-gateway-kubernetes-ingress/blob/master/docs/annotations.md
#

#
# QUESTION:
# ---------
# AKS has "extensions" and "add-ons" which are both
# supported ways to add functionality to your cluster.
#
# What are the differencies between these two?
#
# More information here:
# https://docs.microsoft.com/en-us/azure/aks/integrations
#
