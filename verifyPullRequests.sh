#!/bin/bash


PREQUESTS=$(aws codecommit list-approval-rule-templates | jq '.approvalRuleTemplateNames | .[]' | tr -d '"' | tr '\n' ' ')

declare -a APREQUESTS=($PREQUESTS)

for i in "${!APREQUESTS[@]}"
do

   aws codecommit get-approval-rule-template --approval-rule-template-name ${APREQUESTS[$i]} | jq '.approvalRuleTemplate | .approvalRuleTemplateContent' | tr -d '\' | sed 's/^"\(.*\)"$/\1/' | jq .

done
