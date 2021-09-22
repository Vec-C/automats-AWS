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

IDS=$(jq '.items[] | "\(.id) \(.path) \(.resourceMethods)\n"' <<< $RESOURCES)

echo $IDS > Resources.txt

perl -pe 's/^.*?([a-z0-9]+)\s.*?((GET|POST|PUT|DELETE).*)+$/\1 \2/g' Resources.txt > Methods.txt

perl -i -pe 's/^.*?([a-z0-9]+)\s(.*?)((GET|POST|PUT|DELETE).*)*$/\1 \2/g' Resources.txt

perl -i -pe 's/^([a-z0-9]+)\s(.*?)\s\n/\1 \2 \n/g' Resources.txt && perl -i -pe 's/^".*\n//g' Resources.txt

egrep -o '[GET|POST|PUT|DELETE].*[GET|POST|PUT|DELETE]?.*[GET|POST|PUT|DELETE]?.*[GET|POST|PUT|DELETE]?' Methods.txt > Methods2.txt

echo $(sed 's/[^A-Z,]//g' Methods2.txt) > Methods.txt && perl -i -pe 's/ /\n/g' Methods.txt && rm Methods2.txt

declare -a RESS
declare -a METS
declare -a METHS

RESS=($(egrep -o '^[a-zA-Z0-9]+\s' Resources.txt | tr '\n' ' '))
METS=($(egrep -o '^.*$' Methods.txt | tr '\n' ' '))

echo "Ingresa el nombre del stage"
read STAGE
STAGE=$(aws apigateway get-stage --rest-api-id $APIID --stage-name $STAGE)

#******INICIA ITERACI´ÓN SOBRE MÉTODOS POR RECURSO*************
for i in "${!RESS[@]}"
do

	RESOURCE=${RESS[$i]}
	IFS=','
	METHS=(${METS[$i]})
	
done
