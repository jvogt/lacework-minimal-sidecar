#!/bin/sh
# Minimal datacollector sidecar start script
#
# Environment Variables:
# LaceworkAccessToken="..."      (Required)
# LaceworkDebug="true"           (Optional, will tail datacollector.log)
# LaceworkAddRootCerts="true"    (Optional, creates /etc/ssl/certs/ca-certificates.crt)
# LaceworkRunAsEntrypoint="true" (Optional, use if setting lacework.sh as ENTRYPOINT in docker. This script will execute whatever is presented in CMD)

if [ -z "$LaceworkAccessToken" ]; then
  echo "Please set the LaceworkAccessToken environment variable"
  exit 1
fi

mkdir -p /var/log/lacework /var/lib/lacework/config


# Copy correct binary
if grep -q Alpine /etc/issue; then
  echo "Using alpine datacollector"
  cp /shared/datacollector_alpine /var/lib/lacework/datacollector
else
  echo "Using linux datacollector"
  cp /shared/datacollector_linux /var/lib/lacework/datacollector
fi
chmod +x /var/lib/lacework/datacollector


# Create config file
echo "Writing Lacework datacollector config file to /var/lib/lacework/config/config.json"
LW_CONFIG="{\"tokens\": {\"accesstoken\": \"${LaceworkAccessToken}\"}}"
echo $LW_CONFIG > /var/lib/lacework/config/config.json


# Optional debug logging
if [ "$LaceworkDebug" = "true" ]; then
  echo "Debug mode: tailing /var/log/lacework/datacollector.log"
  touch /var/log/lacework/datacollector.log
  tail -f /var/log/lacework/datacollector.log &
fi


# Check for existence of CA Certs in customer image
if [ ! -f /etc/ssl/certs/ca-certificates.crt ]; then
  echo "WARNING: Root certs not found, to add them set LaceworkAddRootCerts=true"
fi
if [ "$LaceworkAddRootCerts" = "true" ]; then
  echo "Copying root certs from Lacework volume to /etc/ssl/certs/ca-certificates.crt"
  mkdir -p /etc/ssl/certs
  cp /shared/ca-certificates.crt /etc/ssl/certs
fi


# Start datacollector
/var/lib/lacework/datacollector &
echo "Lacework datacollector started"

# Optionally operate as ENTRYPOINT script (run customer CMD as presented by docker)
if [ "$LaceworkRunAsEntrypoint" = "true" ]; then
  echo "Lacework sidecar running as ENTRYPOINT"
  if [ "$LaceworkDebug" = "true" ]; then
    echo "Executing: exec \"${@}\""
  fi
  exec "$@"
fi
