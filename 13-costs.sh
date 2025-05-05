#
# Use Azure Cost Management in the portal and analyze your environment costs.
#

#
# Use Azure Pricing Calculator for evaluating one deployment environment
# https://azure.microsoft.com/en-us/pricing/calculator/
#

# Enable cost analysis in AKS
# If not enabled in the beginning (--enable-cost-analysis).
# Command: COSTS-1
az aks update  \
  -g $resource_group_name \
  -n $aks_name \
  --enable-cost-analysis
