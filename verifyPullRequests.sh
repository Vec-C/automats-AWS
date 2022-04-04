#!/bin/bash

#********Getting GIT Repositories********

COUNT=$(sed -nE "s/(Pipe)/\1/p" Pipes.txt | wc -l | tr -d ' ')
noDeployPipes=0
stop=$COUNT
declare -a PIPE
declare -a SOURCE

for (( i = 1; i < stop; i=i+6 )); 
do
   
   checking=$( expr "$i"  '-' "$noDeployPipes" )
   line=$(sed -nE $checking"s/(Pipe)/\1/p" Pipes.txt)
   if [ "$line" = "Pipe" ]
   then
      next=$( expr "$checking"  '-' "5" )
      PIP=$PIP" "$(sed -nE $next"s/^(.+)$/\1/p" Pipes.txt)
      next=$( expr "$checking"  '-' "3" )
      SOURC=$SOURC" "$(sed -nE $next"s/^(.+)$/\1/p" Pipes.txt | tr -d '"')
   else
      noDeployPipes=$( expr "1"  '+' "$noDeployPipes" )
   fi

   stop=$( expr "6"  '*' "$COUNT" '-' "5" '-' "$noDeployPipes" )
   
done

PIPE=($PIP)
SOURCE=($SOURC)

for i in ${!PIPE[@]}
do
   
   echo ${PIPE[$i]} 
   #**************Añadir Template*******
   #aws codecommit associate-approval-rule-template-with-repository --repository-name ${SOURCE[$i]}  --approval-rule-template-name "Approval for master branches"
   #**************Enlistar Templates adjuntos*******
   aws codecommit list-associated-approval-rule-templates-for-repository --repository-name ${SOURCE[$i]}

done