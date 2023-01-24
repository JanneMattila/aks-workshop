#!/bin/bash

# Deploy webapp update application
# https://github.com/JanneMattila/webapp-update

# Command: UPDATE-1
kubectl apply -f update-app/

# Validate
# Command: UPDATE-2
kubectl get deployment -n update-app
kubectl get service -n update-app
kubectl get pod -n update-app -o custom-columns=NAME:'{.metadata.name}',NODE:'{.spec.nodeName}'
kubectl top pod -n update-app

update_app_svc_ip=$(kubectl get service update-app-svc -n update-app -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
store_variable update_app_svc_ip
echo $update_app_svc_ip

curl $update_app_svc_ip

curl $update_app_svc_ip/release.txt
curl -s $update_app_svc_ip/api/update | jq .

# Download helper test scripts
wget https://raw.githubusercontent.com/JanneMattila/webapp-update/main/doc/deployment-monitor.ps1
wget https://raw.githubusercontent.com/JanneMattila/webapp-update/main/doc/deployment-request-tester.ps1

# Use this in separate terminal
pwsh deployment-monitor.ps1 -Url http://$update_app_svc_ip/api/update -Delay 1000
pwsh deployment-request-tester.ps1 -Url http://$update_app_svc_ip/api/update -Delay 1000

# Test updating
kubectl set image deployment/update-app-deployment update-app=jannemattila/webapp-update:1.0.9 -n update-app
kubectl set image deployment/update-app-deployment update-app=jannemattila/webapp-update:1.0.10 -n update-app

kubectl edit deployment/update-app-deployment -n update-app

kubectl apply -f update-app/02-deployment.yaml

kubectl rollout --help

kubectl rollout history deployment/update-app-deployment -n update-app                # Check the history of deployments including the revision
kubectl rollout undo deployment/update-app-deployment -n update-app                   # Rollback to the previous deployment
kubectl rollout undo --to-revision=2 deployment/update-app-deployment -n update-app   # Rollback to a specific revision
kubectl rollout status -w deployment/update-app-deployment -n update-app              # Watch rolling update status of deployment until completion
kubectl rollout restart deployment/update-app-deployment -n update-app                # Rolling restart of the deployment

# TRY:
# ----
# Use "network-app" to connect to our update-app:
# HTTP GET http://update-app-svc.update-app.svc.cluster.local
#
