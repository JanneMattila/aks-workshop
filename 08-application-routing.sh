# Enable Application Routing
# https://learn.microsoft.com/en-us/azure/aks/app-routing
# Command: APPROUTING-1
az aks approuting enable -g $resource_group_name -n $aks_name

# Deploy
kubectl apply -f others/app-routing/

kubectl get service -n network-app
kubectl get ingress -n network-app

kubectl describe ingress network-app-ingress2 -n network-app
ingress_ip2=$(kubectl get ingress network-app-ingress2 -n network-app -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
store_variable "ingress_ip2"
echo $ingress_ip2

curl $ingress_ip2
# -> Hello there!

az aks approuting disable -g $resource_group_name -n $aks_name
