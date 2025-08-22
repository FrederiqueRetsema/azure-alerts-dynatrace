#!/bin/bash
az login --tenant "${AZURE_TENANT_ID}"
terraform init

date +"%Y-%m-%d %H:%M:%S"
