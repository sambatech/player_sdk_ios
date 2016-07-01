#!/bin/sh

if [[ ! -n "$EXECUTABLE_PATH" ]]; then
	SRCROOT=$(dirname "$0")
	WRAPPER_NAME="SambaPlayer.framework"
	EXECUTABLE_PATH="${WRAPPER_NAME}/SambaPlayer"
fi

# trusting on Carthage dir structs
if [[ ! -d "${SRCROOT}/../../../Carthage/Build" ]]; then
    echo 'Warning: No Carthage build found, merges will not happen.'
    exit
fi

# merges lib to reach all archs
cp -r "${SRCROOT}/Build/Products/Release-iphonesimulator/${WRAPPER_NAME}/Modules" "${SRCROOT}/../../Build/iOS/${WRAPPER_NAME}/"
lipo -create "${SRCROOT}/Build/Products/Release-iphonesimulator/${EXECUTABLE_PATH}" "${SRCROOT}/../../Build/iOS/${EXECUTABLE_PATH}" -output "${SRCROOT}/../../Build/iOS/${EXECUTABLE_PATH}"

# copies IMA framework to Carthage's build dir
#echo "copying IMA: ${SRCROOT}/Frameworks/GoogleInteractiveMediaAds.framework => ${SRCROOT}/../../Build/iOS"
cp -r "${SRCROOT}/Frameworks/GoogleInteractiveMediaAds.framework" "${SRCROOT}/../../Build/iOS"
