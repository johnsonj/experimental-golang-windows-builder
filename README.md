# Go windows buildlet experiment

Experimental work in automating the Golang Windows builders.

## Setup a firewall rule
Allow traffic to instances tagged `allow-dev-access` on tcp:80, tcp:3389

```bash
# restrict this down to your local network
source_range=0.0.0.0/0

gcloud compute firewall-rules create --allow=tcp:80,tcp:3389 --target-tags allow-dev-access --source-ranges $source_range allow-dev-access
```

## Build and test a single base image
Builds a buildlet from the BASE_IMAGE and sets it up with [winstrap.ps1](./winstrap.ps1). An image is captured and then a new VM is created from that image and validated with [test_buildlet.sh](./test_buildlet.sh).

```bash
export PROJECT_ID=YOUR_GCP_PROJECT
export BASE_IMAGE=windows-server-2016-dc-core-v20170214

./build.sh
```

## Test the buildlet is running
```bash
external_ip=$(gcloud compute instances describe golang-buildlet-test --project=${PROJECT_ID} --zone=${ZONE} --format="value(networkInterfaces[0].accessConfigs[0].natIP)")
curl http://${external_ip}
```

## Build/test golang
```bash
./test_buildlet.sh $external_ip
```

## Troubleshoot via RDP
```bash
./connect.sh golang-buildlet-test
```
