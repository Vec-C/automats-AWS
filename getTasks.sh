#!/bin/bash

rm servicesDetail.json

for file in servicesINFO*.json; do
   rm ${file}
done

CLUSTERS=$(aws ecs list-clusters | egrep -o '/[\_a-zA-Z0-9\-]{1,255}"' | tr '/' '"' | tr "\n" "," | tr '"' ' ')
echo $CLUSTERS | tr ',' '\n'
IFS=' , ' read -r -a ACLUSTERS <<< "$CLUSTERS"
read CLUSTER
SERVICES=$(aws ecs list-services --cluster $CLUSTER | egrep -o '/[\_a-zA-Z0-9\-]{1,255}"' | tr '/' '"' | tr "\n" " " | tr -d '"' )
SERVICES=${SERVICES%?}

declare -a ASERVICES=($SERVICES)
declare -a JSERVICES

SSERVICES=""

for i in "${!ASERVICES[@]}"
do
   if [[ $(($i % 10 )) == 0 ]]
   then
      if [[ $(($i / 10)) > 0 ]]
        then
           JSERVICES[ $(($i / 10)) ]="$SSERVICES"    
           SSERVICES=${ASERVICES[$i]}
        else
           SSERVICES=${ASERVICES[$i]}
        fi
   else
        SSERVICES="$SSERVICES ${ASERVICES[$i]}"
   fi
done

for i in "${!JSERVICES[@]}"
do
   JSERVICES[$i]=$(sed 's/^/"/' <<< ${JSERVICES[$i]})
   JSERVICES[$i]=$(tr '[[:space:]]' '"' <<< ${JSERVICES[$i]})
   JSERVICES[$i]=$(sed 's/"/","/g' <<< ${JSERVICES[$i]})
   JSERVICES[$i]=$(sed 's/^",//' <<< ${JSERVICES[$i]})
   JSERVICES[$i]=$(sed 's/,"$//' <<< ${JSERVICES[$i]})

   FILE={\"cluster\":\"$CLUSTER\",\"services\":[${JSERVICES[$i]}]} 
   
   echo $FILE > "servicesINFO$i.json"
done

SSERVICES=$(sed 's/^/"/' <<< $SSERVICES)
SSERVICES=$(tr '[[:space:]]' '"' <<< $SSERVICES)
SSERVICES=$(sed 's/"/","/g' <<< $SSERVICES)
SSERVICES=$(sed 's/^",//' <<< $SSERVICES)
SSERVICES=$(sed 's/,"$//' <<< $SSERVICES)
SSERVICES={\"cluster\":\"$CLUSTER\",\"services\":[$SSERVICES]} 

echo $SSERVICES > servicesINFOLast.json

for file in servicesINFO*.json; do
   aws ecs describe-services --cli-input-json file://./${file} >> servicesDetail.json
done

jq '.services | .[] | "\(.serviceName) \(.taskDefinition)"' servicesDetail.json > Definitions.txt
jq '.services | .[] | .serviceArn' servicesDetail.json > ServicesARNS.txt

