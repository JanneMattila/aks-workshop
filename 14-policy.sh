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

kubectl get constrainttemplates k8sazurev1blockdefault -o yaml

#
# QUESTION:
# ---------
# How can you use Azure Policy to prevent creation of public load balancers?
#
