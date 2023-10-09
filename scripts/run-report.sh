#!/bin/bash
set -eu

CONFIG=/root/reporting/config.json
TERRA_WORKSPACES=/root/reporting/terra-workspaces.json
IMAGE=ghcr.io/ucsc-cgp/cloud-billing-report:latest
REPORT_TYPE=$1
FAIL_LOG=/root/reporting/fail.log
AWS_PROFILE="fill me in"
EMAIL_TMP_FILE=/tmp/${REPORT_TYPE}.eml
PERSONALIZED_EMAIL_DIR=/tmp/personalizedEmails

echo "Running container"

# Mount the config file, aws credentials, and a tmp directory into the docker container.
# The tmp directory will get populated with personalized emails.
(/usr/bin/docker pull ${IMAGE} > /dev/null 2>&1 && \
  /usr/bin/docker run \
  -v ${CONFIG}:/config.json:ro \
  -v ${TERRA_WORKSPACES}:/terra-workspaces.json:ro \
  -v ~/.aws/credentials:/root/.aws/credentials:ro \
  -e AWS_PROFILE=${AWS_PROFILE} \
  -v ${PERSONALIZED_EMAIL_DIR}/:/tmp/personalizedEmails \
  ${IMAGE} ${REPORT_TYPE} --terra-workspaces=/terra-workspaces.json > ${EMAIL_TMP_FILE} && \
  /usr/sbin/sendmail -t < ${EMAIL_TMP_FILE}) || echo "${REPORT_TYPE},$(date -d 'today - 1day' +%Y-%m-%d)" >> ${FAIL_LOG}

sleep 5

for filename in ${PERSONALIZED_EMAIL_DIR}/*.eml; do
    # send the email file
    /usr/sbin/sendmail -t < $filename
    # remove the file
    rm -f $filename
    # try not to get throttled by gmail
    sleep 2
done

echo "Done"
