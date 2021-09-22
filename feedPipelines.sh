#!/bin/bash

PIPES=$(aws codepipeline list-pipelines | jq '.pipelines | .[] | .name' | tr -d '"' | tr '\n' ' ')

declare -a APIPES=($PIPES)

rm -rf Pipes.txt

for i in "${!APIPES[@]}"
do
   echo "Pipe" >> Pipes.txt
   echo ${APIPES[$i]} >> Pipes.txt
   echo "Source" >> Pipes.txt
   aws codepipeline get-pipeline --name ${APIPES[$i]} | jq '.pipeline | .stages | .[] | select(.name=="Source") | .actions | .[] | .configuration | .RepositoryName' >> Pipes.txt
   echo "Deploy" >> Pipes.txt
   aws codepipeline get-pipeline --name ${APIPES[$i]} | jq '.pipeline | .stages | .[] | select(.name=="Deploy") | .actions | .[] | .configuration | .ServiceName' >> Pipes.txt
done

