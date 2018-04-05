#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# -e: immediately exit if any command has a non-zero exit status
# -o: prevents errors in a pipeline from being masked
# IFS new value is less likely to cause confusing bugs when looping arrays or arguments (e.g. $@)

usage() { echo "Usage: $0 -i <subscriptionId> -g <resourceGroupName> -n <deploymentName> -a <agentCount> -m <masterCount> -l <resourceGroupLocation> -p <servicePrincipalPassword>" 1>&2; exit 1; }

declare subscriptionId=""
declare resourceGroupName=""
declare deploymentName=""
declare resourceGroupLocation=""
declare agentCount=""
declare masterCount=""
declare servicePrincipalPassword=""

# Initialize parameters specified from command line
while getopts ":i:g:n:c:m:l:p:" arg; do
	case "${arg}" in
		i)
			subscriptionId=${OPTARG}
			;;
		g)
			resourceGroupName=${OPTARG}
			;;
		n)
			deploymentName=${OPTARG}
			;;
		c)
			agentCount=${OPTARG}
			;;
		c)
			masterCount=${OPTARG}
			;;
		l)
			resourceGroupLocation=${OPTARG}
			;;
		p)
			servicePrincipalPassword=${OPTARG}
			;;
		esac
done
shift $((OPTIND-1))

#Prompt for parameters is some required parameters are missing
if [[ -z "$subscriptionId" ]]; then
	echo "Your subscription ID can be looked up with the CLI using: az account show --out json "
	echo "Enter your subscription ID:"
	read subscriptionId
	[[ "${subscriptionId:?}" ]]
fi

if [[ -z "$resourceGroupName" ]]; then
	echo "This script will look for an existing resource group, otherwise a new one will be created "
	echo "You can create new resource groups with the CLI using: az group create "
	echo "Enter a resource group name"
	read resourceGroupName
	[[ "${resourceGroupName:?}" ]]
fi

if [[ -z "$deploymentName" ]]; then
	echo "Enter a name for this deployment:"
	read deploymentName
fi

if [[ -z "$agentCount" ]]; then
	echo "Enter the number of Kubernetes agents to create (default 1):"
	read agentCount
fi

if [[ -z "$masterCount" ]]; then
	echo "Enter the number of Kubernetes masters to create (default 1):"
	read masterCount
fi

if [[ -z "$resourceGroupLocation" ]]; then
	echo "If creating a *new* resource group, you need to set a location "
	echo "You can lookup locations with the CLI using: az account list-locations "

	echo "Enter resource group location:"
	read resourceGroupLocation
fi

if [[ -z "$servicePrincipalPassword" ]]; then
	echo "Enter the password for the service principal to be created:"
	read servicePrincipalPassword
fi


if [ -z "$subscriptionId" ] || [ -z "$resourceGroupName" ] || [ -z "$deploymentName" ] || [ -z "$servicePrincipalPassword" ]; then
	echo "Either one of subscriptionId, resourceGroupName, deploymentName, servicePrincipalPassword is empty"
	usage
fi

if [ -z "$agentCount" ]; then
	agentCount=1
fi

if [ -z "$masterCount" ]; then
	masterCount=1
fi

#login to azure using your credentials
az account show 1> /dev/null

if [ $? != 0 ];
then
	az login
fi

#set the default subscription id
az account set --subscription $subscriptionId

set +e

appName=$deploymentName

#Check for existing RG
groupExists=`az group exists --name $resourceGroupName`

if [ "$groupExists" == "false" ]; then
	echo "Resource group with name" $resourceGroupName "could not be found. Creating new resource group.."
	set -e
	(
		set -x
		az group create --name $resourceGroupName --location $resourceGroupLocation 1> /dev/null
	)
	else
	echo "Using existing resource group..."
fi

echo "Creating service principal"
# create service principal
az ad sp create-for-rbac --name $appName --password $servicePrincipalPassword \
                --role contributor \
                --scopes /subscriptions/$subscriptionId/resourceGroups/$resourceGroupName


# get the app id of the service principal
servicePrincipalAppId=$(az ad sp list --display-name $appName --query "[].appId" -o tsv)

echo "Service principal $servicePrincipalAppId created"

# get the tenant id
tenantId=$(az account show --query tenantId -o tsv)

#Start deployment
echo "Creating kubernetes cluster..."
(
	set -x
	az acs create \
		--orchestrator-type kubernetes \
		--resource-group $resourceGroupName \
		--name $deploymentName \
		--service-principal $servicePrincipalAppId \
		--client-secret $servicePrincipalPassword \
		--agent-count $agentCount \
		--master-count $masterCount \
		--generate-ssh-keys
)
