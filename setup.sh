#!/bin/sh

if [[ ! -n "$EXECUTABLE_PATH" ]]; then
SRCROOT=$(dirname "$0")
WRAPPER_NAME="SambaPlayer.framework"
EXECUTABLE_PATH="${WRAPPER_NAME}/SambaPlayer"
fi

# checking dependency build dir
if [[ ! -d "${SRCROOT}/Build" ]]; then
echo "Warning: No dependency build found, merges won't happen." | tee setup-error.log
exit
fi

# checking dependency build
if [[ ! -d "${SRCROOT}/Build/Products/Release-iphonesimulator" ]]; then
echo "Info: No simulator build found yet, waiting..." | tee setup.log
exit
fi

# checking Carthage build dir
if [[ ! -d "${SRCROOT}/../../../Carthage/Build" ]]; then
echo "Warning: No Carthage build directory found, merges won't happen." | tee setup-error.log
exit
fi

# checking dependency build
if [[ ! -d "${SRCROOT}/../../Build/iOS/${EXECUTABLE_PATH}" ]]; then
echo "Info: No Carthage build found yet, waiting..." | tee setup.log
exit
fi

#archs=$(lipo -info "${SRCROOT}/../../Build/iOS/${EXECUTABLE_PATH}")

# merges lib to reach all archs
echo "merging modules: ${SRCROOT}/Build/Products/Release-iphonesimulator/${WRAPPER_NAME}/Modules/ => ${SRCROOT}/../../Build/iOS/${WRAPPER_NAME}/Modules/" | tee setup.log
cp -r "${SRCROOT}/Build/Products/Release-iphonesimulator/${WRAPPER_NAME}/Modules/" "${SRCROOT}/../../Build/iOS/${WRAPPER_NAME}/Modules/"
echo "merging archs: ${SRCROOT}/Build/Products/Release-iphonesimulator/${EXECUTABLE_PATH} ${SRCROOT}/../../Build/iOS/${EXECUTABLE_PATH} => ${SRCROOT}/../../Build/iOS/${EXECUTABLE_PATH}" | tee -a setup.log
lipo -create "${SRCROOT}/Build/Products/Release-iphonesimulator/${EXECUTABLE_PATH}" "${SRCROOT}/../../Build/iOS/${EXECUTABLE_PATH}" -output "${SRCROOT}/../../Build/iOS/${EXECUTABLE_PATH}"

# copies IMA framework to Carthage's build dir
echo "copying IMA: ${SRCROOT}/Frameworks/GoogleInteractiveMediaAds.framework/ => ${SRCROOT}/../../Build/iOS/GoogleInteractiveMediaAds.framework/" | tee -a setup.log
cp -r "${SRCROOT}/Frameworks/GoogleInteractiveMediaAds.framework/" "${SRCROOT}/../../Build/iOS/GoogleInteractiveMediaAds.framework/"
