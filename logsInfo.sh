#!/bin/bash

# Begin script in case all parameters are correct

#****************LOGS***********
echo "Ingrese nombre de servicio"
read SERVICE

DEFINITION=$(ggrep -Po '(?<=")(.*?)'$SERVICE'(.*?)(?=")' Definitions.txt)

jq '.taskDefinition | .containerDefinitions | .[] | .logConfiguration | .options | .[] ' <<< $(aws ecs describe-task-definition --task-definition $DEFINITION)

LOGGROUP=$(jq '.taskDefinition | .containerDefinitions | .[] | .logConfiguration | .options | .[] ' <<< $(aws ecs describe-task-definition --task-definition $DEFINITION) | tr '\n' ' ')

LOGGROUP=$(ggrep -Po '(?<=")/(.*?)(?=")' <<< $LOGGROUP )

QUERYID=$(aws logs start-query --log-group-name $LOGGROUP \
 --start-time `date -v-12H "+%s"` \
 --end-time `date "+%s"` \
 --query-string 'filter @message like /./ | stats count(*) as Count by bin(12h)' | jq .queryId | tr -d '"')

sleep 10 

aws logs get-query-results --query-id $QUERYID | jq '.statistics | .recordsMatched'