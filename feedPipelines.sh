#!/bin/bash

rm -rf Pipes.txt

PIPES=$(aws codepipeline list-pipelines | jq '.pipelines | .[] | .name' | tr -d '"' | tr '\n' ' ')

declare -a APIPES=($PIPES)

for i in "${!APIPES[@]}"
do
   PIPE=$(aws codepipeline get-pipeline --name ${APIPES[$i]})
   echo "Pipe" >> Pipes.txt
   echo ${APIPES[$i]} >> Pipes.txt
   echo "Source" >> Pipes.txt
   echo $PIPE | jq '.pipeline | .stages | .[] | select(.name=="Source") | .actions | .[] | .configuration | .RepositoryName' >> Pipes.txt
   echo "Deploy" >> Pipes.txt
   echo $PIPE | jq '.pipeline | .stages | .[] | select(.name=="Deploy") | .actions | .[] | .configuration | .ServiceName' >> Pipes.txt
done

