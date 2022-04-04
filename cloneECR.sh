#!/bin/bash
TARGET_ACCOUNT_REGION=us-east-1
DESTINATION_ACCOUNT_REGION=us-east-1
DESTINATION_ACCOUNT_BASE_PATH=xxxxxxxxxxx.dkr.ecr.$DESTINATION_ACCOUNT_REGION.amazonaws.com

#REPO_LIST=($(aws --profile core-prod ecr describe-repositories --query 'repositories[].repositoryUri' --output text --region $TARGET_ACCOUNT_REGION))
REPO_LIST=(xxxxxxxxxx.dkr.ecr.us-east-1.amazonaws.com/amazoncorretto)

for repo_url in ${REPO_LIST[@]}; do
    NAME=$( ggrep -Po '(?<=/)(.*)$' <<< $repo_url )
    REPO=$( ggrep -Po '(.*)(?=/)' <<< $repo_url )
    if [[ 1 == 1 ]]; then
        echo "start pulling image $repo_url from Target account"
        aws --profile core-prod ecr get-login-password --region $TARGET_ACCOUNT_REGION | docker login --username AWS --password-stdin $REPO
        docker pull $repo_url:8
        docker tag $repo_url:8 $DESTINATION_ACCOUNT_BASE_PATH/$NAME:8

        aws --profile sessionm-dev ecr get-login-password --region $DESTINATION_ACCOUNT_REGION | docker login --username AWS --password-stdin $DESTINATION_ACCOUNT_BASE_PATH
        docker push $DESTINATION_ACCOUNT_BASE_PATH/$NAME:8
    fi
done