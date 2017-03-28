# Go windows buildlet experiment

## Install terraform

If you don't already have it:
```bash
go get github.com/hashicorp/terraform
```

## Build the instance
```bash
export PROJECT_ID=YOUR_GCP_PROJECT
export IMAGE=windows-server-2016-dc-core-v20170214

./rebuild.sh
```

## Test the buildlet is running
```bash
external_ip=$(gcloud compute instances describe buildlet-win2016 --project=${PROJECT_ID} --zone=${ZONE} --format="value(networkInterfaces[0].accessConfigs[0].natIP)")
curl http://${external_ip}
```

## Troubleshoot via RDP
```bash
./connect.sh
```
