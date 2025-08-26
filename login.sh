#!/bin/bash
if test -z "${DYNATRACE_API_URL}"
then
    echo "No environment variables set, run setenv.sh first"
else 

    az login --tenant "${AZURE_TENANT_ID}"
    terraform init
fi

date +"%Y-%m-%d %H:%M:%S"
