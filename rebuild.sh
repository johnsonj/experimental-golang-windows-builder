set -e
set -u

ZONE="us-east1-d"
REGION="us-east1"

# Destroy existing
yes "yes" | terraform destroy --var "projectid=${PROJECT_ID}" --var "zone=${ZONE}" --var "region=${REGION}" --var "image=${IMAGE}"

# Clean up instance info
rm -f instance.txt

# Create resources
terraform apply --var "projectid=${PROJECT_ID}" --var "zone=${ZONE}" --var "region=${REGION}" --var "image=${IMAGE}"

echo "Waiting 60 seconds for sysprep to finish"
sleep 60

echo ""
echo "Start logs:"
echo ""
gcloud compute instances get-serial-port-output buildlet-windows --zone="${ZONE}" --project="${PROJECT_ID}" 

# Set, fetch credentials
yes "Y" | gcloud compute reset-windows-password buildlet-windows --user wingopher --project="${PROJECT_ID}" --zone="${ZONE}" > instance.txt

echo "Restarting the instance"
gcloud compute instances reset buildlet-windows --zone="${ZONE}" --project="${PROJECT_ID}" 

echo "Waiting 60 seconds for the instance to boot"
sleep 60
external_ip=$(gcloud compute instances describe buildlet-windows --project="${PROJECT_ID}" --zone="${ZONE}" --format="value(networkInterfaces[0].accessConfigs[0].natIP)")
echo curl "http://${external_ip}"
output=$(curl "http://${external_ip}")
echo "${output}"

if [[ ${output} == *"buildlet"* ]]; then
	echo "success!"
	exit 0
else
	echo "failure"
	exit 1
fi
