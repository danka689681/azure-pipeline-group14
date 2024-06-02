#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Define variables
RESOURCE_GROUP="pdp_resource-group-finalc"
LOCATION="West Europe"
STORAGE_ACCOUNT_NAME="pdpstoragegroup14c"
CONTAINER_NAME="pdpstoragecontainerc"
WORKSPACE_NAME="pdp_workspace_group14c1"
EXPERIMENT_NAME="example-experiment"

CONFIG_FILE_PATH="./config-pipeline.yaml"
UPDATED_CONFIG_FILE="./updated-config-pipeline.yaml"


# Create a unique job name using the current timestamp
JOB_NAME="job_$(date +%Y%m%d%H%M%S)"

# Read the original configuration file and update the path with the full URL and unique job name
sed "s|name:.*|name: $JOB_NAME|;" $CONFIG_FILE_PATH > $UPDATED_CONFIG_FILE

# Initialize and apply Terraform configuration
terraform init
terraform apply -auto-approve

az extension add -n ml -y

# Get the storage account key
STORAGE_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP --account-name $STORAGE_ACCOUNT_NAME --query '[0].value' --output tsv)

# Set the container to public access
az storage container set-permission --account-name $STORAGE_ACCOUNT_NAME --account-key $STORAGE_KEY --name $CONTAINER_NAME --public-access container

# Upload the code to Azure Storage
az storage blob upload-batch -d $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME --account-key $STORAGE_KEY -s data --overwrite

# Submit the job using Azure CLI
echo "Submitting the job to Azure ML..."
az ml job create --file $UPDATED_CONFIG_FILE --resource-group $RESOURCE_GROUP --workspace-name $WORKSPACE_NAME


if [ $? -eq 0 ]; then
  echo "Job submission completed successfully."
else
  echo "Job submission failed."
fi

# Delete the updated configuration file
rm -f $UPDATED_CONFIG_FILE

echo "Clean up completed."