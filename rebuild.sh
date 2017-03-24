set -e

# Destroy existing
 yes "yes" | terraform destroy --var "projectid=${PROJECT_ID}"

# Clean up instance info
rm -f instance.txt

# Create resources
terraform apply --var "projectid=${PROJECT_ID}"

echo "Waiting 80 seconds to fetch logs, Ctrl+C if you aren't interested"
sleep 80

echo ""
echo "Start logs:"
echo ""
gcloud compute instances get-serial-port-output buildlet-win2016 --zone="${ZONE}" --project="${PROJECT_ID}" 
