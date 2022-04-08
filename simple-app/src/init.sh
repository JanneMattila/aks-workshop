#!/usr/bin/env bash

cat >/etc/motd <<EOF
AKS Workshop
GitHub: https://github.com/JanneMattila/aks-workshop
EOF

cat /etc/motd

# Run the main application
$@