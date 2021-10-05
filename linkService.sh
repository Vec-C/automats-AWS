#!/bin/bash

#****************Reading Swagger File with New Endpoints ***********

helpFunction()
{
   echo ""
   echo "Usage: $0 -a SWAGGER "
   echo "\t-a Service definition not found"
   exit 1 # Exit script after printing help
}

while getopts "a:" opt
do
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
echo "Ingresa el id del API donde desea añadir los recursos"
read APIID

RESOURCES=$(aws apigateway get-resources --rest-api-id $APIID)

echo $RESOURCES | jq '.items[] | "\(.id) \(.path) \(.resourceMethods)\n"' > linkrecs.txt

NEWRESOURCES=$(jq -r -f list-operations.jq $SWAGGER)

declare -a CREATER
declare -a CREATEM
IFS='
'
count=0
cflag=0

for item in $NEWRESOURCES
do

  if [ "hearbeat" != "$(echo $item | sed -En 's/^([a-z]+)&&\/(.*)&&(.*)$/\2/p')" ]
  	then
		MET=$(echo $item | sed -En 's/^([a-z]+)&&\/(.*)&&(.*)$/\1/p')
		REC=$(echo $item | sed -En 's/^([a-z]+)&&\/(.*)&&(.*)$/\2/p')
		if [ -z "$(sed -En 's/^.*('$REC')[[:blank:]]+.*(('$MET').*)+$/\1 \2/pi' linkrecs.txt)" ]
			then
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
		PARENT=$(sed -En 's/"([a-z0-9]+) \/ null.*/\1/p' linkrecs.txt)
		declare -a PARENTS
		declare -a CHILDS
		count=0

		for i in ${!CREATER[@]}
		do

			IFS='/'
			countI=0

			for j in ${CREATER[$i]}
			do

				IFS=" "
				if [ $countI == 0 ]
					then
						if [[ ! " ${PARENTS[*]} " =~ " $j " ]]; then
							echo "Create resource parent: "$j
							PARENTS[$count]=$j 
							countI=$((countI+1))
							count=$((count+1))
						fi
					else
						CHILDS[$countI]=$j
						countI=$((countI+1))
				fi
				
			done
			
			for j in ${CHILDS[@]}
			do
				
				if [[ ! " ${PARENTS[*]} " =~ " $j " ]]; then
					echo "Creating resource "$j
				fi
				#aws apigateway create-resource --rest-api-id $APIID --parent-id $PARENT --path-part $CREATER[$i]
				PARENTS[$count]=$j
				count=$((count+1))

			done

			echo "Creating "${CREATEM[$i]}" method for /"${CREATER[$i]}
			echo "Header parameters:"
			jq '.paths["/'${CREATER[$i]}'"] | .'${CREATEM[$i]}' | .parameters[]? | select(.required == false) | select(.in=="header")' $SWAGGER
			echo "Query parameters:"
			jq '.paths["/'${CREATER[$i]}'"] | .'${CREATEM[$i]}' | .parameters[]? | select(.required == false) | select(.in=="query")' $SWAGGER

		done
	
	else
		exit
fi
















