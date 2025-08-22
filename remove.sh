#!/bin/bash
terraform destroy -var dynatrace-api-token="${DYNATRACE_API_TOKEN}" -var dynatrace-api-url="${DYNATRACE_API_URL}" -auto-approve

date +"%Y-%m-%d %H:%M:%S"
