#!/bin/bash
set -euf

CONFIG=/root/reporting/config.json
IMAGE=ghcr.io/ucsc-cgp/cloud-billing-report:latest
REPORT_TYPE=$1
FAIL_LOG=/root/reporting/fail.log
AWS_PROFILE="fill me in"
EMAIL_TMP_FILE=/tmp/${REPORT_TYPE}.eml
PERSONALIZED_EMAIL_DIR=/tmp/personalizedEmails

echo "Running container"

# Mount the config file, aws credentials, and a tmp directory into the docker container.
# The tmp directory will get populated with personalized emails.
(/usr/local/bin/docker run \
  -v ${CONFIG}:/config.json:ro \
  -v ~/.aws/credentials:/root/.aws/credentials:ro \
  -e AWS_PROFILE=${AWS_PROFILE} \
  -v ${PERSONALIZED_EMAIL_DIR}/:/tmp/personalizedEmails \
  ${IMAGE} ${REPORT_TYPE} > ${EMAIL_TMP_FILE} && \
  /usr/sbin/sendmail -t < ${EMAIL_TMP_FILE}) || echo "${REPORT_TYPE},$(date -d 'today - 1day' +%Y-%m-%d)" >> ${FAIL_LOG}

for filename in ${PERSONALIZED_EMAIL_DIR}/*.eml; do
    # send the email file
    /usr/sbin/sendmail -t < $filename
    # remove the file
    rm $filename
done

echo "Done"