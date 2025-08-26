#!/bin/bash

if test -z "${DYNATRACE_API_URL}"
then
    echo "No environment variables set, run setenv.sh first"
else 

    terraform destroy -var dynatrace-api-token="${DYNATRACE_API_TOKEN}" -var dynatrace-api-url="${DYNATRACE_API_URL}" -auto-approve

fi

date +"%Y-%m-%d %H:%M:%S"
