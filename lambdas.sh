#!/bin/bash

QUERYID[0]=lambdavalidafirmaubermxdevdelivery
QUERYID[1]=lambdaValidaFirmaCLUber
QUERYID[2]=lambdaRedimeCuponMX
QUERYID[3]=lambdavalidaeventounicomxdevdelivery
QUERYID[4]=lambdawebhookubermxdevdelivery
QUERYID[5]=lambdatraduceordenubermxdevdelivery
QUERYID[6]=aggegatorCancelOrdermx-default-dev
QUERYID[7]=updateThirdPartyDealers
QUERYID[8]=lambdaAlarms2Slackmxproddelivery
QUERYID[9]=lambdaValidaEventoCLUber
QUERYID[10]=lambdaWebhookCLUber
QUERYID[11]=webhookUberPhytonCl
QUERYID[12]=lambdaobtieneordenubermxdevdelivery
QUERYID[13]=appMeshStatisticsmx-default-prod
QUERYID[14]=webhookUberPhyton
QUERYID[15]=updateRouteTableDynatrace
QUERYID[16]=findStotreAddress
QUERYID[17]=lambdaTraduceOrdenUber
QUERYID[18]=countConsoleMetricsMX-default-prod
QUERYID[19]=lambdaObtienerOrdenCLUber
QUERYID[20]=startstopmx-default-dev
QUERYID[21]=lambdaStartStopMXDevDelivery
QUERYID[22]=lambda_auto_confirm_users
QUERYID[23]=lambdamensajerosurbanosdev
QUERYID[24]=searchClientsPastTicketsDev
QUERYID[25]=mylambdafunctioncli 

for i in "${!QUERYID[@]}"
do
   echo ${QUERYID[$i]}
   ID=$(aws logs start-query --log-group-name /aws/lambda/${QUERYID[$i]} \
 --start-time `date -v-24H "+%s"` \
 --end-time `date "+%s"` \
 --query-string 'filter @message like /./ | stats count(*) as Count by bin(24h)' | jq .queryId | tr -d '"')

   QUERY[$i]=$ID
   # or do whatever with individual element of the array
done

sleep 10

for i in "${!QUERY[@]}"
do
   echo  "${QUERYID[i]} $(aws logs get-query-results --query-id ${QUERY[$i]} | jq '.statistics | .recordsMatched')"
  
   # or do whatever with individual element of the array
done
