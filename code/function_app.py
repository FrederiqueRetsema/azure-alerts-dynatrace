import azure.functions as func

import logging
import requests
import json
import os

from azure.identity import ManagedIdentityCredential
from azure.keyvault.secrets import SecretClient 

AZURE_KEYVAULT_NAME = "dynatrace-api"

#app = func.FunctionApp(http_auth_level=func.AuthLevel.FUNCTION)
app = func.FunctionApp()

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def create_new_prefix(prefix: str, keyword: str) -> str:
  if prefix == "":
    prefix = keyword
  else: 
    prefix = prefix + "." + keyword

  return prefix


def act_on_item(prefix: str, i):
  if type(i) == list:
    i = walk_list(prefix, i)
  if type(i) == dict:
    i = walk_dict(prefix, i)

  return i


def walk_list(prefix: str, l: list) -> list:
  new_l = []
  for item in l:
    new_l.append(act_on_item(prefix, item))

  return new_l


def walk_dict(prefix: str, d: dict) -> dict:
  new_d = {}
  for keyword in d.keys():
    new_prefix = create_new_prefix(prefix, keyword)
    new_d[new_prefix] = act_on_item(new_prefix, d[keyword])

  return new_d


def flatten(d: dict) -> dict:
  found_dict = False
  new_d = {}
  for keyword in d.keys():
    if type(d[keyword]) == dict:
      new_d = new_d | d[keyword]
      found_dict = True
    else:
      new_d[keyword] = d[keyword]      

  if found_dict:
    return flatten(new_d)
  else:
    return new_d


def get_severity(azure_severity: str) -> str:  
    new_severity = "NONE"

    match azure_severity:
      case "Sev4": new_severity = "debug"     # Azure: 4 - Verbose
      case "Sev3": new_severity = "info"      # Azure: 3 - Informational
      case "Sev2": new_severity = "warn"      # Azure: 2 - Warning
      case "Sev1": new_severity = "error"     # Azure: 1 - Error
      case "Sev0": new_severity = "emergency" # Azure: 0 - Critical

    return new_severity


def get_body_dict_from_request(req: func.HttpRequest) -> dict:
    req_body = {}
    try:
        req_body = req.get_json()
    except ValueError:
        pass
    else:
        pass

    return req_body


def get_dynatrace_url_and_token(vault_name : str) -> {str, str}:

  dynatrace_api_url = ""
  dynatrace_api_token = ""

  try:
    vault_url = "https://{0}.vault.azure.net".format(vault_name)
    user_managed_identity_id = os.environ["USER_MANAGED_IDENTITY_ID"]  

    credential = ManagedIdentityCredential(client_id=user_managed_identity_id) 
    client = SecretClient(vault_url=vault_url,
                          credential=credential)

    dynatrace_api_url = client.get_secret("dynatrace-api-url").value
    dynatrace_api_token = client.get_secret("dynatrace-api-token").value

  except Exception as E:
    logger.error("Error in getting data from keyvault: {0}".format(E))
    raise(E)

  return {"dynatrace_api_url": dynatrace_api_url, "dynatrace_api_token": dynatrace_api_token}


# Main

@app.function_name(name="SendToDynatrace")
@app.route(route="send_to_dynatrace")
def  send_to_dynatrace(req: func.HttpRequest) -> func.HttpResponse:

    body_dict = get_body_dict_from_request(req)
    logger.info("body_dict: {0}".format(body_dict))

    dynatrace_api_and_token = get_dynatrace_url_and_token(AZURE_KEYVAULT_NAME)
    dynatrace_api_url = dynatrace_api_and_token["dynatrace_api_url"]
    dynatrace_api_token = dynatrace_api_and_token["dynatrace_api_token"]

    # Change key values in something Dynatrace recognizes: no nested = flattened json
    dict_with_new_names = walk_dict("", body_dict)
    flattened_dict = flatten(dict_with_new_names)
    logger.info("flattened_dict: {0}".format(flattened_dict))

    # Add some keys that are needed by log lines that are inserted by the Log Monitoring API

    flattened_dict["timestamp"] = flattened_dict["data.essentials.firedDateTime"]
    flattened_dict["severity"] = get_severity(flattened_dict["data.essentials.severity"])
    flattened_dict["log.source"] = "Azure Monitoring Alert"
    logger.info("added keys to flattened_dict: {0}".format(flattened_dict))

    # Send it to Dynatrace

    logger.info("Send to url: {0}".format(dynatrace_api_url))
    headers = {"Content-Type":"application/json; charset=utf-8",
               "Authorization": "Api-Token " + dynatrace_api_token}

    try:
        request_to_dynatrace = requests.post(dynatrace_api_url,
                                             headers=headers,
                                             data=json.dumps(flattened_dict))
    except Exception as E:
        logger.error("Error in getting data from keyvault: {0}".format(E))

        raise(E)

    logger.info("Status code POST request: {0}".format(request_to_dynatrace.status_code))
    logger.info("Content POST request: {0}".format(request_to_dynatrace.content))
    logger.info("Raw data POST request: "+str(request_to_dynatrace.raw))

    return func.HttpResponse("Result of sending data to Dynatrace: ", status_code=request_to_dynatrace.status_code)

# import azure.functions as  func
# import logging
# import requests
# import json
# import os

# app = func.FunctionApp()

# @app.function_name(name="SendToDynatrace")
# @app.route(route="send_to_dynatrace")
# def  send_to_dynatrace(req: func.HttpRequest) -> func.HttpResponse:
#   logging.info(message="Test")
#   r = requests.post("https://pipos.free.beeceptor.com",
#                     data=str(os.environ))

#   return  func.HttpResponse("HttpTrigger1 function processed a request!!!")    
