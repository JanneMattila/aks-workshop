#!/bin/bash

# Import images
# Command: REGISTRY-1
az acr import -n $acr_name -t "apps/jannemattila/webapp-fs-tester:1.1.7" --source "docker.io/jannemattila/webapp-fs-tester:1.1.7" 

############################
# Import vulnerable images
# --
# More images:
# https://hub.docker.com/u/vulnerables
############################
# Command: REGISTRY-2
az acr import -n $acr_name -t "bad/dotnet/core/sdk:2.2.401" --source "mcr.microsoft.com/dotnet/core/sdk:2.2.401" 
az acr import -n $acr_name -t "bad/vulnerables/web-dvwa" --source "docker.io/vulnerables/web-dvwa" 
az acr import -n $acr_name -t "bad/vulnerables/metasploit-vulnerability-emulator" --source "docker.io/vulnerables/metasploit-vulnerability-emulator" 
az acr import -n $acr_name -t "bad/vulnerables/cve-2017-7494" --source "docker.io/vulnerables/cve-2017-7494" 
az acr import -n $acr_name -t "bad/vulnerables/mail-haraka-2.8.9-rce" --source "docker.io/vulnerables/mail-haraka-2.8.9-rce" 
############################
# /Import vulnerable images
############################

# Enable "Defender for Containers" in the Portal

# Study ACR in Portal
