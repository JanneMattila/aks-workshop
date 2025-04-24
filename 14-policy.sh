#
# Azure Policy
##
# https://learn.microsoft.com/en-us/azure/governance/policy/concepts/policy-for-kubernetes
#

# azure-policy pod is installed in kube-system namespace
kubectl get pods -n kube-system

# gatekeeper pod is installed in gatekeeper-system namespace
kubectl get pods -n gatekeeper-system

kubectl get constrainttemplates

kubectl get constrainttemplates k8sazurev2noprivilege -o yaml

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: privileged-pod
spec:
  containers:
    - name: nginx
      image: nginx
      securityContext:
        privileged: true
EOF

# Error from server (Forbidden): 
# error when creating "STDIN": 
# admission webhook "validation.gatekeeper.sh" 
# denied the request: [azurepolicy-k8sazurev2noprivilege-0abdd17e1c6494e77e21]
# Privileged container is not allowed: nginx, securityContext: {"privileged": true}

#
# QUESTION:
# ---------
# How can you use Azure Policy to prevent creation of public load balancers?
#
