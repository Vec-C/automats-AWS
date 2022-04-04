while read p; do                                        
  TASK=$( echo $p | tr -d '"' | sed -En 's/^.*task-definition\/(.*)$/\1/p' )
  HEALTH=$( aws ecs describe-task-definition --task-definition $TASK | jq '.taskDefinition | .containerDefinitions | .[0] | .healthCheck | .command' )
  echo $TASK"__"$HEALTH
  echo "NEW SERVICE"
done < Definitions.txt