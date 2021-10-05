#!/bin/bash

#****************APIS***********
aws apigateway get-rest-apis --max-items 100 > apis.json
echo $(sed '/policy/d' apis.json) > apis.json

apiIds=$(jq '.items | .[] | .id' apis.json)
apiNames=$(jq '.items | .[] | .name' apis.json)

apiIds=$(echo "$apiIds" | tr -d '"' | tr '\n' ' ')
apiNames=$(echo "$apiNames" | tr -d '"' | tr '\n' ' ')

declare -a idis=($apiIds)
declare -a names=($apiNames)

for key in "${!idis[@]}"; do echo ${idis[$key]}; echo ${names[$key]}; echo "\n"; done

#****************RECURSOS***********
echo "Ingresa el id del API a consultar"
read APIID

RESOURCES=$(aws apigateway get-resources --rest-api-id $APIID)

jq '.items[] | "\(.id) \(.path) \(.resourceMethods)\n"' <<< $RESOURCES

#****************INTEGRACION***********
echo "Ingresa el id del recurso a consultar"
read RESOURCE
echo "Ingresa el método a consultar"
read METHOD

RESOURCE=$(aws apigateway get-integration --rest-api-id $APIID --resource-id $RESOURCE --http-method $METHOD)
jq .uri <<< $RESOURCE
SVAR=$(jq .uri <<< $RESOURCE)

if [ ! -z $(grep -o 'stageVariable' <<< $SVAR) ]
   then
      echo "Ingresa el nombre del stage"
      read STAGE
      STAGE=$(aws apigateway get-stage --rest-api-id $APIID --stage-name $STAGE)
      SVAR=$(ggrep -Po '(?<=\.)[a-zA-Z0-9]+(?=})' <<< $SVAR )
      jq .variables.$SVAR <<< $STAGE
      ELB=$(jq .variables.$SVAR <<< $STAGE | ggrep -Po '(?<=")[a-zA-Z]+(?=-)')
      PORT=$(jq .variables.$SVAR <<< $STAGE | ggrep -Po '(?<=:)\d+')
   else
      ELB=$(ggrep -Po '(?<=//)(.*?)(?=-)' <<< $SVAR)
      PORT=$(ggrep -Po '(?<=:)\d+(?=/)' <<< $SVAR)
fi

#****************TARGETGROUP***********
ELBARN=$(ggrep -ioP '(?<='$ELB'=)(.*?)$' < elbs.txt)

aws elbv2 describe-listeners --page-size 400 --load-balancer-arn $ELBARN > targets.json

jq '.Listeners | .[] | select(.Port=='$PORT') | .DefaultActions | .[] | .TargetGroupArn' targets.json

TARGET=$(jq '.Listeners | .[] | select(.Port=='$PORT') | .DefaultActions | .[] | .TargetGroupArn' targets.json | tr -d '"')
SERVICE=$(aws elbv2 describe-target-groups --target-group-arns $TARGET)
jq <<< $SERVICE