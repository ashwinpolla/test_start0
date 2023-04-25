namespace: Cerner.DFMP.Schedulers.SMAX.Operations
operation:
  name: jiraIssueStatusUpdateSMAX
  inputs:
    - MP_jiraIssueURL: "${get_sp('MarketPlace.jiraIssueURL')}"
    - MP_jiraUser: "${get_sp('MarketPlace.jiraUser')}"
    - MP_jiraPassword: "${get_sp('MarketPlace.jiraPassword')}"
    - smax_Url: "${get_sp('MarketPlace.smaxURL')}"
    - smax_tenantId: "${get_sp('MarketPlace.tenantID')}"
    - smax_Token
    - projectNames: "${get_sp('MarketPlace.jiraProjects')}"
    - creator: "${get_sp('MarketPlace.jiraIssueCreator')}"
    - lastUpdate:
        required: false
    - smax_FieldID:
        required: false
    - jira_IncidentCategory_FieldId:
        required: false
    - jira_RequestCategory_FieldId:
        required: false
    - conn_timeout: "${get_sp('Cerner.DigitalFactory.connection_timeout')}"
    - http_fail_status_codes: "${get_sp('Cerner.DigitalFactory.http_fail_status_codes')}"
    - smax_jirasmaxid_list:
        required: false
    - previous_errorLogs:
        required: false
  python_action:
    use_jython: false
    script: "##############################################################\r\n#   OO operation for sync of Jira and Smax for Jira Issues\r\n#   Operation: jiraIssueStatusUpdateSMAX\r\n#   Author: Rakesh Sharma (rakesh.sharma@cerner.com)\r\n#   Created on: 19 May 2022\r\n#   Updated on: 07 Sep 2022\r\n#   Inputs:\r\n#       -  MP_jiraIssueURL\r\n#       -  MP_jiraUser\r\n#       -  MP_jiraPassword\r\n#       -  smax_Url\r\n#       -  smax_tenantId\r\n#       -  smax_Token\r\n#       -  projectNames\r\n#       -  creator\r\n#       -  lastUpdate\r\n#       -  smax_FieldID\r\n#       -  jira_IncidentCategory_FieldId\r\n#       -  jira_RequestCategory_FieldId\r\n#       -  conn_timeout\r\n#       -  http_fail_status_codes\r\n#       -  smax_jirasmaxid_list\r\n#       -  previous_errorLogs\r\n#\r\n#   Outputs:\r\n#       - result\r\n#       - message\r\n#       - errorType\r\n#       - errorSeverity\r\n#       - errorProvider\r\n#       - errorMessage\r\n#       - errorLogs\r\n#       - provider_failure\r\n#       - jiraIssueStatus\r\n\r\n###############################################################\r\nimport sys, os\r\nimport subprocess\r\n\r\n\r\n# function do download external modules to python \"on-the-fly\"\r\ndef install(param):\r\n    message = \"\"\r\n    result = \"\"\r\n    try:\r\n        pathname = os.path.dirname(sys.argv[0])\r\n        message = os.path.abspath(pathname)\r\n        message = subprocess.call([sys.executable, \"-m\", \"pip\", \"list\"])\r\n        message = subprocess.run([sys.executable, \"-m\", \"pip\", \"install\", param], capture_output=True)\r\n        result = \"True\"\r\n    except Exception as e:\r\n        message = e\r\n        result = \"False\"\r\n    return {\"result\": result, \"message\": message}\r\n\r\n\r\n# main function\r\ndef execute(MP_jiraIssueURL, MP_jiraUser, MP_jiraPassword,\r\n            smax_Url, smax_tenantId, smax_Token, projectNames, creator, lastUpdate, smax_FieldID,\r\n            jira_IncidentCategory_FieldId, jira_RequestCategory_FieldId, conn_timeout, http_fail_status_codes,\r\n            smax_jirasmaxid_list,previous_errorLogs):\r\n    message = \"\"\r\n    result = \"\"\r\n    jiraIssueStatus = \"\"\r\n    statusJiraResult = {}\r\n    updateResult = {}\r\n    errorSeverity = \"\"\r\n    errorType = \"\"\r\n    errorProvider = \"\"\r\n    errorMessage = \"\"\r\n    smaxDataU = {}\r\n    newUpdateTime = \"\"\r\n    provider_failure = \"\"\r\n    errorLogs = \"\"\r\n    reqUrl = \"\"\r\n    responseBody = \"\"\r\n    responseCode = \"\"\r\n    ProviderUrlBody = \"\"\r\n    smaxticketID = \"\"\r\n    jiraticketID = \"\"\r\n\r\n    try:\r\n        # requirement external modules\r\n        install(\"requests\")\r\n        install(\"pytz\")\r\n\r\n        # Get current new update time in CST timezone ('US/Central') as Jira is returns time in this TZ\r\n        from datetime import datetime\r\n        from pytz import timezone\r\n        fmt = \"%Y-%m-%d %H:%M\"  # Format of time\r\n        # Current time in CST - 'US/Central'\r\n        #now_cst = datetime.now(timezone('US/Central'))\r\n        #newUpdateTime = now_cst.strftime(fmt)\r\n        lastUpdate = lastUpdate[0:16]\r\n\r\n        import json\r\n        status_codes = json.loads(http_fail_status_codes)\r\n\r\n        # ************Calling extractJiraStatusBulk for extracting JIRA records ****************8\r\n        statusJiraResult = extractJiraStatusBulk(MP_jiraIssueURL, MP_jiraUser, MP_jiraPassword, projectNames, creator,\r\n                                                 lastUpdate,\r\n                                                 smax_FieldID, jira_IncidentCategory_FieldId,\r\n                                                 jira_RequestCategory_FieldId, conn_timeout, status_codes,\r\n                                                 smax_jirasmaxid_list)\r\n        tresult = statusJiraResult[\"result\"]\r\n        message = statusJiraResult[\"message\"]\r\n        errorType = statusJiraResult[\"errorType\"]\r\n        errorLogs += statusJiraResult[\"errorLogs\"]\r\n        provider_failure = statusJiraResult[\"provider_failure\"]\r\n        if tresult == \"False\" and provider_failure == \"True\":\r\n            raise Exception(message)\r\n\r\n        if statusJiraResult[\"result\"] == \"True\":\r\n            jiraIssueStatus = statusJiraResult[\"jiraIssueStatus\"]\r\n            if len(jiraIssueStatus) > 0:\r\n                updateResult = createSMAXBulkRequest(jiraIssueStatus)\r\n                tresult = updateResult[\"result\"]\r\n                message = updateResult[\"message\"]\r\n                errorType = updateResult[\"errorType\"]\r\n                errorLogs += updateResult[\"errorLogs\"]\r\n                provider_failure = updateResult[\"provider_failure\"]\r\n                if tresult == \"False\" and provider_failure == \"True\":\r\n                    raise Exception(message)\r\n                if updateResult[\"result\"] == \"True\" and len(updateResult[\"smaxData\"]) > 2:\r\n                    smaxDataU['entities'] = []\r\n                    smaxDataU['operation'] = \"UPDATE\"\r\n                    smaxDataU = updateResult[\"smaxData\"]\r\n                    updateRes = updateSMAXJiraStatus(smax_Url, smax_tenantId, smax_Token, smaxDataU, status_codes)\r\n                    tresult = updateRes[\"result\"]\r\n                    message = updateRes[\"message\"]\r\n                    errorType = updateRes[\"errorType\"]\r\n                    errorLogs += updateRes[\"errorLogs\"]\r\n                    provider_failure = updateRes[\"provider_failure\"]\r\n                    if tresult == \"False\" and provider_failure == \"True\":\r\n                        raise Exception(message)\r\n            else:\r\n                result = \"True\"\r\n                message = \"No issue found since last update\"\r\n        else:\r\n            result = \"True\"\r\n            message = \"No issue found since last update\"\r\n        result = \"True\"\r\n    except Exception as e:\r\n        message = str(e)\r\n        result = \"False\"\r\n        errorType = \"e20000\"\r\n        errorSeverity = \"ERROR\"\r\n        if not errorProvider:\r\n            errorProvider = \"JIRA\"\r\n        errorMessage = message\r\n        errorLogs += \"SMAXRequestId,\" + smaxticketID + \"||JiraIssueId,\" + jiraticketID + \"||ProviderUrl,\" + reqUrl + \"||ErrorProvider,SMAX||ProviderUrlBody,\" + ProviderUrlBody + \"||ErrorMessage,\" + str(\r\n            message) + \": Response Code: \" + responseCode + \"|||\"\r\n\r\n    return {\"result\": result, \"message\": message, \"newUpdateTime\": newUpdateTime, \"errorType\": errorType,\r\n            \"errorSeverity\": errorSeverity, \"errorProvider\": errorProvider, \"errorMessage\": errorMessage,\r\n            \"jiraIssueStatus\": jiraIssueStatus, \"errorLogs\": errorLogs + previous_errorLogs, \"provider_failure\": provider_failure}\r\n\r\n\r\n# search all the issues updated since lastUpdate params\r\ndef extractJiraStatusBulk(MP_jiraIssueURL, MP_jiraUser, MP_jiraPassword, projectNames,\r\n                          creator, lastUpdate, smax_FieldID, jira_IncidentCategory_FieldId,\r\n                          jira_RequestCategory_FieldId, conn_timeout, status_codes, smax_jirasmaxid_list):\r\n    message = \"\"\r\n    result = \"\"\r\n    jiraIssueStatus = \"\"\r\n    errorSeverity = \"\"\r\n    errorType = \"\"\r\n    errorProvider = \"\"\r\n    errorMessage = \"\"\r\n    provider_failure = \"\"\r\n    errorLogs = \"\"\r\n    reqUrl = \"\"\r\n    responseBody = \"\"\r\n    responseCode = \"\"\r\n    ProviderUrlBody = \"\"\r\n    failCodes = \"\"\r\n    smaxticketID = \"\"\r\n    jiraticketID = \"\"\r\n    jiraIDs = \"\"\r\n\r\n    try:\r\n        import json\r\n        import requests\r\n\r\n        index = 0\r\n        ids = projectNames.split(\"♪\")\r\n        inputString = \"\"\r\n        \r\n        for jiraID in smax_jirasmaxid_list.split(\"♪\"):\r\n            if jiraID:\r\n                jiraIDs += str(jiraID.split(\"♫\")[0]) + \",\"\r\n                if jiraIDs:\r\n                    jiraIDs = jiraIDs[:-1]\r\n                ids = \"0\"\r\n\r\n        for id in ids:\r\n            startAt = 0\r\n            maxResults = 500\r\n            total = 501\r\n            while_loop = 'true'\r\n            while while_loop:\r\n                reqUrl = '{0}rest/api/2/search'.format(MP_jiraIssueURL)\r\n                data = {}\r\n                if jiraIDs:\r\n                    data[\"jql\"] = \"issue IN (\" + jiraIDs + \")\"\r\n                else:\r\n                    data[\"jql\"] = \"project='{0}' AND updated >='{1}' AND creator='{2}'\".format(id, lastUpdate, creator)\r\n                data[\"startAt\"] = startAt\r\n                data[\"maxResults\"] = maxResults\r\n                data[\"fields\"] = [smax_FieldID, \"status\", \"assignee\", \"resolutiondate\", \"resolution\",\r\n                                  jira_IncidentCategory_FieldId,\r\n                                  jira_RequestCategory_FieldId]\r\n\r\n                inputString = json.dumps(data)\r\n                ProviderUrlBody = str(inputString)\r\n                basicAuthCredentials = requests.auth.HTTPBasicAuth(MP_jiraUser, MP_jiraPassword)\r\n                headers = {'X-Atlassian-Token': 'no-check', 'Content-Type': 'application/json'}\r\n                response = requests.post(reqUrl, auth=basicAuthCredentials, headers=headers, data=inputString,\r\n                                         timeout=int(conn_timeout))\r\n                responseBody = str(response.content)\r\n                responseCode = str(response.status_code)\r\n                if response.status_code == 200:\r\n                    result = \"True\"\r\n                    entityJsonArray = json.loads(response.content)\r\n                    total = entityJsonArray[\"total\"]\r\n                    # set the values for next run if more records\r\n                    if total > maxResults:\r\n                        startAt = int(maxResults) + 1\r\n                        maxResults = int(maxResults) + 500\r\n                        # run next loop again to retreve left over records\r\n                        while_loop = 'true'\r\n                    else:\r\n                        # break the loop after last record is retrieved\r\n                        while_loop = ''\r\n                    for entity in entityJsonArray[\"issues\"]:\r\n                        jira_status = fetchSmaxIdAndAssignee(entity, smax_FieldID, jira_IncidentCategory_FieldId,\r\n                                                             jira_RequestCategory_FieldId)\r\n                        tresult = jira_status[\"result\"]\r\n                        message = jira_status[\"message\"]\r\n                        errorType = jira_status[\"errorType\"]\r\n                        errorLogs += jira_status[\"errorLogs\"]\r\n                        provider_failure = jira_status[\"provider_failure\"]\r\n\r\n                        if tresult == \"False\" and provider_failure == \"True\":\r\n                            raise Exception(message)\r\n                        if jira_status[\"result\"] == \"True\":\r\n                            jiraIssueStatus += jira_status[\"jiraIssueStatus\"]\r\n                else:\r\n                    failCodes = status_codes['jira']\r\n                    if responseCode in failCodes:\r\n                        provider_failure = \"True\"\r\n                        msg = \"Unsupported response from provider: \" + responseBody + \", Response Code: \" + responseCode\r\n                        raise Exception(msg)\r\n                    else:\r\n                        result = \"False\"\r\n                        errorLogs = \"SMAXRequestId,\" + smaxticketID + \"||JiraIssueId,\" + jiraticketID + \"||ProviderUrl,\" + reqUrl + \"||ErrorProvider,JIRA||ProviderUrlBody,\" + ProviderUrlBody + \"||ErrorMessage,\" + responseBody + \": Response Code: \" + responseCode + \"|||\"\r\n\r\n    except Exception as e:\r\n        message = str(e)\r\n        result = \"False\"\r\n        errorSeverity = \"ERROR\"\r\n        errorType = \"e20000\"\r\n        errorProvider = \"JIRA\"\r\n        errorMessage = message\r\n        errorLogs = \"SMAXRequestId,\" + smaxticketID + \"||JiraIssueId,\" + jiraticketID + \"||ProviderUrl,\" + reqUrl + \"||ErrorProvider,JIRA||ProviderUrlBody,\" + ProviderUrlBody + \"||ErrorMessage,\" + str(\r\n            message) + \": Response Code: \" + responseCode + \"|||\"\r\n\r\n    return {\"result\": result, \"message\": message, \"jiraIssueStatus\": jiraIssueStatus, \"errorType\": errorType,\r\n            \"errorSeverity\": errorSeverity, \"errorProvider\": errorProvider, \"errorMessage\": errorMessage,\r\n            \"errorLogs\": errorLogs, \"provider_failure\": provider_failure}\r\n\r\n\r\n# Fetch the field from JIRA(JSON) - smax_filedID,assignee,status_name,incidentCategory,requestCategory\r\ndef fetchSmaxIdAndAssignee(entity, smax_FieldID, jira_IncidentCategory_FieldId, jira_RequestCategory_FieldId):\r\n    jiraIssueStatus = \"\"\r\n    close_time = \"\"\r\n    incidentCategory_value = \"\"\r\n    requestCategory_value = \"\"\r\n    resolution = \"\"\r\n    message = \"\"\r\n    result = \"True\"\r\n    errorType = \"\"\r\n    errorSeverity = \"\"\r\n    errorMessage = \"\"\r\n    assignee_name = \"\"\r\n    provider_failure = \"\"\r\n    errorLogs = \"\"\r\n    reqUrl = \"\"\r\n    responseBody = \"\"\r\n    responseCode = \"\"\r\n    ProviderUrlBody = \"\"\r\n    failCodes = \"\"\r\n    smaxticketID = \"\"\r\n    jiraticketID = \"\"\r\n\r\n    try:\r\n\r\n        smax_id = entity[\"fields\"][smax_FieldID]\r\n        assignee = entity[\"fields\"][\"assignee\"]\r\n        if assignee:\r\n            tassignee_name = entity[\"fields\"][\"assignee\"][\"displayName\"]\r\n            email = entity[\"fields\"][\"assignee\"][\"emailAddress\"]\r\n            assignee_name = tassignee_name + \"(\" + email + \")\"\r\n        status_name = entity[\"fields\"][\"status\"][\"name\"]\r\n        incidentCategory = entity[\"fields\"][jira_IncidentCategory_FieldId]\r\n        if incidentCategory:\r\n            incidentCategory_value = incidentCategory.get(\"value\")\r\n        requestCategory = entity[\"fields\"][jira_RequestCategory_FieldId]\r\n        if requestCategory:\r\n            requestCategory_value = requestCategory.get(\"value\")\r\n        resolutionDate = entity[\"fields\"][\"resolutiondate\"]\r\n        if resolutionDate:\r\n            close_time = str(cst_to_milliseconds(resolutionDate)[\"time_milliseconds\"])\r\n            resolution = entity[\"fields\"][\"resolution\"][\"name\"]\r\n        # t = smax_id + \"♫\"\r\n        # Do not add any duplicate SMAX ID Records\r\n        if smax_id and smax_id != '73346' and smax_id + \"♫\" not in jiraIssueStatus:\r\n            if not incidentCategory and not requestCategory:\r\n                jiraIssueStatus += smax_id + \"♫\" + status_name + \"♫\" + assignee_name + \"♫♫\" + close_time + \"♫\" + resolution + \"♪\"\r\n\r\n            elif incidentCategory:\r\n                jiraIssueStatus += smax_id + \"♫\" + status_name + \"♫\" + assignee_name + \"♫\" + incidentCategory_value + \"♫\" + close_time + \"♫\" + resolution + \"♪\"\r\n\r\n            elif requestCategory:\r\n                jiraIssueStatus += smax_id + \"♫\" + status_name + \"♫\" + assignee_name + \"♫\" + requestCategory_value + \"♫\" + close_time + \"♫\" + resolution + \"♪\"\r\n    except Exception as e:\r\n        message = str(e)\r\n        result = \"False\"\r\n        errorSeverity = \"ERROR\"\r\n        errorType = \"e10000\"\r\n        errorMessage = message\r\n        errorLogs = \"SMAXRequestId,\" + smaxticketID + \"||JiraIssueId,\" + jiraticketID + \"||ProviderUrl,\" + reqUrl + \"||ErrorProvider,JIRA||ProviderUrlBody,\" + ProviderUrlBody + \"||ErrorMessage,\" + str(\r\n            message) + \": Response Code: \" + responseCode + \"|||\"\r\n\r\n    return {\"result\": result, \"message\": message, \"jiraIssueStatus\": jiraIssueStatus, \"errorType\": errorType,\r\n            \"errorMessage\": errorMessage, \"errorLogs\": errorLogs, \"provider_failure\": provider_failure}\r\n\r\n\r\n## function to convert CST Date and time to MilliSeconds format for updation in SMAX\r\n##input cst date as: \"2022-05-17T04:56:18.000-0500\"\r\ndef cst_to_milliseconds(dt):\r\n    message = \"\"\r\n    result = \"\"\r\n    errorMessage = ''\r\n    errorType = ''\r\n    time_milliseconds = ''\r\n    provider_failure = \"\"\r\n    errorLogs = \"\"\r\n    reqUrl = \"\"\r\n    errorSeverity = \"\"\r\n    responseBody = \"\"\r\n    responseCode = \"\"\r\n    ProviderUrlBody = \"\"\r\n    smaxticketID = \"\"\r\n    jiraticketID = \"\"\r\n\r\n    try:\r\n        from datetime import datetime\r\n        from datetime import timedelta\r\n        import pytz\r\n\r\n        dt = dt.replace('T', ' ')[0:19]  ## date now 2022-05-17 04:56:18\r\n        # get the date time in UTC by adding timedelta of 5 Hours\r\n        # dt_obj = datetime.strptime(dt, '%Y-%m-%d %H:%M:%S') + timedelta(hours=5)\r\n        YY = dt[0:4]\r\n        MON = dt[5:7]\r\n        DD = dt[8:10]\r\n        HH = dt[11:13]\r\n        MM = dt[14:16]\r\n        SS = dt[17:19]\r\n        # get the date time in UTC by adding timedelta of 5 Hours since CST is 5 Hours Behind UTC\r\n        dt_obj = datetime(int(YY), int(MON), int(DD), int(HH), int(MM), int(SS), tzinfo=pytz.utc) + timedelta(hours=5)\r\n        ## get time in milliseconds\r\n        time_milliseconds = int(dt_obj.timestamp() * 1000)\r\n        message = time_milliseconds\r\n        result = 'True'\r\n\r\n    except Exception as e:\r\n        message = str(e)\r\n        result = \"False\"\r\n        errorSeverity = \"ERROR\"\r\n        errorType = \"e10000\"\r\n        errorMessage = message\r\n        errorLogs = \"SMAXRequestId,\" + smaxticketID + \"||JiraIssueId,\" + jiraticketID + \"||ProviderUrl,\" + reqUrl + \"||ErrorProvider,JIRA||ProviderUrlBody,\" + ProviderUrlBody + \"||ErrorMessage,\" + str(\r\n            message) + \": Response Code: \" + responseCode + \"|||\"\r\n\r\n    return {\"result\": result, \"message\": message, \"time_milliseconds\": time_milliseconds, \"errorType\": errorType,\r\n            \"errorMessage\": errorMessage, \"errorLogs\": errorLogs, \"provider_failure\": provider_failure}\r\n\r\n\r\n## Create SMAX Request body for bulk data\r\ndef createSMAXBulkRequest(jiraIssueStatus):\r\n    message = \"\"\r\n    result = \"\"\r\n    smaxData = \"\"\r\n    errorSeverity = \"\"\r\n    errorType = \"\"\r\n    errorProvider = \"\"\r\n    errorMessage = \"\"\r\n    provider_failure = \"\"\r\n    errorLogs = \"\"\r\n    reqUrl = \"\"\r\n    responseBody = \"\"\r\n    responseCode = \"\"\r\n    ProviderUrlBody = \"\"\r\n    smaxticketID = \"\"\r\n    jiraticketID = \"\"\r\n\r\n    try:\r\n        import json\r\n\r\n        smaxDataU = {}\r\n        smaxDataU['entities'] = []\r\n        smaxDataU['operation'] = \"UPDATE\"\r\n        smaxid_list = str('1')\r\n        jiraIssueStatus_tmp = jiraIssueStatus\r\n        jiraIssueStatus = ''\r\n\r\n        # '{\"entity_type\": \"Request\", \"properties\": { \"Id\": \"'+smaxRequestID+'\",  \"JiraIssueStatus_c\": \"'+jiraIssueStatus+'\"}, \"related_properties\" : { }  }'\r\n        if len(jiraIssueStatus.split(\"♪\")) > 0:\r\n            ## loop to remove the duplicates if any\r\n            for issues in jiraIssueStatus_tmp.split(\"♪\"):\r\n                if issues and issues.split(\"♫\")[0] not in smaxid_list:\r\n                    smaxid_list += str(issues.split(\"♫\")[0]) + ','\r\n                    jiraIssueStatus += issues + \"♪\"\r\n            smaxDataU['entities'] = [0] * len(jiraIssueStatus.split(\"♪\"))\r\n            i = 0\r\n            for issues in jiraIssueStatus.split(\"♪\"):\r\n                if issues:\r\n                    smaxDataU['entities'][i] = {}\r\n                    smaxDataU['entities'][i][\"entity_type\"] = \"Request\"\r\n                    smaxDataU['entities'][i][\"properties\"] = {}\r\n                    smaxDataU['entities'][i][\"properties\"][\"Id\"] = issues.split(\"♫\")[0]\r\n                    smaxDataU['entities'][i][\"properties\"][\"JiraIssueStatus_c\"] = issues.split(\"♫\")[1]\r\n                    if len(issues.split(\"♫\")) > 2 and issues.split(\"♫\")[2]:\r\n                        smaxDataU['entities'][i][\"properties\"][\"JiraAssignee_c\"] = issues.split(\"♫\")[2]\r\n                    if len(issues.split(\"♫\")) > 3 and issues.split(\"♫\")[3]:\r\n                        smaxDataU['entities'][i][\"properties\"][\"JIRACategory_c\"] = issues.split(\"♫\")[3]\r\n                    # if Ticket is closed and there is value in resolution/close date\r\n                    if len(issues.split(\"♫\")) > 3 and issues.split(\"♫\")[4]:\r\n                        smaxDataU['entities'][i][\"properties\"][\"CloseTime\"] = issues.split(\"♫\")[4]\r\n                    if issues.split(\"♫\")[1] == 'Closed':\r\n                        smaxDataU['entities'][i][\"properties\"][\"Status\"] = 'RequestStatusComplete'\r\n                        ## commeneted below two lines since SMAX does not permit updation for phaseid in some cases\r\n                        # smaxDataU['entities'][i][\"properties\"][\"PhaseId\"] = 'Close'\r\n                        # smaxDataU['entities'][i][\"properties\"][\"CompletionCode\"] = 'CompletionCodeFulfilledInJira_c'\r\n                        # resolution in JIRA\r\n                        smaxDataU['entities'][i][\"properties\"][\"Solution\"] = issues.split(\"♫\")[\r\n                                                                                 5] + ' and Jira Issue Closed'\r\n\r\n                elif i > 0:\r\n                    del smaxDataU['entities'][i]\r\n                i += 1\r\n            smaxData = json.dumps(smaxDataU)\r\n\r\n        result = \"True\"\r\n    except Exception as e:\r\n        message = str(e)\r\n        result = \"False\"\r\n        errorSeverity = \"ERROR\"\r\n        errorType = \"e20000\"\r\n        errorProvider = \"JIRA\"\r\n        errorMessage = message\r\n        errorLogs = \"SMAXRequestId,\" + smaxticketID + \"||JiraIssueId,\" + jiraticketID + \"||ProviderUrl,\" + reqUrl + \"||ErrorProvider,JIRA||ProviderUrlBody,\" + ProviderUrlBody + \"||ErrorMessage,\" + str(\r\n            message) + \": Response Code: \" + responseCode + \"|||\"\r\n\r\n    return {\"result\": result, \"message\": message, \"smaxData\": smaxData, \"errorType\": errorType,\r\n            \"errorSeverity\": errorSeverity, \"errorProvider\": errorProvider, \"errorMessage\": errorMessage,\r\n            \"errorLogs\": errorLogs, \"provider_failure\": provider_failure}\r\n\r\n\r\n# insert or update Knowladge Article in SMAX\r\ndef updateSMAXJiraStatus(smax_Url, tenantId, smax_Token, datas, status_codes):\r\n    message = \"\"\r\n    result = \"\"\r\n    token = \"\"\r\n    errorSeverity = \"\"\r\n    errorType = \"\"\r\n    errorProvider = \"\"\r\n    errorMessage = \"\"\r\n    errorDetails = \"\"\r\n    provider_failure = \"\"\r\n    errorLogs = \"\"\r\n    reqUrl = \"\"\r\n    responseBody = \"\"\r\n    responseCode = \"\"\r\n    ProviderUrlBody = \"\"\r\n    msg = \"\"\r\n    smaxticketID = \"\"\r\n    jiraticketID = \"\"\r\n\r\n    try:\r\n        import requests\r\n        import json\r\n\r\n        token = smax_Token\r\n\r\n        headers = {\r\n            'Cookie': 'LWSSO_COOKIE_KEY=' + token,\r\n            'Content-Type': 'application/json',\r\n            'User-Agent': 'Apache-HttpClient/4.4.1'\r\n        }\r\n\r\n        payload = datas\r\n        ProviderUrlBody = str(payload)\r\n        reqUrl = smax_Url + \"/rest/\" + tenantId + \"/ems/bulk\"\r\n        response = requests.request(\"POST\", reqUrl, headers=headers, data=payload)\r\n        responseBody = str(response.content)\r\n        responseCode = str(response.status_code)\r\n        if response.status_code == 200:\r\n            smax_response = json.loads(response.content)\r\n            smax_status = smax_response[\"meta\"][\"completion_status\"]\r\n            if smax_status == 'FAILED':\r\n                errorDetails = smax_response[\"entity_result_list\"][0].get(\"errorDetails\")\r\n                msg = \"Issue Creating Records! : \" + str(errorDetails) + \": \" + responseBody\r\n                raise Exception(msg)\r\n        else:\r\n            failCodes = status_codes['jira']\r\n            if responseCode in failCodes:\r\n                provider_failure = \"True\"\r\n                msg = \"Unsupported response from provider: \" + responseBody + \", Response Code: \" + responseCode\r\n                raise Exception(msg)\r\n            else:\r\n                result = \"False\"\r\n                errorLogs = \"SMAXRequestId,\" + smaxticketID + \"||JiraIssueId,\" + jiraticketID + \"||ProviderUrl,\" + reqUrl + \"||ErrorProvider,JIRA||ProviderUrlBody,\" + ProviderUrlBody + \"||ErrorMessage,\" + responseBody + \": Response Code: \" + responseCode + \"|||\"\r\n\r\n    except Exception as e:\r\n        message = str(e)\r\n        result = \"False\"\r\n        errorSeverity = \"ERROR\"\r\n        errorType = \"e20000\"\r\n        errorProvider = \"SMAX\"\r\n        errorMessage = message\r\n        errorLogs = \"SMAXRequestId,\" + smaxticketID + \"||JiraIssueId,\" + jiraticketID + \"||ProviderUrl,\" + reqUrl + \"||ErrorProvider,JIRA||ProviderUrlBody,\" + ProviderUrlBody + \"||ErrorMessage,\" + str(\r\n            message) + \": Response Code: \" + responseCode + \"|||\"\r\n\r\n    return {\"result\": result, \"message\": message, \"smax_response\": msg, \"errorType\": errorType,\r\n            \"errorSeverity\": errorSeverity, \"errorProvider\": errorProvider, \"errorMessage\": errorMessage,\r\n            \"errorLogs\": errorLogs, \"provider_failure\": provider_failure}"
  outputs:
    - result
    - message
    - newUpdateTime
    - errorType
    - errorSeverity
    - errorProvider
    - errorMessage
    - jiraIssueStatus
    - errorLogs
    - provider_failure
  results:
    - SUCCESS: '${result=="True"}'
    - FAILURE
