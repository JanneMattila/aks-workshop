#####################
#  ____  _     _    
# |  _ \(_)___| | __
# | | | | / __| |/ /
# | |_| | \__ \   < 
# |____/|_|___/_|\_\
# 
# Command: STORAGE-PART2-1
kubectl apply -f storage-app/10-azuredisk-sc.yaml
kubectl apply -f storage-app/11-persistent-volume-claim-disk.yaml

# Delete previous statefulset
kubectl delete -f storage-app/04-statefulset.yaml
# If you don't delete it, then next command would fail with error:
# The StatefulSet "storage-app-deployment" is invalid: 
# spec: Forbidden: updates to statefulset spec for fields other than 
# 'replicas', 'template', 'updateStrategy', 'persistentVolumeClaimRetentionPolicy' 
# and 'minReadySeconds' are forbidden

# Command: STORAGE-PART2-2
kubectl apply -f storage-app/12-statefulset.yaml

kubectl get statefulset -n storage-app
kubectl get pod -n storage-app
kubectl describe pod -n storage-app

kubectl get pv -n storage-app
kubectl get pvc -n storage-app

kubectl describe pv -n storage-app
kubectl describe pvc -n storage-app

# Note: Your Azure Region must support availability zones in order to use ZRS disks.
# Otherwise you'll get error:
# "message": "SKU Premium_ZRS is not supported for resource type Disk in this region. 
#             Supported SKUs for this region are Premium_LRS,StandardSSD_LRS,Standard_LRS"

kubectl get pod -n storage-app
kubectl describe pod -n storage-app
kubectl get statefulset -n storage-app
kubectl describe statefulset -n storage-app

# Quick tests for our Azure Disk:
# Command: STORAGE-PART2-3
# - Generate files
curl -s -X POST --data '{"path": "/mnt/premiumdisk","folders": 2,"subFolders": 3,"filesPerFolder": 5,"fileSize": 1024}' -H "Content-Type: application/json" "http://$storage_app_ip/api/generate" | jq .
# - Enumerate files
curl -s -X POST --data '{"path": "/mnt/premiumdisk","filter": "*.*","recursive": true}' -H "Content-Type: application/json" "http://$storage_app_ip/api/files" | jq .

# QUESTION:
# ---------
# Are there any resources created to the "MC_" resource group
# from this Azure Disk deployment?
#

# Go to Azure Portal and study:
# - "MC_" resource group
# - Azure Disk
# - AKS resource & Storage from blade
# - Open in Browser below address and generate some data to disk:
echo "http://$storage_app_ip/swagger"
# etc.

# QUESTION:
# ---------
# Can I freely adjust Azure Disk settings (size, performance) in portal?
#

# QUESTION:
# ---------
# Can you explain what happens if you change the 
# replica count in our statefulset from 1 to 3?
#
# Test and verify your answer.
#
# Hint: You can use following command to scale statefulset:
kubectl scale statefulset storage-app-deployment -n storage-app --replicas=3

# QUESTION:
# ---------
# Is data automatically synchronized between pods?
#

# QUESTION:
# ---------
# If you run following commands:
kubectl get pv -n storage-app
kubectl get pvc -n storage-app
# Can you explain the output?
#
# You can analyze these also in AKS resource & Storage blade in Azure Portal
#

# QUESTION:
# ---------
# If you run following command:
#   kubectl delete -f storage-app/12-statefulset.yaml
# How many persistent volumes will be there after
# that command and why?
#
# More information here:
# https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/
#

# QUESTION:
# ---------
# If you run following command:
#   kubectl delete namespace storage-app
# What would happen and why?
#
# DON'T RUN THAT COMMAND!
#

###########################
#  _____
# | ____|__  __ ___   ___
# |  _|  \ \/ // _ \ / __|
# | |___  >  <|  __/| (__
# |_____|/_/\_\\___| \___|
# Connect to first pod
# Command: STORAGE-PART2-2
storage_app_pod1=$(kubectl get pod -n storage-app -o name | head -n 1)
store_variable "storage_app_pod1"
echo $storage_app_pod1
kubectl exec --stdin --tty $storage_app_pod1 -n storage-app -- /bin/sh

# Run commands inside pod
mount
df -h

cd /mnt
ls -lF

cd /mnt/nfs
cd /mnt/premiumdisk
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

#
# QUESTION:
# ---------
# You have large volume with a lots of files in it.
# You start to experience slow startup times for your application.
#
# Why?
#
# More information:
# https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#configure-volume-permission-and-ownership-change-policy-for-pods
# https://learn.microsoft.com/en-us/troubleshoot/azure/azure-kubernetes/fail-to-mount-azure-disk-volume#cause-changing-ownership-and-permissions-for-large-volume-takes-much-time
#
