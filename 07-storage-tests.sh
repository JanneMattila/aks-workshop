#!/bin/bash

# Test that setup is correctly running
# Command: STORAGE-TESTS-1
kubectl get service -n storage-app

storage_app_ip=$(kubectl get service -n storage-app -o jsonpath="{.items[0].status.loadBalancer.ingress[0].ip}")
store_variable "storage_app_ip"
echo $storage_app_ip

curl $storage_app_ip/swagger/index.html
# -> OK!

# Quick tests for our Azure Files NFSv4.1 share:
# Command: STORAGE-TESTS-2
# - Generate files
curl -s -X POST --data '{"path": "/mnt/nfs","folders": 3,"subFolders": 5,"filesPerFolder": 10,"fileSize": 1024}' -H "Content-Type: application/json" "http://$storage_app_ip/api/generate" | jq .milliseconds
# - Enumerate files
curl -s -X POST --data '{"path": "/mnt/nfs","filter": "*.*","recursive": true}' -H "Content-Type: application/json" "http://$storage_app_ip/api/files" | jq .milliseconds

# Go to Azure Portal and study storage account.

###########################
#  _____
# | ____|__  __ ___   ___
# |  _|  \ \/ // _ \ / __|
# | |___  >  <|  __/| (__
# |_____|/_/\_\\___| \___|
# Connect to first pod
# Command: STORAGE-TESTS-3
###########################

storage_app_pod1=$(kubectl get pod -n storage-app -o name | head -n 1)
store_variable "storage_app_pod1"
echo $storage_app_pod1
kubectl exec --stdin --tty $storage_app_pod1 -n storage-app -- /bin/sh

# Run commands inside pod
mount
df -h

cd /mnt/nfs
mkdir perf-test

# Write test with 4 x 4MBs for 20 seconds
fio --directory=perf-test --direct=1 --rw=randwrite --bs=4k --ioengine=libaio --iodepth=256 --runtime=20 --numjobs=4 --time_based --group_reporting --size=4m --name=iops-test-job --eta-newline=1

# Read test with 4 x 4MBs for 20 seconds
fio --directory=perf-test --direct=1 --rw=randread --bs=4k --ioengine=libaio --iodepth=256 --runtime=20 --numjobs=4 --time_based --group_reporting --size=4m --name=iops-test-job --eta-newline=1 --readonly

# Exit container shell
exit

#################################
#     __ _____
#    / /| ____|__  __ ___   ___
#   / / |  _|  \ \/ // _ \ / __|
#  / /  | |___  >  <|  __/| (__
# /_/   |_____|/_/\_\\___| \___|
#################################

#
# QUESTION:
# ---------
# What different topics impact persistant storage overall performance?
#

#
# QUESTION:
# ---------
# Scenario:
# - You AKS deployed with Availability Zones
# - You have Azure Disk from Zone-1
# - Workload is using Azure Disk
#   - It's deployed into Zone-1
#
# What happens in AKS fails in Zone-1?
#
# More information:
# https://docs.microsoft.com/en-us/azure/aks/availability-zones#azure-disk-availability-zone-support
#
