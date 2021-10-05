#!/bin/bash

rm Verifying.json

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

perl -pe 's/^.*?([a-zA-Z0-9]+)\s.*?((GET|POST|PUT|DELETE|ANY).*)+$/\1 \2/g' Resources.txt > Methods.txt

perl -i -pe 's/^.*?([a-zA-Z0-9]+)\s(.*?)((GET|POST|PUT|DELETE|OPTIONS|ANY).*)+$/\1 \2/g' Resources.txt

perl -i -pe 's/^([a-zA-Z0-9]+)\s(.*?)\s\n/\1 \2 \n/g' Resources.txt && perl -i -pe 's/^".*\n//g' Resources.txt

egrep -o '[GET|POST|PUT|DELETE|ANY].*[GET|POST|PUT|DELETE|ANY]?.*[GET|POST|PUT|DELETE|ANY]?.*[GET|POST|PUT|DELETE|ANY]?' Methods.txt > Methods2.txt

echo $(sed 's/[^A-Z,]//g' Methods2.txt) > Methods.txt && perl -i -pe 's/ /\n/g' Methods.txt && rm Methods2.txt

declare -a RESS
declare -a METS
declare -a METHS

RESS=($(egrep -o '^[a-zA-Z0-9]+\s' Resources.txt | tr '\n' ' '))
METS=($(egrep -o '^.*$' Methods.txt | tr '\n' ' '))

echo "Ingresa el nombre del stage"
read STAGE
STAGE=$(aws apigateway get-stage --rest-api-id $APIID --stage-name $STAGE)

#******INICIA ITERACIÓN SOBRE MÉTODOS POR RECURSO*************
for i in "${!RESS[@]}"
do

	RESOURCE=${RESS[$i]}
	IFS=','
	METHS=(${METS[$i]})
	for j in "${METHS[@]}"
	do

		L=0	
		IFS=' '
		RESOURCE=${RESS[$i]}
		METHOD=$j
		if [ $METHOD != "OPTIONS" ]
		then
			RESOURCE=$(aws apigateway get-integration --rest-api-id $APIID --resource-id $RESOURCE --http-method $METHOD)
			jq .uri <<< $RESOURCE
			SVAR=$(jq .uri <<< $RESOURCE)
			if [ ! -z $(grep -o 'stageVariables' <<< $SVAR) ]
			then
				SVAR=$(ggrep -Po '(?<=\.)[a-zA-Z0-9]+(?=})' <<< $SVAR )
				jq .variables.$SVAR <<< $STAGE
				ELB=$(jq .variables.$SVAR <<< $STAGE | ggrep -Po '(?<=")[a-zA-Z]+(?=-)')
				PORT=$(jq .variables.$SVAR <<< $STAGE | ggrep -Po '(?<=:)\d+')
			else
				if [ -z $(grep -o 'lambda' <<< $SVAR) ]
				then
					ELB=$(ggrep -Po '(?<=//)(.*?)(?=-)' <<< $SVAR)
					PORT=$(ggrep -Po '(?<=:)\d+(?=/)' <<< $SVAR)
				else
					L=1
				fi
			fi
			if [ "$L" -eq "0" ]
			then
		   		#****************TARGETGROUP***********
		   		ELBARN=$(ggrep -ioP '(?<='$ELB'=)(.*?)$' < elbs.txt)
		   		aws elbv2 describe-listeners --page-size 400 --load-balancer-arn $ELBARN > targets.json
		   		jq '.Listeners | .[] | select(.Port=='$PORT') | .DefaultActions | .[] | .TargetGroupArn' targets.json
		   		TARGET=$(jq '.Listeners | .[] | select(.Port=='$PORT') | .DefaultActions | .[] | .TargetGroupArn' targets.json | tr -d '"')
		   		if [ ! -z "$TARGET" ]
				then
					SERVICE=$(aws elbv2 describe-target-groups --target-group-arns $TARGET | jq .TargetGroups)
				else
					SERVICE='"ELIMINAR-'$ELB':'$PORT'"'
				fi
		   		NAME=$(sed -n $(($i + 1))"s/^.*[[:space:]]\(.*\)[[:space:]].*$/\1/p" Resources.txt)
		   		echo '{"resource":"'$NAME'","targets":'$SERVICE'},' >> Verifying.json
		   	else
		   		echo "LAMBDA"
			fi
		else
			echo "OPTIONS"
		fi

	done

done
