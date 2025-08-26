#!/bin/bash

SUBSCRIPTION_ID="abcdefg1-23h4-5i67-j8k9-012lm3456no7"
RESOURCE_GROUP_NAME="my-resourcegroup"
ALERT_NAME="Alert for creation of database"
CURRENT_TIME=$(date +"%Y-%m-%dT%H:%M:%S")
FUNCTION_APP_NAME="functionappname"
FUNCTION_APP_TOKEN="A1b2CDefghIjk3L4mNopQrstuVwxyZABcDE5F6gHIjkLMnOpQRsTUv=="

curl -v -XPOST -d "{\"data.essentials.alertTargetIDs\":[\"/subscriptions/${SUBSCRIPTION_ID}/resourcegroups/${RESOURCE_GROUP_NAME}/providers/microsoft.dbformysql/flexibleservers/frederique-wordpress-b1ms\"],
                    \"data.essentials.alertRuleID\":\"/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}/providers/microsoft.insights/activityLogAlerts/${ALERT_NAME}\",
                    \"data.essentials.firedDateTime\":${CURRENT_TIME},
                    \"data.essentials.severity\":\"Sev4\"}" "https://${FUNCTION_APP_NAME}.azurewebsites.net/send_to_dynatrace?code=${FUNCTION_APP_TOKEN}"
date +\"%Y-%m-%dT%H:%M:%S\"

