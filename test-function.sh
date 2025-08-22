#!/bin/bash
curl -v -XPOST -d "{\"data.essentials.firedDateTime\":$(date +\"%Y-%m-%dT%H:%M:%S\"),\"data.essentials.severity\":\"Sev4\"}" "https://azure-alerts-dynatrace-fa.azurewebsites.net/send_to_dynatrace?code=functionkey
date +\"%Y-%m-%dT%H:%M:%S\"

# {"data.essentials.firedDateTime":"2025-08-22T12:46:00", "data.essentials.severity":"Sev4"}

