WhoWasIt="$(awk -F : '{print $1}' < <(echo "${1}"))"
CurrentCommit="MCSS-IPPvCommit-9c4ce55d-be5e-4411-987a-d1db09127f9a"
echo "$WhoWasIt"
if [ $WhoWasIt != $CurrentCommit ]; then echo "ABORT! You must use the Mugino Orchestrator to run this task or your versions dont match"; fi
echo "$(awk -F : '{print $2}' < <(echo "${1}"))"
echo "$(awk -F : '{print $3}' < <(echo "${1}"))"
echo "$(awk -F : '{print $4}' < <(echo "${1}"))"
echo "$(awk -F : '{print $5}' < <(echo "${1}"))"
echo "$(awk -F : '{print $6}' < <(echo "${1}"))"
echo "$(awk -F : '{print $7}' < <(echo "${1}"))"
echo "$(awk -F : '{print $8}' < <(echo "${1}"))"
echo "$(awk -F : '{print $9}' < <(echo "${1}"))"
echo "$(awk -F : '{print $10}' < <(echo "${1}"))"
echo "$(awk -F : '{print $11}' < <(echo "${1}"))"
echo "$(awk -F : '{print $12}' < <(echo "${1}"))"
echo "$(awk -F : '{print $13}' < <(echo "${1}"))"
echo "$(awk -F : '{print $14}' < <(echo "${1}"))"
echo "$(awk -F : '{print $15}' < <(echo "${1}"))"