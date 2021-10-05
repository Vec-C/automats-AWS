#!/bin/bash

# Begin script in case all parameters are correct

#EJECUTAR DESDE TERMINAL******C/P*****NO SÉ, INVESTIGA****

#****************LOOPING ON TARGETS*********************

VERIFIED=""
declare -A CHECKED
for row in $(jq '.' Verifying.json | jq -r '.[] | @base64'); do
    _jq() {
     echo ${row} | base64 --decode | jq -r ${1}
    }

    SERVICE=$(_jq '.targets | .[] | .TargetGroupName')

    echo $SERVICE

    DEFINITION=$(ggrep -Po '(?<=")(.*?)'$SERVICE'(.*?)(?=")' Definitions.txt)

    jq '.taskDefinition | .containerDefinitions | .[] | .logConfiguration | .options | .[] ' <<< $(aws ecs describe-task-definition --task-definition $DEFINITION)

    LOGGROUP=$(jq '.taskDefinition | .containerDefinitions | .[] | .logConfiguration | .options | .[] ' <<< $(aws ecs describe-task-definition --task-definition $DEFINITION) | tr '\n' ' ')

    LOGGROUP=$(ggrep -Po '(?<=")/(.*?)(?=")' <<< $LOGGROUP )

    QUERYID=$(aws logs start-query --log-group-name $LOGGROUP \
     --start-time `date -v-12H "+%s"` \
     --end-time `date "+%s"` \
     --query-string 'filter @message like /./ | stats count(*) as Count by bin(12h)' | jq .queryId | tr -d '"')

    if [[ $VERIFIED == *$LOGGROUP* ]]; then
        COUNT=${CHECKED[$(ggrep -Po '(?<=/delivery-).*?(?=-)' <<< $LOGGROUP)]}
        else
            sleep 7
            COUNT=$(aws logs get-query-results --query-id $QUERYID | jq '.statistics | .recordsMatched')
            VERIFIED=$VERIFIED" "$LOGGROUP
            COUNTED=$(ggrep -Po '(?<=/delivery-).*?(?=-)' <<< $LOGGROUP)
            CHECKED[$COUNTED]=$COUNT
    fi

    echo '{"resource":"'$(_jq '.resource')'","service":"'$SERVICE'","count":"'$COUNT'"},' >> apiStatistics.json

done



