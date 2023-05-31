# Azure Kubernetes Service (AKS) Workshop

Azure Kubernetes Service (AKS) Workshop

## Workshop architecture

![Workshop architecture diagram](https://user-images.githubusercontent.com/2357647/163179908-3ca8e7b0-16ab-405e-bbcf-8b1342129b37.png)

## Usage

1. Open [Azure Cloud Shell](https://shell.azure.com/)
   - Use `Bash`
   - Use [clouddrive](https://docs.microsoft.com/en-us/azure/cloud-shell/persisting-shell-storage) folder
    for persisting files in Azure Cloud Shell
   - To prevent cloud shell for timing out, you can use `while :; do echo 'Hit CTRL+C'; sleep 1; done` trick
   - If cloud shell *does* timeout, then you can recover variable state by running `source saved_variables.sh`
   - Alternative environment options: Use WSL or Linux
   - Pre-reqs for alternative environment: 
     - [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-linux?pivots=apt)
     - *Optional* [VS Code](https://code.visualstudio.com/)
       - Execute different script steps one-by-one in VS Code (hint: use [shift-enter](https://github.com/JanneMattila/some-questions-and-some-answers/blob/master/q%26a/vs_code.md#automation-tip-shift-enter))
2. Clone this repo ```git clone https://github.com/JanneMattila/aks-workshop.git```
   - Good idea to clone this also to local machine for better readability and usability
3. Start deployments by opening [00-variables.sh](./00-variables.sh) and follow the instructions
