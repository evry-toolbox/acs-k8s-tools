# acs-k8s-tools

## Install Kubernetes cluster on Azure Container Services (ACS)

The script creates a resource group and installs a vanilla Kubernetes cluster in Azure.

### Disclaimer

**This is performed at own risk.**


### Prerequisites

The user running the script must have permissions in Azure to create new resource groups.
You must have [Microsoft Azure CLI 2.0](https://github.com/Azure/azure-cli) installed on your computer.
You must also install the Kubernetes CLI. If Azure CLI is installed, you can install Kubernetes CLI as follows:
```
az acs kubernetes install-cli
```

Before running the script, you must be logged on to the relevant Azure tenant.
```
az login
```
After logging in, you should verify that you are logged on to the correct tenant:
```
az account show
```
Look for the "id" field - this is the subscriptionId that should be used when running the script.

### What it does

The script will do the following:
* Create a new Azure resource group, unless it already exists
* Create a Service Principal in Azure Active Directory for the Kubernetes cluster
* Create a Kubernetes cluster with a given number of master and agent nodes.

### Execute

Run this script on your client computer:
```
curl https://raw.githubusercontent.com/evry-toolbox/acs-k8s-tools/master/createK8sCluster.sh | sudo bash
```
