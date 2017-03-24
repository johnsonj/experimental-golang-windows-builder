set -e
set -u

# Set, fetch credentials
yes "Y" | gcloud compute reset-windows-password buildlet-win2016 --user wingopher --project="${PROJECT_ID}" --zone="${ZONE}" > instance.txt

echo ""
echo "Instance credentials: "
echo ""
cat instance.txt

echo ""
echo "Connecting to instance: "
echo ""

username="$(grep username instance.txt | cut -d ':' -f 2 | xargs echo -n)"
password="$(grep password instance.txt | cut -d ':' -f 2  | xargs echo -n)"
hostname="$(grep ip_address instance.txt | cut -d ':' -f 2 | xargs echo -n)"

echo xfreerdp -u "${username}" -p "${password}" -n "${hostname}" --ignore-certificate "${hostname}"
xfreerdp -u "${username}" -p "${password}" -n "${hostname}" --ignore-certificate "${hostname}"
