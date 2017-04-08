set -e
set -u

ZONE="us-east1-d"
REGION="us-east1"
BUILDER_PREFIX="${1-golang}"
INSTANCE_NAME="${BUILDER_PREFIX}-buildlet"
TEST_INSTANCE_NAME="${BUILDER_PREFIX}-buildlet-test"
MACHINE_TYPE="n1-standard-4"
BUILDLET_IMAGE="golang-buildlet-${BASE_IMAGE}"
IMAGE_PROJECT=$IMAGE_PROJECT
BASE_IMAGE=$BASE_IMAGE

#
# 0. Cleanup images/instances from prior runs
#
echo "Destroying existing instances (if exists)"
yes "Y" | gcloud compute instances delete "$INSTANCE_NAME" --project="$PROJECT_ID" --zone="$ZONE" || true
yes "Y" | gcloud compute instances delete "$TEST_INSTANCE_NAME" --project="$PROJECT_ID" --zone="$ZONE" || true
echo "Destroying existing image (if exists)"
yes "Y" | gcloud compute images delete "$BUILDLET_IMAGE" || true


#
# 1. Create base instance
# 

echo "Creating target instance"
gcloud compute instances create --machine-type="$MACHINE_TYPE" "$INSTANCE_NAME" \
        --image "$BASE_IMAGE" --image-project "$IMAGE_PROJECT" \
        --project="$PROJECT_ID" --zone="$ZONE" \
        --metadata="buildlet-binary-url=https://storage.googleapis.com/go-builder-data/buildlet.windows-amd64" \
        --metadata-from-file=sysprep-specialize-script-ps1=winstrap.ps1 --tags=allow-dev-access 

echo "Waiting 120 seconds for sysprep to finish"
sleep 120

echo ""
echo "Start logs:"
echo ""
gcloud compute instances get-serial-port-output "$INSTANCE_NAME" --zone="$ZONE" --project="$PROJECT_ID" 

# Set, fetch credentials
yes "Y" | gcloud compute reset-windows-password "$INSTANCE_NAME" --user wingopher --project="$PROJECT_ID" --zone="$ZONE" > instance.txt

echo "Restarting the instance"
gcloud compute instances reset "$INSTANCE_NAME" --zone="$ZONE" --project="$PROJECT_ID" 

echo "Waiting 60 seconds for the instance to boot"
sleep 60
external_ip=$(gcloud compute instances describe "$INSTANCE_NAME" --project="$PROJECT_ID" --zone="$ZONE" --format="value(networkInterfaces[0].accessConfigs[0].natIP)")
echo curl "http://${external_ip}"
output=$(curl "http://${external_ip}")
echo "${output}"

if [[ ${output} == *"buildlet"* ]]; then
	echo "success! buildlet responds"
else
	echo "failure"
	exit 1
fi

#
# 2. Image base instance
#

echo "Shutting down instance"
gcloud compute instances stop "$INSTANCE_NAME"

echo "Capturing image"
gcloud compute images create "$BUILDLET_IMAGE" --source-disk "$INSTANCE_NAME" --source-disk-zone "$ZONE"

#
# 3. Verify image is valid
#

echo "Creating new machine with image"
gcloud compute instances create --machine-type="$MACHINE_TYPE" --image "$BUILDLET_IMAGE" "$TEST_INSTANCE_NAME" \
--project="$PROJECT_ID" --metadata="buildlet-binary-url=https://storage.googleapis.com/go-builder-data/buildlet.windows-amd64" \
--tags=allow-dev-access --zone="$ZONE"

echo "Waiting 60 seconds for instance creation"
sleep 60

echo "Performing test build"
test_image_ip=$(gcloud compute instances describe "$TEST_INSTANCE_NAME" --project="$PROJECT_ID" --zone="$ZONE" --format="value(networkInterfaces[0].accessConfigs[0].natIP)")
./test_buildlet.sh "$test_image_ip"

echo "Success! A new buildlet can be created with the following command"
echo "gcloud compute instances create --machine-type='$MACHINE_TYPE' '$INSTANCE_NAME' \
--metadata='buildlet-binary-url=https://storage.googleapis.com/go-builder-data/buildlet.windows-amd64' \
--image '$BUILDLET_IMAGE' --image-project '$PROJECT_ID' \
"
