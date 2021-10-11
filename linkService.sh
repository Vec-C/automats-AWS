#!/bin/bash

#****************Reading Swagger File with New Endpoints ***********
helpFunction()
{
   echo ""
   echo "Usage: $0 -a SWAGGER "
   echo "\t-a Service definition not found"
   exit 1 # Exit script after printing help
}

while getopts "a:" opt; do
   case "$opt" in
      a ) SWAGGER="$OPTARG" ;;
      ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
   esac
done

# Print helpFunction in case parameters are empty
if [ -z "$SWAGGER" ]
then
   echo "Some or all of the parameters are empty";
   helpFunction
fi

#****************Found Resources on Certain API***********
#****************LIST APIS***********
aws apigateway get-rest-apis --max-items 100 > apis.json
echo $(sed '/policy/d' apis.json) > apis.json

apiIds=$(jq '.items | .[] | .id' apis.json)
apiNames=$(jq '.items | .[] | .name' apis.json)

apiIds=$(echo "$apiIds" | tr -d '"' | tr '\n' ' ')
apiNames=$(echo "$apiNames" | tr -d '"' | tr ' ' '_' |tr '\n' ' ')

declare -a idis=($apiIds)
declare -a names=($apiNames)

for key in "${!idis[@]}"; do echo ${idis[$key]}; echo ${names[$key]}; echo "\n"; done

#****************RECURSOS***********
echo "Ingresa el id del API donde desea añadir los recursos"
read APIID

RESOURCES=$(aws apigateway get-resources --rest-api-id $APIID)

echo $RESOURCES | jq '.items[] | "\(.id) \(.path) \(.resourceMethods)\n"' > linkrecs.txt

#***********SEEK METHODS FOR EACH RESOURCE**********
NEWRESOURCES=$(jq -r -f list-operations.jq $SWAGGER)

declare -a CREATER
declare -a CREATEM
IFS='
'
count=0
cflag=0

#***********VALIDATING PREXISTENCE OF REQUESTED OBJECTS FOR CREATION**********
for item in $NEWRESOURCES; do

  if [ "hearbeat" != "$(echo $item | sed -En 's/^([a-z]+)&&\/(.*)&&(.*)$/\2/p')" ]
  	then
		MET=$(echo $item | sed -En 's/^([a-z]+)&&\/(.*)&&(.*)$/\1/p')
		REC=$(echo $item | sed -En 's/^([a-z]+)&&\/(.*)&&(.*)$/\2/p')
		REC=$(if [ -z "$(sed -En 's/\//\\\//gp' <<< $REC)" ] ;then echo $REC ; else sed -En 's/\//\\\//gp' <<< $REC; fi )
		if [ -z "$(sed -En 's/^.*('$REC')[[:blank:]]+.*(('$MET').*)+$/\1 \2/pi' linkrecs.txt)" ]
			then
				REC=$(echo $REC | tr -d '\\')
				DEPLOY=$DEPLOY$REC" "$MET"\n"
				CREATER[cflag]=$REC
				CREATEM[cflag]=$MET
				cflag=$((cflag+1))
			else
				echo $REC" "$MET" Duplicated resource on selected API, action on Swagger definition required."
				count=$((count+1))
		fi
  fi
  
done

IFS=" "
if [ $count == 0 ]
	then 
		echo "Do u wanna deploy the next resources:\n"$DEPLOY"?"
		echo "yes/no"
		read DOIT 
	else
		exit
