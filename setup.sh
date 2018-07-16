#!/bin/sh

echo "Started merge task at $(date)" | tee -a setup.log

SRCROOT=$(dirname "$0")

# copies IMA framework to Carthage's build dir
echo "copying IMA: ${SRCROOT}/Frameworks/GoogleInteractiveMediaAds.framework => ${SRCROOT}/../../Build/iOS/GoogleInteractiveMediaAds.framework/" | tee -a setup.log
cp -r "${SRCROOT}/Frameworks/GoogleInteractiveMediaAds.framework" "${SRCROOT}/../../Build/iOS/" 2>&1 | tee -a setup.log
