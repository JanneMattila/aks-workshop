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

#########################
# Internal only ingress
#########################
# Remove existing public ingress
kubectl delete -f others/app-routing/02-ingress.yaml

# Deploy internal ingress
kubectl apply -f others/app-routing/01-service.yaml
kubectl apply -f others/app-routing/internal/

kubectl get ingress -n network-app

kubectl describe ingress network-app-ingress3 -n network-app
private_ingress_ip=$(kubectl get ingress network-app-ingress3 -n network-app -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
store_variable "private_ingress_ip"
echo $private_ingress_ip

# We cannot directly test this so let's use our web app network tester
curl -X POST --data "HTTP GET \"http://$private_ingress_ip\"" "$network_app_external_svc_ip/api/commands"

az aks approuting disable -g $resource_group_name -n $aks_name
