# Azure Kubernetes Service (AKS) Workshop

Azure Kubernetes Service (AKS) Workshop

## Workshop architecture

![Workshop architecture diagram](https://user-images.githubusercontent.com/2357647/163179908-3ca8e7b0-16ab-405e-bbcf-8b1342129b37.png)

## Workshop Pre-reqs

- Azure subscription with `Owner` role
  - Why? Because we need to assign permissions e.g., `AcrPull` and others
- Azure subscription should be enabled for creating following resources:
  - Multiple Azure Virtual Networks
    - User Defined Routes (UDR)
    - Network Security Groups (NSG)
  - Private DNS Zone
  - Virtual Machine
  - Bastion Host
  - Azure Container Registry (ACR)
  - Azure Kubernetes Service (AKS)
  - Azure Container Instances (ACI)
  - Azure Storage Account
    - NFS fileshare
    - Private endpoint
  - Azure Application Gateway
  - Azure Log Analytics Workspace
- Each person should have their own dedicated resource group
  - Why? Because we need to test AKS cluster upgrades and other operations 
    that require personal environments
- [Azure Cloud Shell](https://shell.azure.com/) available
- Azure AD Group that contains all workshop participants
  - Why? Because we need have group for AKS cluster admin access
    - You only need to have `Object ID` of the group
    - You can use [My Groups](https://myaccount.microsoft.com/groups)
      to find group that you're member of. You can see `Object ID` of the group in URL.

## Usage

1. Open [Azure Cloud Shell](https://shell.azure.com/)
   - Use `Bash`
   - Use [clouddrive](https://docs.microsoft.com/en-us/azure/cloud-shell/persisting-shell-storage) folder
    for persisting files in Azure Cloud Shell
   - To prevent cloud shell for timing out, you can use following `keep_alive` trick in `00-variables.sh` script:
```bash
   while :; do echo 'Hit CTRL+C'; sleep 1; done
```
   - If cloud shell *does* timeout, then you can recover variable state using these steps:
      1. Run `00-variables.sh` to restore variable values
      2. Update authorized IP ranges to AKS:
      ```bash
      my_ip=$(curl -s https://myip.jannemattila.com)
      az aks update -g $resource_group_name -n $aks_name --api-server-authorized-ip-ranges $my_ip
      ```
      3. Get credentials for connecting to AKS:
      ```bash
      az aks get-credentials -n $aks_name -g $resource_group_name --overwrite-existing
      ```
      4. Test connectivity to API Server:
      ```bash
      kubectl get nodes
      ```
   - Alternative environment options: Use WSL or Linux
   - Pre-reqs for alternative environment: 
     - [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-linux?pivots=apt)
     - *Optional* [VS Code](https://code.visualstudio.com/)
       - Execute different script steps one-by-one in VS Code (hint: use [shift-enter](https://github.com/JanneMattila/some-questions-and-some-answers/blob/master/q%26a/vs_code.md#automation-tip-shift-enter))
2. Clone this repo 
```bash
git clone https://github.com/JanneMattila/aks-workshop.git
```
   - Good idea to clone this also to local machine for better readability and usability
3. Start deployments by opening [00-variables.sh](./00-variables.sh) and follow the instructions
