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
curl https://raw.githubusercontent.com/evry-toolbox/acs-k8s-tools/master/createK8sCluster.sh > createK8sCluster.sh
chmod 755 createK8sCluster.sh
./createK8sCluster.sh
```
The script may take several minutes to complete. After completion, Azure may require several more minutes
before the cluster is running. You may also verify the setup in [Azure Portal](https://portal.azure.com).

### Download Kubernetes configuration

After installation, you should download credentials for the new cluster and configure the Kubernetes CLI to use them:
```
az acs kubernetes get-credentials --resource-group=myResourceGroup --name=myK8sCluster
```
Verify the connection to the cluster:
```
kubectl get nodes
```

### Upgrading Kubernetes
If required, you may at this point upgrade your Kubernetes cluster to the desired version using the
[upgrade script](https://github.com/evry-toolbox/acs-k8s-upgrade).

### Deleting the cluster

The following command will remove the resource group, container service and related resources:
```
az group delete --name myResourceGroup --yes --no-wait
```
This will take some time to be completed in Azure.

Note that the service principal created in Azure Active Directory will NOT be removed, it must be manually
deleted from the Azure Portal.

### Running the Kubernetes dashboard
Start a proxy to the Kubernetes API server on the default port (8001):
```
kubectl proxy
```
Open a web browser and navigate to the dashboard at http://localhost:8001/api/v1/namespaces/kube-system/services/kubernetes-dashboard/proxy/.
