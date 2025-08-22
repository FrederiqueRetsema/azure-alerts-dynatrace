#!/bin/bash
#

if test -z "${DYNATRACE_API_URL}"
then
    echo "No environment variables set, run setenv.sh first"
else 

    terraform plan -var dynatrace-api-token="${DYNATRACE_API_TOKEN}" -var dynatrace-api-url="${DYNATRACE_API_URL}" -out terraform.plan 
    terraform apply terraform.plan

    cd code 
    func azure functionapp publish azure-alerts-dynatrace-fa --python
    cd ..

    date +"%Y-%m-%d %H:%M:%S"
fi
