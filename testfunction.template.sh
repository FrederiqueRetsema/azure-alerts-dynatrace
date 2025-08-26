#!/bin/bash
curl -v -XPOST -d "{\"data.essentials.alertTargetIDs\":[\"/subscriptions/abcdefg1-23h4-5i67-j8k9-012lm3456no7/resourcegroups/my-resourcegroup/providers/microsoft.dbformysql/flexibleservers/my-database\"],
                    \"data.essentials.alertRuleID\":\"/subscriptions/abcdefg1-23h4-5i67-j8k9-012lm3456no7/resourceGroups/my-resourcegroup/providers/microsoft.insights/activityLogAlerts/Alert for creation of database\",
                    \"data.essentials.firedDateTime\":$(date +\"%Y-%m-%dT%H:%M:%S\"),
                    \"data.essentials.severity\":\"Sev4\"}" "https://functionappname.azurewebsites.net/send_to_dynatrace?code=A1b2CDefghIjk3L4mNopQrstuVwxyZABcDE5F6gHIjkLMnOpQRsTUv=="
date +\"%Y-%m-%dT%H:%M:%S\"

