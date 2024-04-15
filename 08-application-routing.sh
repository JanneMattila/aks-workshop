# Enable Application Routing
# https://learn.microsoft.com/en-us/azure/aks/app-routing
# Command: APPROUTING-1
az aks approuting enable -g $resource_group_name -n $aks_name

# Deploy
kubectl apply -f others/app-routing/

kubectl get service -n network-app
kubectl get ingress -n network-app

kubectl describe ingress network-app-ingress -n network-app
ingress_ip=$(kubectl get ingress -n network-app -o jsonpath="{.items[0].status.loadBalancer.ingress[0].ip}")
store_variable "ingress_ip"
echo $ingress_ip

curl $ingress_ip
# -> Hello there!

az aks approuting disable -g $resource_group_name -n $aks_name
