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
kubectl apply -f storage-app/12-statefulset.yaml

kubectl get pv -n storage-app
kubectl get pvc -n storage-app

kubectl describe pv -n storage-app
kubectl describe pvc -n storage-app

# Note: Your Azure Region must support availability zones in order to use ZRS disks.
# Otherwise you'll get error:
# "message": "SKU Premium_ZRS is not supported for resource type Disk in this region. 
#             Supported SKUs for this region are Premium_LRS,StandardSSD_LRS,Standard_LRS"

kubectl get pod -n storage-app
kubectl get statefulset -n storage-app
kubectl describe statefulset -n storage-app

# QUESTION:
# ---------
# Can you explain what happens if you change the 
# replica count in our statefulset from 1 to 3?
#

# QUESTION:
# ---------
# If you run following commands:
kubectl get pv -n storage-app
kubectl get pvc -n storage-app
# Can you explain the output?
#

# QUESTION:
# ---------
# If you run following command:
kubectl delete -f storage-app/04-statefulset.yaml
# How many persistent volumes will be there after
# that command and why?
#
# More information here:
# https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/

# QUESTION:
# ---------
# If you run following command:
#   kubectl delete namespace storage-app
# What would happen?
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
