#!/bin/bash

###################
#          _ 
#  ___ ___| |__
# / __/ __| '_ \
# \__ \__ \ | | |
# |___/___/_| |_|
# to jumpbox 
###################

# Echo important variables
echo "Environment vars->"
echo network_app_internal_svc_ip=\"$network_app_internal_svc_ip\"
echo network_app_pod1_ip=\"$network_app_pod1_ip\"
echo aci_ip=\"$aci_ip\"
echo "<-Environment vars"

echo $vm_password

# Command: NETWORK-TESTING-1
az network bastion ssh --name $bastion_name --resource-group $resource_group_name --target-resource-id $vm_id --auth-type "password" --username $vm_username

# Copy above "Environment vars" section and paste them to the console.

# Try to connect 
# Command: NETWORK-TESTING-2
curl $network_app_internal_svc_ip
# -> <html><body>Hello
curl $network_app_pod1_ip
# -> <html><body>Hello
curl $aci_ip
# -> <html><body>Hello

# QUESTION:
# ---------
# What did above test proove?
#

#
# Below is using following application for network testing:
# https://github.com/JanneMattila/webapp-network-tester
#

# Test outbound internet accesses
# Command: NETWORK-TESTING-3
BODY=$(echo "HTTP GET \"https://github.com\"")
curl -X POST --data "$BODY" -H "Content-Type: text/plain" "$network_app_internal_svc_ip/api/commands" # OK
curl -X POST --data "$BODY" -H "Content-Type: text/plain" "$aci_ip/api/commands" # OK

# Test spoke001 -> spoke002 connectivity
# Command: NETWORK-TESTING-4
curl -X POST --data  "HTTP GET \"http://$network_app_internal_svc_ip\"" -H "Content-Type: text/plain" "$aci_ip/api/commands" # Timeout
# Test spoke002 -> spoke001 connectivity
curl -X POST --data  "HTTP GET \"http://$aci_ip\"" -H "Content-Type: text/plain" "$network_app_internal_svc_ip/api/commands" # Timeout

# Exit jumpbox
exit

# QUESTION:
# ---------
# Why did above spoke-to-spoke tests timeout?
#

# QUESTION:
# ---------
# What are differences between User-Defined Routes (UDR) and 
# Network Security Groups (NSG)?
#
# Extra "Exercise 1" in "90-bonus-exercises.sh".
# Extra "Exercise 2" in "90-bonus-exercises.sh".
#

# QUESTION:
# ---------
# What are our options to enable spoke-to-spoke connectivity?
#
# Extra "Exercise 2" in "90-bonus-exercises.sh".
#