fi
if [ $DOIT == "yes" ]
	then 
		DEPLOY=""
		PARENT=$(sed -En 's/"([a-z0-9]+) \/ .*/\1/p' linkrecs.txt)
		declare -a PARENTS
		declare -a CHILDS
		count=0
		PARENTS[$count]="qwerty "$PARENT
		count=$((count+1))

		#***********FOR EACH RESOURCE**********
		for i in ${!CREATER[@]}; do

			IFS='/'
			countI=0

			#***********FOR EACH RESOURCE CHILD/VERB ( /... )**********
			for j in ${CREATER[$i]}; do

				IFS=" "
				if [[ ! " ${PARENTS[*]} " =~ " $j " ]]; then
					if [ $countI == 0 ]
						then
							count=1
					fi
					echo "Create resource: "$j
					PID=$( echo ${PARENTS[$((count-1))]} | ggrep -Po '(?<=\s).*$' )
					PA=$(aws apigateway create-resource --rest-api-id $APIID --parent-id $PID --path-part $j || sed -En 's/"([a-z0-9]+) \/'$j' .*/\1/p' linkrecs.txt)
					if [ -z "$(echo $PA | jq .id )" ] 
					then
						PARENTS[$count]=$j" "$PA
					else
						PARENTS[$count]=$j" "$(echo $PA | jq .id | tr -d '"')
					fi
					count=$((count+1))
					countI=$((countI+1))
				else

					for key in "${!PARENTS[@]}"; do

				   	if [[ $( echo ${PARENTS[$key]} | ggrep -Po '^.*(?=\s)' ) == "$j" ]]; then
				      	PARENTS[$count]=${PARENTS[$key]}
				      	count=$((count+1))
				      	countI=$((countI+1))
				   	fi

					done
				
				fi

			done

			echo "Creating "${CREATEM[$i]}" method for /"${CREATER[$i]}
			HPARAMS=$( jq -r '.paths["/'${CREATER[$i]}'"] | .'${CREATEM[$i]}' | .parameters[]? | select(.required == false) | select(.in=="header" ) | .name ' $SWAGGER )
			QPARAMS=$( jq -r '.paths["/'${CREATER[$i]}'"] | .'${CREATEM[$i]}' | .parameters[]? | select(.required == false) | select(.in=="query" ) | .name ' $SWAGGER )
			CODERESPONSES=$( jq -r '.paths["/'${CREATER[$i]}'"] | .'${CREATEM[$i]}' | .responses | to_entries | .[] | .key' $SWAGGER )
			RESOURCES=$(aws apigateway get-resources --rest-api-id $APIID)
			echo $RESOURCES | jq '.items[] | "\(.id) \(.path) \(.resourceMethods)\n"' > linkrecs.txt
			REC=$(if [ -z "$(sed -En 's/\//\\\//gp' <<< ${CREATER[$i]})" ] ;then echo ${CREATER[$i]} ; else sed -En 's/\//\\\//gp' <<< ${CREATER[$i]}; fi )
			RID=$( sed -En 's/"([a-z0-9]+) \/'$REC' .*/\1/p' linkrecs.txt )
			METHOD=$( echo ${CREATEM[$i]} | tr [:lower:] [:upper:] )
			RPARAMETERS=""
			RIPARAMETERS=""

			while read p; do    
				if [ ! -z $p ] ; then
  					RPARAMETERS=$RPARAMETERS"method.request.header.$p=false,"
  					RIPARAMETERS=$RIPARAMETERS"integration.request.header.$p=method.request.header.$p,"
  				fi
			done <<< $HPARAMS

			while read p; do  
				if [ ! -z $p ] ; then  
  					RPARAMETERS=$RPARAMETERS"method.request.querystring.$p=false,"
  					RIPARAMETERS=$RIPARAMETERS"integration.request.querystring.$p=method.request.querystring.$p,"
				fi
			done <<< $QPARAMS

			if [ ! -z $RPARAMETERS ] ; then
				aws apigateway put-method --rest-api-id $APIID --resource-id $RID --http-method $METHOD --authorization-type "NONE" --no-api-key-required --request-parameters "${RPARAMETERS%?}"
				aws apigateway put-integration --rest-api-id $APIID --resource-id $RID --http-method $METHOD --type HTTP --integration-http-method $METHOD --uri 'http://${stageVariables.'${SWAGGER%?????}'}/'${CREATER[$i]} --request-parameters "${RIPARAMETERS%?}"
			else
				aws apigateway put-method --rest-api-id $APIID --resource-id $RID --http-method $METHOD --authorization-type "NONE" --no-api-key-required
				aws apigateway put-integration --rest-api-id $APIID --resource-id $RID --http-method $METHOD --type HTTP --integration-http-method $METHOD --uri 'http://${stageVariables.'${SWAGGER%?????}'}/'${CREATER[$i]}
			fi

			#***********ADDING RESPONSE CODES**********
			while read p; do  
				if [ ! -z $p ] ; then  
  					aws apigateway put-method-response --rest-api-id $APIID --resource-id $RID --http-method $METHOD --status-code $p
					aws apigateway put-integration-response --rest-api-id $APIID --resource-id $RID --http-method $METHOD --status-code $p --selection-pattern $p
				fi
			done <<< $CODERESPONSES

		done
	
	else
		exit
fi