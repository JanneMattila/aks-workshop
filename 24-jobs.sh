#########################################
#                        _       _     
#   ___ _ __ ___  _ __  (_) ___ | |__  
#  / __| '__/ _ \| '_ \ | |/ _ \| '_ \ 
# | (__| | | (_) | | | || | (_) | |_) |
#  \___|_|  \___/|_| |_|/ |\___/|_.__/ 
#                     |__/         
#########################################

kubectl apply -f others/echoer-cronjob.yaml

kubectl get cronjob
kubectl get pod

cronjob_app_pod1=$(kubectl get pod -o name | tail -n 1)
echo $cronjob_app_pod1

kubectl logs $cronjob_app_pod1

kubectl delete -f others/echoer-cronjob.yaml
